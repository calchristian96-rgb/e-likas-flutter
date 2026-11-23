import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/utils/philippine_time.dart';
import '../../l10n/app_localizations.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../staff_shell/current_event.dart';
import '../../core/widgets/lock_note.dart';
import '../staff_shell/event_lock.dart';

/// The numbers a submission would carry, computed by the server.
class CountFigures {
  const CountFigures({
    required this.families,
    required this.familiesInside,
    required this.familiesOutside,
    required this.persons,
    required this.personsInside,
    required this.personsOutside,
  });

  final int families;
  final int familiesInside;
  final int familiesOutside;
  final int persons;
  final int personsInside;
  final int personsOutside;

  /// Families with no stay recorded in the event (in the total, in
  /// neither part): shown when not zero.
  int get familiesNoStay => families - familiesInside - familiesOutside;

  static int _i(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toInt() ?? 0;

  factory CountFigures.fromJson(Map<String, dynamic> j) => CountFigures(
    families: _i(j, 'families'),
    familiesInside: _i(j, 'families_inside_ec'),
    familiesOutside: _i(j, 'families_outside_ec'),
    persons: _i(j, 'persons'),
    personsInside: _i(j, 'persons_inside_ec'),
    personsOutside: _i(j, 'persons_outside_ec'),
  );

  bool sameAs(CountFigures o) =>
      families == o.families &&
      familiesInside == o.familiesInside &&
      familiesOutside == o.familiesOutside &&
      persons == o.persons &&
      personsInside == o.personsInside &&
      personsOutside == o.personsOutside;
}

/// Families and persons added or removed after the barangay's latest
/// submission (backend 5bb30d1): not in the validated count or DROMIC
/// until a submission that includes them is validated. A validated
/// submission never changes.
class LateEntries {
  const LateEntries({
    required this.families,
    required this.persons,
    required this.removedFamilies,
    required this.removedPersons,
    required this.total,
    this.since,
    this.submissionStatus,
  });

  static LateEntries? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    return LateEntries(
      families: i('families'),
      persons: i('persons'),
      removedFamilies: i('removed_families'),
      removedPersons: i('removed_persons'),
      total: i('total'),
      since: DateTime.tryParse(j['since'] as String? ?? '')?.toLocal(),
      submissionStatus: j['submission_status'] as String?,
    );
  }

  final int families;
  final int persons;
  final int removedFamilies;
  final int removedPersons;
  final int total;

  /// The latest submission's time: entries after it are late.
  final DateTime? since;
  final String? submissionStatus;
}

/// "System checks" before a submission: warnings only, never a block.
class CountChecks {
  const CountChecks({
    required this.incompleteFamilies,
    required this.possibleDuplicates,
  });

  static CountChecks fromJson(Object? j) {
    final m = j is Map<String, dynamic> ? j : const <String, dynamic>{};
    return CountChecks(
      incompleteFamilies: (m['incomplete_families'] as num?)?.toInt() ?? 0,
      possibleDuplicates: (m['possible_duplicates'] as num?)?.toInt() ?? 0,
    );
  }

  final int incompleteFamilies;
  final int possibleDuplicates;
}

/// `GET /count-submissions/computed` (backend step 9).
class ComputedCount {
  const ComputedCount({
    required this.eventId,
    required this.eventActive,
    required this.computed,
    this.submitted,
    this.submissionStatus,
    this.submissionVersion,
    this.reviewNote,
    this.validatedFamilies,
    this.validatedPersons,
    this.lateEntries,
    this.checks = const CountChecks(
      incompleteFamilies: 0,
      possibleDuplicates: 0,
    ),
    this.submittedAt,
    this.reviewedAt,
    this.barangayName,
    this.hasOfficialAccount = true,
  });

  final int? validatedPersons;

  /// Null before the barangay's first submission.
  final LateEntries? lateEntries;
  final CountChecks checks;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? barangayName;

  /// Without one, CSWD submits the count for the barangay.
  final bool hasOfficialAccount;

  bool get hasLateEntries => (lateEntries?.total ?? 0) > 0;

  final int eventId;
  final bool eventActive;
  final CountFigures computed;

  /// The current submission's numbers, or null before the first one.
  final CountFigures? submitted;

  /// pending | validated | returned
  final String? submissionStatus;
  final int? submissionVersion;
  final String? reviewNote;

  /// The validated need for relief (families), once validated.
  final int? validatedFamilies;

  bool get changedSinceSubmission =>
      submitted != null && !computed.sameAs(submitted!);

  /// The server refuses a new submission while the current one waits
  /// and nothing changed.
  bool get canSubmit =>
      eventActive &&
      !(submissionStatus == 'pending' && !changedSinceSubmission);

  factory ComputedCount.fromJson(Map<String, dynamic> j) {
    final event = j['evacuation_event'] as Map<String, dynamic>? ?? const {};
    final current = j['current_submission'] as Map<String, dynamic>?;
    final need = j['validated_need'] as Map<String, dynamic>?;
    return ComputedCount(
      eventId: event['id'] as int? ?? 0,
      eventActive: event['status'] == 'active',
      computed: CountFigures.fromJson(
        j['computed'] as Map<String, dynamic>? ?? const {},
      ),
      submitted: current == null ? null : CountFigures.fromJson(current),
      submissionStatus: current?['status'] as String?,
      submissionVersion: (current?['version'] as num?)?.toInt(),
      reviewNote: current?['review_note'] as String?,
      validatedFamilies: (need?['families'] as num?)?.toInt(),
      validatedPersons: (need?['persons'] as num?)?.toInt(),
      lateEntries: LateEntries.fromJson(j['late_entries']),
      checks: CountChecks.fromJson(j['checks']),
      submittedAt: DateTime.tryParse(
        current?['submitted_at'] as String? ?? '',
      )?.toLocal(),
      reviewedAt: DateTime.tryParse(
        current?['reviewed_at'] as String? ?? '',
      )?.toLocal(),
      barangayName:
          (j['barangay'] as Map<String, dynamic>?)?['name'] as String?,
      hasOfficialAccount: j['has_official_account'] != false,
    );
  }
}

final computedCountProvider =
    FutureProvider.autoDispose<
      ({ComputedCount count, DateTime fetchedAt, bool fromCache})?
    >((ref) async {
      ref.watch(outboxRevisionProvider);
      final event = await ref.watch(currentStaffEventProvider.future);
      if (event == null) return null;
      final read = await ref
          .watch(staffReadCacheProvider)
          .get(
            '/count-submissions/computed',
            query: {'evacuation_event_id': event.id},
          );
      return (
        count: ComputedCount.fromJson(read.data),
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// "Final count" (C23b): the numbers the system computed for the
/// barangay, the state of the last submission, and "Submit final count"
/// / "Submit updated count", queued offline. The validated count is the
/// barangay's relief need.
class FinalCountCard extends ConsumerWidget {
  const FinalCountCard({super.key});

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ComputedCount count,
  ) async {
    final l10n = AppLocalizations.of(context);
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.finalCountSubmitTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.finalCountFigures(
                l10n.countFamilies(count.computed.families),
                l10n.countPersons(count.computed.persons),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.finalCountCentersPrivate(
                l10n.countFamilies(count.computed.familiesInside),
                l10n.countFamilies(count.computed.familiesOutside),
              ),
            ),
            if (count.checks.incompleteFamilies > 0)
              Text(
                l10n.finalCountCheckIncomplete(count.checks.incompleteFamilies),
              ),
            if (count.checks.possibleDuplicates > 0)
              Text(
                l10n.finalCountCheckDuplicates(count.checks.possibleDuplicates),
              ),
            const SizedBox(height: 8),
            Text(l10n.finalCountAfterThis),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: l10n.finalCountNote,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.finalCountReviewFirst),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.finalCountSubmitShort),
          ),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (ok != true) return;
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.countSubmission,
      method: 'POST',
      path: '/count-submissions',
      body: {
        'evacuation_event_id': count.eventId,
        if (text.isNotEmpty) 'note': text,
      },
      summary: l10n.finalCountSummary(
        l10n.countFamilies(count.computed.families),
        l10n.countPersons(count.computed.persons),
      ),
      subjectKey: 'count:${count.eventId}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(staffAuthProvider).value;
    if (!(session?.can(StaffPermission.countSubmit) ?? false)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final result = ref.watch(computedCountProvider).value;
    if (result == null) return const SizedBox.shrink();
    final count = result.count;
    final queued = (ref.watch(pendingActionsProvider).value ?? const []).any(
      (a) => a.subjectKey == 'count:${count.eventId}',
    );
    final (statusText, statusColor) = switch (count.submissionStatus) {
      'validated' => (
        count.reviewedAt == null
            ? l10n.finalCountValidated(
                l10n.countFamilies(count.validatedFamilies ?? 0),
              )
            : l10n.finalCountValidatedAsOf(
                l10n.countFamilies(count.validatedFamilies ?? 0),
                formatShortDateTime(count.reviewedAt!),
              ),
        semantic.success,
      ),
      'returned' => (l10n.finalCountReturned, theme.colorScheme.error),
      'pending' => (l10n.finalCountWaiting, semantic.warning),
      _ => (l10n.finalCountNotSubmitted, theme.colorScheme.onSurfaceVariant),
    };
    final c = count.computed;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.finalCountTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                l10n.finalCountFigures(
                  l10n.countFamilies(c.families),
                  l10n.countPersons(c.persons),
                ),
                style: theme.textTheme.headlineSmall,
              ),
              Text(
                l10n.finalCountInsideOutside(
                  c.familiesInside,
                  c.familiesOutside,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              if (c.familiesNoStay > 0)
                Text(
                  l10n.finalCountNoStay(c.familiesNoStay),
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Text(
                queued ? l10n.syncWaiting : statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: queued ? null : statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count.reviewNote != null && count.reviewNote!.isNotEmpty)
                Text(count.reviewNote!, style: theme.textTheme.bodySmall),
              if (count.hasLateEntries)
                _LateEntriesNote(late: count.lateEntries!)
              else if (count.changedSinceSubmission)
                Text(l10n.finalCountChanged, style: theme.textTheme.bodySmall),
              if (result.fromCache)
                Text(
                  l10n.savedCopyAge(formatElapsedSince(result.fetchedAt)),
                  style: theme.textTheme.bodySmall,
                ),
              if (ref.watch(eventMonitoredProvider)) ...[
                const SizedBox(height: 16),
                const LockNote(),
              ] else if (count.canSubmit && !queued) ...[
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _submit(context, ref, count),
                  child: Text(
                    count.submitted == null
                        ? l10n.finalCountSubmit
                        : l10n.finalCountSubmitUpdated,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "3 late entries (11 persons) since 2:00 PM: not in your final count"
/// with what the next submission will add.
class _LateEntriesNote extends StatelessWidget {
  const _LateEntriesNote({required this.late});

  final LateEntries late;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semantic.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: semantic.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, color: semantic.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lateEntriesCount(late.total),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  [
                    if (late.families > 0)
                      l10n.lateEntriesAdded(
                        l10n.countFamilies(late.families),
                        l10n.countPersons(late.persons),
                      ),
                    if (late.removedFamilies > 0 || late.removedPersons > 0)
                      l10n.lateEntriesRemoved(
                        l10n.countFamilies(late.removedFamilies),
                        l10n.countPersons(late.removedPersons),
                      ),
                    if (late.since != null)
                      l10n.lateEntriesSince(formatShortDateTime(late.since!)),
                  ].join(' · '),
                ),
                Text(
                  late.submissionStatus == 'validated'
                      ? l10n.lateEntriesNotInValidated
                      : l10n.lateEntriesNotInCount,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
