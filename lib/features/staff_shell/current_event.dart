import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/staff_read_cache.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../family_registration/domain/entities/lookup_entities.dart';
import '../family_registration/presentation/providers/lookup_providers.dart';

/// The event switcher (backend 008da71): each user works on one event at
/// a time, remembered on the server so the web and the apps share it.
class SelectedEventState {
  const SelectedEventState({
    required this.selected,
    required this.chosen,
    required this.open,
    required this.closed,
  });

  factory SelectedEventState.fromJson(Map<String, dynamic> j) {
    EvacuationEventLookup row(Object? e) {
      final m = e as Map<String, dynamic>;
      return EvacuationEventLookup(
        id: m['id'] as int,
        name: m['name'] as String? ?? '',
        status: m['status'] as String? ?? 'monitoring',
        isDemo: m['is_demo'] == true,
      );
    }

    return SelectedEventState(
      selected: j['selected'] == null ? null : row(j['selected']),
      chosen: j['chosen'] == true,
      open: [for (final e in j['open_events'] as List? ?? const []) row(e)],
      closed: [for (final e in j['closed_events'] as List? ?? const []) row(e)],
    );
  }

  /// The event this user works on; null when no event is open and none
  /// is chosen. A closed one can be chosen to look back (read-only).
  final EvacuationEventLookup? selected;

  /// False when the server picked it (the only open event, or the
  /// current one: real before demo, active before monitoring, newest).
  final bool chosen;
  final List<EvacuationEventLookup> open;
  final List<EvacuationEventLookup> closed;
}

/// The same pick as the server's, from the events list: used only when
/// `GET /selected-event` has never been read on this phone.
SelectedEventState _localPick(List<EvacuationEventLookup> events) {
  int rank(EvacuationEventLookup e) =>
      (e.isDemo ? 2 : 0) + (e.status == 'active' ? 0 : 1);
  final open =
      [
        for (final e in events)
          if (e.isOpen) e,
      ]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : b.id.compareTo(a.id);
      });
  return SelectedEventState(
    selected: open.firstOrNull,
    chosen: false,
    open: open,
    closed: [
      for (final e in events)
        if (!e.isOpen) e,
    ],
  );
}

/// `GET /selected-event`, saved for offline.
final selectedEventProvider = FutureProvider.autoDispose<SelectedEventState>((
  ref,
) async {
  try {
    final read = await ref.watch(staffReadCacheProvider).get('/selected-event');
    return SelectedEventState.fromJson(read.data);
  } catch (_) {
    return _localPick(await ref.watch(evacuationEventsLookupProvider.future));
  }
});

/// The open events, the selected one's status first (active, then
/// monitoring; real before demo).
final openStaffEventsProvider =
    FutureProvider.autoDispose<List<EvacuationEventLookup>>(
      (ref) async => (await ref.watch(selectedEventProvider.future)).open,
    );

/// The event Staff Mode works on: the user's selected event (null when
/// none is open). Every event-based screen uses it.
final currentStaffEventProvider =
    FutureProvider.autoDispose<EvacuationEventLookup?>(
      (ref) async => (await ref.watch(selectedEventProvider.future)).selected,
    );

/// `PUT /selected-event`: online only (it is the user's choice on the
/// server, shared with the web). Null when it worked, else the message.
Future<String?> chooseStaffEvent(
  WidgetRef ref,
  AppLocalizations l10n,
  int? eventId,
) async {
  if (!await ref.read(connectivityServiceProvider).hasConnection) {
    return l10n.eventSwitchNeedsConnection;
  }
  try {
    await ref
        .read(staffApiClientProvider)
        .put('/selected-event', data: {'evacuation_event_id': eventId});
  } on DioException catch (e) {
    return mapStaffDioError(e).message;
  }
  ref.invalidate(selectedEventProvider);
  ref.invalidate(evacuationEventsLookupProvider);
  return null;
}

/// The event line of a Staff Mode tab: "Event: {name}" (DEMO marked,
/// closed marked), and Change when there is more than one to choose.
class StaffEventBar extends ConsumerWidget {
  const StaffEventBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(selectedEventProvider).value;
    final current = state?.selected;
    if (state == null || current == null) return const SizedBox.shrink();
    final choices = state.open.length + state.closed.length;
    return Row(
      children: [
        Flexible(
          child: Text(
            l10n.eventSwitchCurrent(current.name),
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (current.isDemo) ...[const SizedBox(width: 8), const DemoBadge()],
        // Monitoring until the first check-in or an evacuation order
        // makes it Active (backend EventFlow).
        const SizedBox(width: 8),
        StatusChip(
          label: switch (current.status) {
            'active' => l10n.eventStatusActive,
            'monitoring' => l10n.eventStatusMonitoring,
            _ => l10n.eventSwitchClosed,
          },
          color: switch (current.status) {
            'active' => const Color(0xFFB45309),
            'monitoring' => const Color(0xFF2563EB),
            _ => const Color(0xFF374151),
          },
        ),
        if (choices > 1)
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => _showSwitcher(context, ref, state),
            child: Text(l10n.eventSwitchChange),
          ),
      ],
    );
  }
}

Future<void> _showSwitcher(
  BuildContext context,
  WidgetRef ref,
  SelectedEventState state,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final picked = await showModalBottomSheet<EvacuationEventLookup>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      Widget tile(EvacuationEventLookup e) => ListTile(
        minTileHeight: 56,
        title: Text(e.name),
        subtitle: Text(switch (e.status) {
          'active' => l10n.eventStatusActive,
          'monitoring' => l10n.eventStatusMonitoring,
          _ => l10n.eventSwitchClosedReadOnly,
        }),
        leading: Icon(
          e.id == state.selected?.id
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: theme.colorScheme.primary,
        ),
        trailing: e.isDemo ? const DemoBadge() : null,
        onTap: () => Navigator.of(context).pop(e),
      );
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.eventSwitchTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (state.open.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionTitle(l10n.eventSwitchOpen),
                ),
                for (final e in state.open) tile(e),
              ],
              if (state.closed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionTitle(l10n.eventSwitchClosedEvents),
                ),
                for (final e in state.closed) tile(e),
              ],
            ],
          ),
        ),
      );
    },
  );
  if (picked == null || picked.id == state.selected?.id) return;
  final error = await chooseStaffEvent(ref, l10n, picked.id);
  messenger.showSnackBar(
    SnackBar(content: Text(error ?? l10n.eventSwitchNowWorkingOn(picked.name))),
  );
}
