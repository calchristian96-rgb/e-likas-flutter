import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/notifications/local_notifications.dart';
import '../../core/widgets/lock_note.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notifications.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_shell/current_event.dart';

/// `GET /dashboard/barangay` (officials), saved for offline: the plan
/// (forecast, space, centers ready), the list of families to evacuate,
/// each center's readiness, facility requests, the To do list, the
/// status (with `may_say_arriving`) and the barangay's alerts
/// (docs/backend/apps-api-2026-11-22.md section 7).
class BarangayDashboard {
  const BarangayDashboard(
    this.data, {
    required this.fetchedAt,
    required this.fromCache,
  });

  final Map<String, dynamic> data;
  final DateTime fetchedAt;
  final bool fromCache;

  Map<String, dynamic> get status =>
      data['status'] as Map<String, dynamic>? ?? const {};

  /// Officials may tell CSWD that families are arriving (monitored only).
  bool get maySayArriving => status['may_say_arriving'] == true;

  Map<String, dynamic>? get plan => data['plan'] as Map<String, dynamic>?;

  /// `{families, persons, checked_in}`, null when nothing is listed.
  Map<String, dynamic>? get list => data['list'] as Map<String, dynamic>?;

  List<Map<String, dynamic>> get todo => [
    for (final t in data['todo'] as List? ?? const [])
      if (t is Map<String, dynamic>) t,
  ];

  List<Map<String, dynamic>> get centers => [
    for (final c in data['centers'] as List? ?? const [])
      if (c is Map<String, dynamic>) c,
  ];

  List<Map<String, dynamic>> get alerts => [
    for (final a in data['alerts'] as List? ?? const [])
      if (a is Map<String, dynamic>) a,
  ];
}

final barangayDashboardProvider =
    FutureProvider.autoDispose<BarangayDashboard?>((ref) async {
      ref.watch(outboxRevisionProvider);
      final event = await ref.watch(currentStaffEventProvider.future);
      try {
        final read = await ref
            .watch(staffReadCacheProvider)
            .get(
              '/dashboard/barangay',
              query: {'evacuation_event_id': ?event?.id},
            );
        return BarangayDashboard(
          read.data,
          fetchedAt: read.fetchedAt,
          fromCache: read.isFromCache,
        );
      } catch (_) {
        return null;
      }
    });

/// "Families are arriving" (officials, while the event is monitored):
/// `POST /evacuation-events/{id}/families-arriving {note?}` tells CSWD
/// and nothing else changes. Online only: CSWD must hear it now.
class FamiliesArrivingButton extends ConsumerWidget {
  const FamiliesArrivingButton({super.key, required this.eventId});

  final int eventId;

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.arrivingNeedsConnection)),
      );
      return;
    }
    if (!context.mounted) return;
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _ArrivingDialog(),
    );
    if (note == null) return;
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .post(
            '/evacuation-events/$eventId/families-arriving',
            data: {if (note.isNotEmpty) 'note': note},
          );
      final message = (response.data as Map?)?['message'] as String?;
      messenger.showSnackBar(
        SnackBar(content: Text(message ?? l10n.arrivingSent)),
      );
    } on DioException catch (e) {
      messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: theme.extension<AppSemanticColors>()!.warning,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _send(context, ref),
      icon: const Icon(Icons.directions_walk),
      label: Text(l10n.arrivingButton, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _ArrivingDialog extends StatefulWidget {
  const _ArrivingDialog();

  @override
  State<_ArrivingDialog> createState() => _ArrivingDialogState();
}

class _ArrivingDialogState extends State<_ArrivingDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.arrivingTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.arrivingBody),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: l10n.arrivingNote,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_note.text.trim()),
          child: Text(l10n.arrivingSend),
        ),
      ],
    );
  }
}

/// Whether a notification row is the server's `RegistrationOpen` (sent to
/// every official when CSWD starts the evacuation, or when a Preemptive
/// or Forced order is recorded for their barangay).
bool isRegistrationOpenNotification(AppNotification n) {
  final type = (n.type ?? '').toLowerCase().replaceAll('_', '');
  if (type.contains('registrationopen')) return true;
  final t = n.title.toLowerCase();
  return t.contains('registration') && t.contains('open');
}

/// The newest unread "registration is open" notification, if any.
final registrationOpenNoticeProvider = Provider.autoDispose<AppNotification?>((
  ref,
) {
  final items = ref.watch(notificationsProvider).value?.items ?? const [];
  return items
      .where((n) => !n.read && isRegistrationOpenNotification(n))
      .firstOrNull;
});

/// The green "Registration is open" card on the official's home: the
/// server's notification when there is one, else the app's own words
/// once the event is Active.
class RegistrationOpenCard extends ConsumerWidget {
  const RegistrationOpenCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notice = ref.watch(registrationOpenNoticeProvider);
    if (notice == null) return const SizedBox.shrink();
    final color = theme.extension<AppSemanticColors>()!.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () => context.go('/staff/home/notifications'),
        child: Row(
          children: [
            Icon(Icons.how_to_reg, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title.isEmpty
                        ? l10n.registrationOpenTitle
                        : notice.title,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                  if (notice.message.isNotEmpty) Text(notice.message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the phone's own "Registration is open" notification when the
/// selected event turns from Monitoring to Active while the app runs.
class RegistrationOpenWatcher extends ConsumerWidget {
  const RegistrationOpenWatcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.listen(currentStaffEventProvider, (previous, next) {
      final before = previous?.value;
      final now = next.value;
      if (before == null || now == null || before.id != now.id) return;
      if (before.status == 'monitoring' && now.status == 'active') {
        LocalNotifications.show(
          id: 7000 + now.id % 1000,
          title: l10n.registrationOpenTitle,
          body: l10n.registrationOpenBody(now.name),
          channelId: LocalNotifications.staffChannelId,
          payload: 'staff:home',
        );
        ref.invalidate(notificationsProvider);
      }
    });
    return child;
  }
}
