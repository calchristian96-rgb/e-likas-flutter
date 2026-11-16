import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/demo_badge.dart';
import '../../l10n/app_localizations.dart';
import '../family_registration/domain/entities/lookup_entities.dart';
import '../family_registration/presentation/providers/lookup_providers.dart';

/// The event Staff Mode works on: the one the user picked, else the
/// newest active real event, else any open one (a real event always
/// before a demo, as the backend's "current event"). Null when no event
/// is open.
class ChosenStaffEvent extends Notifier<int?> {
  @override
  int? build() => null;

  void choose(int id) => state = id;
}

final chosenStaffEventProvider = NotifierProvider<ChosenStaffEvent, int?>(
  ChosenStaffEvent.new,
);

final openStaffEventsProvider =
    FutureProvider.autoDispose<List<EvacuationEventLookup>>((ref) async {
      final events = await ref.watch(evacuationEventsLookupProvider.future);
      int rank(EvacuationEventLookup e) =>
          (e.isDemo ? 2 : 0) + (e.status == 'active' ? 0 : 1);
      return [
        for (final e in events)
          if (e.isOpen) e,
      ]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : b.id.compareTo(a.id);
      });
    });

final currentStaffEventProvider =
    FutureProvider.autoDispose<EvacuationEventLookup?>((ref) async {
      final open = await ref.watch(openStaffEventsProvider.future);
      if (open.isEmpty) return null;
      final chosen = ref.watch(chosenStaffEventProvider);
      return open.firstWhere((e) => e.id == chosen, orElse: () => open.first);
    });

/// The event line of a Staff Mode tab: its name (DEMO marked) and a
/// picker when more than one event is open.
class StaffEventBar extends ConsumerWidget {
  const StaffEventBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final open = ref.watch(openStaffEventsProvider).value ?? const [];
    final current = ref.watch(currentStaffEventProvider).value;
    if (current == null) return const SizedBox.shrink();
    if (open.length < 2) {
      return Row(
        children: [
          Flexible(
            child: Text(
              current.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (current.isDemo) ...[const SizedBox(width: 8), const DemoBadge()],
        ],
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: current.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.staffRegFieldEvacuationEvent,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final e in open)
          DropdownMenuItem(
            value: e.id,
            child: Text(
              e.isDemo ? '${e.name} (${l10n.demoBadge})' : e.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) {
        if (id != null) ref.read(chosenStaffEventProvider.notifier).choose(id);
      },
    );
  }
}
