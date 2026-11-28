import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/lock_note.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../family_registration/presentation/providers/lookup_providers.dart';
import '../monitoring/monitoring_page.dart';
import '../staff_shell/current_event.dart';

/// One CSWD action that tells someone: online only, never queued, after
/// a confirm. Null when it worked, else the failure was shown.
Future<bool> _cswdPost(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String title,
  required String body,
  required String action,
  required String done,
  Map<String, dynamic>? data,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (!await ref.read(connectivityServiceProvider).hasConnection) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.cswdNeedsConnection)));
    return false;
  }
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    final response = await ref
        .read(staffApiClientProvider)
        .post(path, data: data);
    final message = (response.data as Map?)?['message'] as String?;
    messenger.showSnackBar(SnackBar(content: Text(message ?? done)));
    return true;
  } on DioException catch (e) {
    messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
    return false;
  }
}

/// "Start evacuation" (CSWD, `events.manage`, the event is monitored):
/// `POST /evacuation-events/{id}/start` makes it Active; every barangay
/// official is told registration is open.
class StartEvacuationCard extends ConsumerWidget {
  const StartEvacuationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final event = ref.watch(currentStaffEventProvider).value;
    if (event == null || event.status != 'monitoring') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cswdStartTitle(event.name),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.cswdStartHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              // An action, so sienna: red is the evacuation status.
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l10n.cswdStartEvacuation),
              onPressed: () async {
                final ok = await _cswdPost(
                  context,
                  ref,
                  path: '/evacuation-events/${event.id}/start',
                  title: l10n.cswdStartConfirmTitle(event.name),
                  body: l10n.cswdStartConfirmBody,
                  action: l10n.cswdStartEvacuation,
                  done: l10n.cswdStartDone(event.name),
                  destructive: true,
                );
                if (ok) {
                  ref.invalidate(selectedEventProvider);
                  ref.invalidate(evacuationEventsLookupProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// `POST /gis/barangays/{id}/ask-update`: CSWD asks the barangay's
/// officials to update their status (CSWD sets Normal, Watch and
/// Flooding only for a barangay with no official).
Future<void> askBarangayToUpdate(
  BuildContext context,
  WidgetRef ref, {
  required int barangayId,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  await _cswdPost(
    context,
    ref,
    path: '/gis/barangays/$barangayId/ask-update',
    title: l10n.cswdAskUpdateTitle(name),
    body: l10n.cswdAskUpdateBody,
    action: l10n.cswdAskUpdate,
    done: l10n.cswdAskUpdateDone(name),
  );
}

/// `POST /barangays/{id}/remind-final-count`: the officials are told.
Future<void> remindFinalCount(
  BuildContext context,
  WidgetRef ref, {
  required int barangayId,
  required String name,
}) async {
  final l10n = AppLocalizations.of(context);
  await _cswdPost(
    context,
    ref,
    path: '/barangays/$barangayId/remind-final-count',
    title: l10n.cswdRemindTitle(name),
    body: l10n.cswdRemindBody,
    action: l10n.cswdRemind,
    done: l10n.cswdRemindDone(name),
  );
}

/// One barangay's progress: registered now against what it expects (its
/// list of families to evacuate) and how many listed are checked in.
class BarangayProgress {
  const BarangayProgress({
    required this.id,
    required this.name,
    required this.registeredFamilies,
    required this.registeredPersons,
    this.expectedFamilies,
    this.listCheckedIn,
  });

  static BarangayProgress? fromJson(Map<String, dynamic> j) {
    final b = j['barangay'] as Map<String, dynamic>?;
    final id = (b?['id'] ?? j['id']) as num?;
    if (id == null) return null;
    int? n(Object? v) => (v as num?)?.toInt();
    final list = j['list'] as Map<String, dynamic>?;
    return BarangayProgress(
      id: id.toInt(),
      name: (b?['name'] ?? j['name']) as String? ?? '',
      registeredFamilies: n(j['families'] ?? j['registered_families']) ?? 0,
      registeredPersons: n(j['persons'] ?? j['registered_persons']) ?? 0,
      expectedFamilies:
          n(list?['families']) ??
          n(j['expected_families'] ?? j['plan_families']),
      listCheckedIn: n(list?['checked_in']),
    );
  }

  final int id;
  final String name;
  final int registeredFamilies;
  final int registeredPersons;

  /// Null when the barangay listed none.
  final int? expectedFamilies;
  final int? listCheckedIn;

  double? get share {
    final e = expectedFamilies;
    if (e == null || e <= 0) return null;
    return (registeredFamilies / e).clamp(0, 1).toDouble();
  }
}

/// Evacuation progress (CSWD): registered against expected, per
/// barangay, from `GET /monitoring/evacuees` (each row's `list`). Read
/// only: CSWD never registers or edits evacuees.
class EvacuationProgressPage extends ConsumerWidget {
  const EvacuationProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(monitoringSectionProvider('evacuees'));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cswdProgressTitle)),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(monitoringSectionProvider('evacuees')),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            const StaffEventBar(),
            const SizedBox(height: 8),
            Text(l10n.cswdProgressHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            ...async.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, _) => [
                EmptyNote(
                  icon: Icons.cloud_off_outlined,
                  message: l10n.monitoringNeedsConnection,
                ),
              ],
              data: (s) {
                final rows =
                    [
                      for (final r in s.data?['barangays'] as List? ?? const [])
                        ?BarangayProgress.fromJson(r as Map<String, dynamic>),
                    ]..sort((a, b) {
                      // Behind first: the lowest share of what is expected.
                      final x = a.share ?? 2;
                      final y = b.share ?? 2;
                      final c = x.compareTo(y);
                      return c != 0 ? c : a.name.compareTo(b.name);
                    });
                return [
                  if (s.fromCache)
                    Text(
                      l10n.savedCopyAge(formatElapsedSince(s.fetchedAt)),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (rows.isEmpty) Text(l10n.cswdProgressNone),
                  for (final r in rows)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.zero,
                        onTap: () => context.go('/staff/barangays/${r.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: theme.textTheme.titleMedium),
                              Text(
                                r.expectedFamilies == null
                                    ? l10n.cswdProgressNoList(
                                        l10n.countFamilies(
                                          r.registeredFamilies,
                                        ),
                                      )
                                    : l10n.cswdProgressLine(
                                        formatCount(r.registeredFamilies),
                                        formatCount(r.expectedFamilies),
                                      ),
                              ),
                              if (r.listCheckedIn != null &&
                                  r.expectedFamilies != null)
                                Text(
                                  l10n.cswdProgressListCheckedIn(
                                    formatCount(r.listCheckedIn),
                                    formatCount(r.expectedFamilies),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (r.share != null) ...[
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: r.share,
                                  minHeight: 6,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
