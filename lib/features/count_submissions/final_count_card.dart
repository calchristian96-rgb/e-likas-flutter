import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../staff_shell/current_event.dart';

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
  });

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
                count.computed.families,
                count.computed.persons,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.finalCountComputedNote),
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
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.finalCountSubmit),
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
        count.computed.families,
        count.computed.persons,
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
        l10n.finalCountValidated(count.validatedFamilies ?? 0),
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
                l10n.finalCountFigures(c.families, c.persons),
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
              if (count.changedSinceSubmission)
                Text(l10n.finalCountChanged, style: theme.textTheme.bodySmall),
              if (result.fromCache)
                Text(
                  l10n.savedCopyAge(formatElapsedSince(result.fetchedAt)),
                  style: theme.textTheme.bodySmall,
                ),
              if (count.canSubmit && !queued) ...[
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
