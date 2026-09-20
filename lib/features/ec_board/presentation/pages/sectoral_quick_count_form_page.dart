import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../domain/entities/ec_board_quick_count.dart';
import '../../domain/entities/sectoral_group.dart';
import '../../domain/entities/sectoral_group_draft.dart';
import '../providers/ec_board_provider.dart';
import 'add_evacuee_form_page.dart' show localizedSectoralGroup;

/// The sectoral/4Ps edit form — same offline queue-then-sync shape as
/// Add Evacuee (see `SectoralGroupDraft`'s doc comment): "try online
/// first, fall back to the local pending queue" on save, and reopening
/// this page resumes whatever draft (pending-local or last-known-
/// synced) is currently the more current one.
class SectoralQuickCountFormPage extends ConsumerStatefulWidget {
  const SectoralQuickCountFormPage({
    super.key,
    required this.centerId,
    required this.evacuationEventId,
  });

  final int centerId;
  final int evacuationEventId;

  @override
  ConsumerState<SectoralQuickCountFormPage> createState() =>
      _SectoralQuickCountFormPageState();
}

class _SectoralQuickCountFormPageState
    extends ConsumerState<SectoralQuickCountFormPage> {
  SectoralGroupDraft? _draft;
  bool _dirty = false;
  bool _submitting = false;

  SectoralGroupDraft _emptyDraft() => SectoralGroupDraft(
    evacuationCenterId: widget.centerId,
    evacuationEventId: widget.evacuationEventId,
    beneficiaries4ps: 0,
    sectoralGroups: [
      for (final group in sectoralGroupValues)
        SectoralGroupEntry(group: group, maleCount: 0, femaleCount: 0),
    ],
  );

  SectoralGroupDraft _draftFromLastKnown(EcBoardQuickCount count) =>
      SectoralGroupDraft(
        evacuationCenterId: widget.centerId,
        evacuationEventId: widget.evacuationEventId,
        beneficiaries4ps: count.beneficiaries4ps,
        sectoralGroups: [
          for (final group in sectoralGroupValues)
            SectoralGroupEntry(
              group: group,
              maleCount:
                  count.sectoralGroups
                      .where((g) => g.group == group)
                      .firstOrNull
                      ?.maleCount ??
                  0,
              femaleCount:
                  count.sectoralGroups
                      .where((g) => g.group == group)
                      .firstOrNull
                      ?.femaleCount ??
                  0,
            ),
        ],
      );

  void _update(SectoralGroupDraft Function(SectoralGroupDraft) fn) {
    setState(() {
      _draft = fn(_draft ?? _emptyDraft());
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.staffRegDiscardDialogTitle),
        content: Text(l10n.staffRegDiscardDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.staffRegDiscardDialogConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, {required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    if (draft == null) return;

    setState(() => _submitting = true);
    final isOnline = await ref.read(connectivityServiceProvider).hasConnection;
    final repo = ref.read(ecBoardRepositoryProvider);

    if (!isOnline) {
      await repo.saveQuickCountEdit(draft);
      if (!mounted) return;
      setState(() => _submitting = false);
      _dirty = false;
      ref.invalidate(
        pendingQuickCountEditProvider(
          widget.centerId,
          widget.evacuationEventId,
        ),
      );
      _showSnack(l10n.ecBoardSectoralSavedOfflineMessage, isError: false);
      Navigator.of(context).maybePop();
      return;
    }

    final result = await ref.read(ecBoardUpdateQuickCountProvider)(draft);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success():
        _dirty = false;
        await repo.deleteQuickCountEdit(
          centerId: widget.centerId,
          evacuationEventId: widget.evacuationEventId,
        );
        if (!mounted) return;
        ref.invalidate(
          ecBoardQuickCountProvider(widget.centerId, widget.evacuationEventId),
        );
        ref.invalidate(
          pendingQuickCountEditProvider(
            widget.centerId,
            widget.evacuationEventId,
          ),
        );
        _showSnack(l10n.ecBoardSectoralSuccessMessage, isError: false);
        Navigator.of(context).maybePop();
      case Failed(:final failure):
        // Same reasoning as Add Evacuee's own failure branch: an
        // attempt was made online and it failed, so this is saved
        // locally as needsAttention rather than silently dropped —
        // staff still see it and can retry, same as any other queued
        // item that failed its first attempt.
        await repo.saveQuickCountEdit(draft);
        final category = switch (failure) {
          ValidationFailure() => PendingErrorCategory.validation,
          ForbiddenFailure() => PendingErrorCategory.forbidden,
          AmbiguousWriteFailure() => PendingErrorCategory.ambiguous,
          _ => PendingErrorCategory.server,
        };
        await repo.markQuickCountEditNeedsAttention(
          centerId: widget.centerId,
          evacuationEventId: widget.evacuationEventId,
          category: category,
          message: failure.message,
        );
        ref.invalidate(
          pendingQuickCountEditProvider(
            widget.centerId,
            widget.evacuationEventId,
          ),
        );
        if (!mounted) return;
        _showSnack(failure.message, isError: true);
        Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Seeds `_draft` once, the first time either source resolves: a
    // pending local edit takes priority (it's this device's own more
    // recent, unsynced intent) over the last-known synced figures.
    if (_draft == null) {
      final pendingAsync = ref.watch(
        pendingQuickCountEditProvider(
          widget.centerId,
          widget.evacuationEventId,
        ),
      );
      final pending = pendingAsync.value;
      if (pending != null) {
        _draft = pending.draft;
      } else if (pendingAsync.isLoading) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.ecBoardSectoralFormTitle)),
          body: const Center(child: CircularProgressIndicator()),
        );
      } else {
        final lastKnownAsync = ref.watch(
          ecBoardQuickCountProvider(widget.centerId, widget.evacuationEventId),
        );
        if (lastKnownAsync.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.ecBoardSectoralFormTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        _draft = switch (lastKnownAsync.value) {
          final count? => _draftFromLastKnown(count),
          null => _emptyDraft(),
        };
      }
    }

    final draft = _draft!;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.ecBoardSectoralFormTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.ecBoardSectoralFormSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: draft.beneficiaries4ps.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.ecBoardFourPsBeneficiaryFamilies,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => _update(
                  (d) => d.copyWith(beneficiaries4ps: int.tryParse(value) ?? 0),
                ),
              ),
              const Divider(height: 32),
              Text(
                l10n.ecBoardSectoralGroupsSectionTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.ecBoardSectoralFormFieldsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in draft.sectoralGroups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedSectoralGroup(context, entry.group),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: entry.maleCount.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.staffRegSexMale,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) => _update(
                                (d) => d.updateGroup(
                                  entry.group,
                                  maleCount: int.tryParse(value) ?? 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: entry.femaleCount.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.staffRegSexFemale,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) => _update(
                                (d) => d.updateGroup(
                                  entry.group,
                                  femaleCount: int.tryParse(value) ?? 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.ecBoardSectoralSaveButton),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
