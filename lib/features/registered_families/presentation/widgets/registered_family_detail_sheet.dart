import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/family_record.dart';
import '../../domain/entities/registered_family.dart';
import '../providers/registered_families_provider.dart';

/// One family record — reused both from the Registered Families list
/// (tap a row) and from Phase 3's "View record" duplicate-match action,
/// so there's exactly one place that renders this data. The header
/// comes from the local cache the caller passed in (works offline);
/// the member list is fetched live (see `FamilyRecord`), because it's
/// where each member can be checked out — the same per-person Check out
/// the web family page has, the counterpart of EC Board's Quick
/// Departure. Offline, it falls back to the cached member names.
Future<void> showRegisteredFamilyDetailSheet(
  BuildContext context,
  RegisteredFamily family,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _RegisteredFamilyDetailSheet(family: family, controller: controller),
    ),
  );
}

class _RegisteredFamilyDetailSheet extends ConsumerWidget {
  const _RegisteredFamilyDetailSheet({
    required this.family,
    required this.controller,
  });

  final RegisteredFamily family;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recordAsync = ref.watch(familyRecordProvider(family.id));

    return SafeArea(
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            family.headOfFamilyName.isEmpty
                ? l10n.staffFamiliesUnnamedFamily
                : family.headOfFamilyName,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.staffFamiliesRegisteredIn(family.barangayName),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.groups_outlined,
            label: l10n.staffFamiliesMemberCount(family.memberCount),
          ),
          if (family.homeAddress != null && family.homeAddress!.isNotEmpty)
            _DetailRow(icon: Icons.home_outlined, label: family.homeAddress!),
          if (family.evacuationCenterName != null)
            _DetailRow(
              icon: Icons.night_shelter_outlined,
              label: family.evacuationCenterName!,
            ),
          if (family.is4psBeneficiary)
            _DetailRow(
              icon: Icons.verified_outlined,
              label: l10n.staffReg4psBeneficiaryLabel,
            ),
          if (family.createdAt != null)
            _DetailRow(
              icon: Icons.event_outlined,
              label: DateFormat.yMMMd().add_jm().format(family.createdAt!),
            ),
          const SizedBox(height: 12),
          Text(
            l10n.staffFamiliesMembersSectionTitle,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          ...recordAsync.when(
            data: (record) => [
              // Only while someone is still checked in.
              if (record.members.any((m) => m.hasOpenStay))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _markFamilyDeparted(context, record),
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(l10n.markFamilyDepartedButton),
                    ),
                  ),
                ),
              if (record.isLegacyBulkEntry)
                _Notice(text: l10n.familyLegacyBulkEntryNotice)
              else if (!record.hasHeadLinked)
                _Notice(text: _headNotLinkedText(l10n, record)),
              for (final (index, member) in record.members.indexed)
                _MemberRow(
                  familyId: family.id,
                  member: member,
                  index: index + 1,
                ),
            ],
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            // Offline (or the fetch failed): the cached names, with a
            // note on why there's no check-in state or Check out here.
            error: (error, _) => [
              _Notice(
                text: error is NetworkFailure
                    ? l10n.familyMembersNeedConnection
                    : (error is Failure
                          ? error.message
                          : l10n.familyMembersNeedConnection),
              ),
              for (final name in family.memberNames)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Mark family as departed", the same as the web family page: pick who
  /// is leaving (everyone still checked in, all ticked) and one reason,
  /// confirm, then check each one out through the same single-person
  /// check-out call, one at a time. One that fails doesn't undo the
  /// others; failures are listed by name afterwards.
  Future<void> _markFamilyDeparted(
    BuildContext context,
    FamilyRecord record,
  ) async {
    final l10n = AppLocalizations.of(context);
    String nameOf(FamilyRecordMember member) => member.isPlaceholder
        ? l10n.checkOutMemberPendingName(record.members.indexOf(member) + 1)
        : member.fullName;

    final batch = await showDialog<_DepartureBatch>(
      context: context,
      builder: (context) => _MarkFamilyDepartedDialog(
        members: record.members.where((m) => m.hasOpenStay).toList(),
        nameOf: nameOf,
      ),
    );
    if (batch == null || !context.mounted) return;

    // Through the container, not `ref`: the refresh below must still
    // happen if the sheet is gone by the time the check-outs finish.
    final container = ProviderScope.containerOf(context, listen: false);
    final failed = await showDialog<List<(String, String)>>(
      context: context,
      builder: (context) => _MarkFamilyDepartedConfirmDialog(
        batch: batch,
        nameOf: nameOf,
        checkOut: container.read(checkOutEvacueeProvider),
      ),
    );
    if (failed == null) return;

    final done = batch.members.length - failed.length;
    container.invalidate(familyRecordProvider(family.id));
    container.invalidate(registeredFamiliesProvider);
    if (!context.mounted) return;

    if (done > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.markFamilyDepartedDone(done))),
      );
    }
    if (failed.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.markFamilyDepartedPartialTitle(done, batch.members.length),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.markFamilyDepartedPartialBody),
              const SizedBox(height: 8),
              for (final (name, reason) in failed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('$name: $reason'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        ),
      );
    }
  }

  /// The web family page's reminder, word for word: which answers the
  /// board's child-headed/head's-sex figures are using until a real
  /// head is linked.
  String _headNotLinkedText(AppLocalizations l10n, FamilyRecord record) {
    final answered = [
      switch (record.headSex) {
        'male' => l10n.ecBoardSummaryMale,
        'female' => l10n.ecBoardSummaryFemale,
        _ => null,
      },
      switch (record.isChildHeaded) {
        true => l10n.ecBoardSummaryMinor,
        false => l10n.ecBoardSummaryNotMinor,
        null => null,
      },
    ].nonNulls.toList();
    return answered.isEmpty
        ? l10n.familyHeadNotLinkedNothingKnown
        : l10n.familyHeadNotLinked(answered.join(', '));
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.familyId,
    required this.member,
    required this.index,
  });

  final int familyId;
  final FamilyRecordMember member;

  /// 1-based position, for a placeholder's "Member N" label.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning =
        theme.extension<AppSemanticColors>()?.warning ?? Colors.amber.shade800;

    final status = !member.hasOpenStay
        ? l10n.familyMemberCheckedOut
        : member.openStayCenterName != null
        ? l10n.familyMemberCheckedInAt(member.openStayCenterName!)
        : l10n.familyMemberCheckedInUnspecified;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      member.isPlaceholder
                          ? l10n.familyMemberDetailsPending(index)
                          : member.fullName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: member.isPlaceholder ? warning : null,
                      ),
                    ),
                    if (member.isHead)
                      Text(
                        l10n.staffRegHeadOfFamilyBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (member.hasOpenStay)
            TextButton(
              onPressed: () => _checkOut(context, ref),
              child: Text(l10n.checkOutButton),
            ),
        ],
      ),
    );
  }

  /// Same two steps as the web: pick the reason, then confirm — a real,
  /// lasting change, like Remove.
  Future<void> _checkOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = member.isPlaceholder
        ? l10n.checkOutMemberPendingName(index)
        : member.fullName;
    final reason = await showDialog<CheckOutReason>(
      context: context,
      builder: (context) => _CheckOutDialog(
        name: name,
        centerName:
            member.openStayCenterName ?? l10n.checkOutTheirCurrentLocation,
      ),
    );
    if (reason == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          l10n.checkOutConfirm(name, checkOutReasonLower(l10n, reason)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.checkOutButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(checkOutEvacueeProvider)(member.id, reason);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        // Refresh in place — the row now reads "Checked out". The
        // cached list's center line may have changed too.
        ref.invalidate(familyRecordProvider(familyId));
        ref.invalidate(registeredFamiliesProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.checkOutSucceeded(name))),
        );
      case Failed(:final failure):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failure is NetworkFailure
                  ? l10n.familyMembersNeedConnection
                  : failure.message,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }
}

class _CheckOutDialog extends StatefulWidget {
  const _CheckOutDialog({required this.name, required this.centerName});

  final String name;
  final String centerName;

  @override
  State<_CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends State<_CheckOutDialog> {
  CheckOutReason _reason = CheckOutReason.returnedHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.checkOutDialogTitle(widget.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.checkOutDialogSubtitle(widget.centerName),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.checkOutReasonLabel, style: theme.textTheme.labelLarge),
          RadioGroup<CheckOutReason>(
            groupValue: _reason,
            onChanged: (value) => setState(() => _reason = value ?? _reason),
            child: Column(
              children: [
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: CheckOutReason.returnedHome,
                  title: Text(l10n.checkOutReturnedHome),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: CheckOutReason.transferred,
                  title: Text(l10n.checkOutTransferred),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: CheckOutReason.other,
                  title: Text(l10n.checkOutOther),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason),
          child: Text(l10n.checkOutButton),
        ),
      ],
    );
  }
}

/// "returned home" / "transferred elsewhere" / "departed for another
/// reason", for the confirmation sentences.
String checkOutReasonLower(AppLocalizations l10n, CheckOutReason reason) =>
    switch (reason) {
      CheckOutReason.returnedHome => l10n.checkOutReturnedHomeLower,
      CheckOutReason.transferred => l10n.checkOutTransferredLower,
      CheckOutReason.other => l10n.checkOutOtherLower,
    };

/// Who "Mark family as departed" checks out, and why.
class _DepartureBatch {
  const _DepartureBatch(this.members, this.reason);

  final List<FamilyRecordMember> members;
  final CheckOutReason reason;
}

class _MarkFamilyDepartedDialog extends StatefulWidget {
  const _MarkFamilyDepartedDialog({
    required this.members,
    required this.nameOf,
  });

  /// Only members still checked in.
  final List<FamilyRecordMember> members;
  final String Function(FamilyRecordMember) nameOf;

  @override
  State<_MarkFamilyDepartedDialog> createState() =>
      _MarkFamilyDepartedDialogState();
}

class _MarkFamilyDepartedDialogState extends State<_MarkFamilyDepartedDialog> {
  late final Set<int> _ticked = widget.members.map((m) => m.id).toSet();
  CheckOutReason _reason = CheckOutReason.returnedHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return AlertDialog(
      title: Text(l10n.markFamilyDepartedButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.markFamilyDepartedSubtitle, style: muted),
            const SizedBox(height: 16),
            Text(l10n.markFamilyDepartedWho, style: theme.textTheme.labelLarge),
            for (final member in widget.members)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _ticked.contains(member.id),
                onChanged: (on) => setState(
                  () => on == true
                      ? _ticked.add(member.id)
                      : _ticked.remove(member.id),
                ),
                title: Text(widget.nameOf(member)),
                subtitle: Text(
                  [
                    if (member.isHead) l10n.staffRegHeadOfFamilyBadge,
                    member.openStayCenterName != null
                        ? l10n.familyMemberCheckedInAt(
                            member.openStayCenterName!,
                          )
                        : l10n.familyMemberCheckedInUnspecified,
                  ].join(' · '),
                ),
              ),
            const SizedBox(height: 8),
            Text(l10n.checkOutReasonLabel, style: theme.textTheme.labelLarge),
            RadioGroup<CheckOutReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              child: Column(
                children: [
                  for (final (reason, label) in [
                    (CheckOutReason.returnedHome, l10n.checkOutReturnedHome),
                    (CheckOutReason.transferred, l10n.checkOutTransferred),
                    (CheckOutReason.other, l10n.checkOutOther),
                  ])
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: reason,
                      title: Text(label),
                    ),
                ],
              ),
            ),
            Text(l10n.markFamilyDepartedReasonHelp, style: muted),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _ticked.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _DepartureBatch(
                    widget.members
                        .where((m) => _ticked.contains(m.id))
                        .toList(),
                    _reason,
                  ),
                ),
          child: Text(
            _ticked.isEmpty
                ? l10n.markFamilyDepartedConfirmButton
                : l10n.markFamilyDepartedSubmit(_ticked.length),
          ),
        ),
      ],
    );
  }
}

/// The confirm step, which also does the work, like the web's
/// "Marking..." button: each ticked member goes through the single
/// check-out call, one at a time, and the dialog can't be closed until
/// they're all done. Pops with the ones that failed (name, why), or null
/// when cancelled.
class _MarkFamilyDepartedConfirmDialog extends StatefulWidget {
  const _MarkFamilyDepartedConfirmDialog({
    required this.batch,
    required this.nameOf,
    required this.checkOut,
  });

  final _DepartureBatch batch;
  final String Function(FamilyRecordMember) nameOf;
  final Future<Result<void>> Function(int evacueeId, CheckOutReason reason)
  checkOut;

  @override
  State<_MarkFamilyDepartedConfirmDialog> createState() =>
      _MarkFamilyDepartedConfirmDialogState();
}

class _MarkFamilyDepartedConfirmDialogState
    extends State<_MarkFamilyDepartedConfirmDialog> {
  bool _working = false;

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _working = true);
    final failed = <(String, String)>[];
    for (final member in widget.batch.members) {
      final result = await widget.checkOut(member.id, widget.batch.reason);
      if (result case Failed(:final failure)) {
        failed.add((
          widget.nameOf(member),
          failure is NetworkFailure
              ? l10n.familyMembersNeedConnection
              : failure.message,
        ));
      }
    }
    if (mounted) Navigator.of(context).pop(failed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = widget.batch.members.length;
    return PopScope(
      canPop: !_working,
      child: AlertDialog(
        title: Text(l10n.markFamilyDepartedConfirmTitle(count)),
        content: Text(
          l10n.markFamilyDepartedConfirmMessage(
            checkOutReasonLower(l10n, widget.batch.reason),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _working ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _working ? null : _run,
            child: Text(
              _working
                  ? l10n.markFamilyDepartedWorking
                  : l10n.markFamilyDepartedConfirmButton,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
