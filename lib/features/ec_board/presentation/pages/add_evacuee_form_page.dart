import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/domain/entities/pending_registration.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../../registered_families/domain/entities/registered_family.dart';
import '../../../registered_families/presentation/providers/registered_families_provider.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_entry_draft.dart';
import '../../domain/entities/sectoral_group.dart';
import '../providers/ec_board_provider.dart';

/// Add Evacuee — a single evacuee's EC Information Board intake:
/// bracket + sex + which household. Also the Review/Edit screen for an
/// existing queued entry when [editingLocalId]/[initialDraft] are
/// given, same dual-purpose pattern `FamilyRegistrationFormPage` uses.
class AddEvacueeFormPage extends ConsumerStatefulWidget {
  const AddEvacueeFormPage({
    super.key,
    required this.centerId,
    required this.evacuationEventId,
    this.editingLocalId,
    this.initialDraft,
    this.initialHouseholdLabel,
  });

  final int centerId;
  final int evacuationEventId;
  final String? editingLocalId;
  final EcBoardEntryDraft? initialDraft;
  final String? initialHouseholdLabel;

  @override
  ConsumerState<AddEvacueeFormPage> createState() => _AddEvacueeFormPageState();
}

class _AddEvacueeFormPageState extends ConsumerState<AddEvacueeFormPage> {
  late EcBoardEntryDraft _draft;
  String? _householdLabel;
  bool _submitting = false;
  bool _dirty = false;

  bool get _isEditing => widget.editingLocalId != null;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.initialDraft ??
        EcBoardEntryDraft(
          evacuationCenterId: widget.centerId,
          evacuationEventId: widget.evacuationEventId,
          sex: null,
          ageBracket: null,
          householdMode: HouseholdMode.existing,
        );
    _householdLabel = widget.initialHouseholdLabel;
  }

  void _update(EcBoardEntryDraft Function(EcBoardEntryDraft) fn) {
    setState(() {
      _draft = fn(_draft);
      _dirty = true;
    });
  }

  Future<void> _pickExistingHousehold() async {
    final picked = await showModalBottomSheet<_HouseholdPick>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _HouseholdPickerSheet(),
    );
    if (picked == null) return;
    setState(() {
      _householdLabel = picked.label;
      _dirty = true;
      _draft = _draft.copyWith(
        existingFamilyRemoteId: picked.remoteFamilyId,
        clearExistingFamilyRemoteId: picked.remoteFamilyId == null,
        existingFamilyLocalId: picked.localFamilyId,
        clearExistingFamilyLocalId: picked.localFamilyId == null,
      );
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
    final householdLabel = _householdLabel;

    if (!_draft.isSubmittable || householdLabel == null) {
      _showSnack(l10n.ecBoardValidationBanner, isError: true);
      return;
    }

    setState(() => _submitting = true);
    final isOnline = await ref.read(connectivityServiceProvider).hasConnection;
    final queueRepo = ref.read(ecBoardRepositoryProvider);

    // Never attempted online even if connectivity is present: the
    // household reference is still only a local pending-registration
    // id, so the backend has nothing real to attach this evacuee to
    // yet — same reasoning as `EcBoardEntryDraft.isReadyToSync`.
    if (!isOnline || !_draft.isReadyToSync) {
      if (widget.editingLocalId case final localId?) {
        await queueRepo.updateDraft(
          localId,
          _draft,
          householdLabel: householdLabel,
        );
      } else {
        await queueRepo.enqueue(_draft, householdLabel: householdLabel);
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      _dirty = false;
      ref.invalidate(ecBoardEntriesForCenterProvider(widget.centerId));
      ref.invalidate(ecBoardCountsForCenterProvider(widget.centerId));
      _showSnack(
        !isOnline
            ? l10n.ecBoardSavedOfflineMessage
            : l10n.ecBoardSavedPendingHouseholdMessage,
        isError: false,
      );
      Navigator.of(context).maybePop();
      return;
    }

    final result = await ref.read(ecBoardSubmitProvider)(_draft);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success():
        _dirty = false;
        if (widget.editingLocalId case final localId?) {
          await queueRepo.delete(localId);
        }
        if (!mounted) return;
        ref.invalidate(ecBoardEntriesForCenterProvider(widget.centerId));
        ref.invalidate(ecBoardCountsForCenterProvider(widget.centerId));
        _showSnack(l10n.ecBoardSuccessMessage, isError: false);
        Navigator.of(context).maybePop();
      case Failed(:final failure):
        final localId = switch (widget.editingLocalId) {
          final id? => id,
          null => await queueRepo.enqueue(
            _draft,
            householdLabel: householdLabel,
          ),
        };
        if (widget.editingLocalId != null) {
          await queueRepo.updateDraft(
            localId,
            _draft,
            householdLabel: householdLabel,
          );
        }
        final category = switch (failure) {
          ValidationFailure() => PendingErrorCategory.validation,
          ForbiddenFailure() => PendingErrorCategory.forbidden,
          AmbiguousWriteFailure() => PendingErrorCategory.ambiguous,
          _ => PendingErrorCategory.server,
        };
        await queueRepo.markNeedsAttention(
          localId,
          category: category,
          message: failure.message,
        );
        ref.invalidate(ecBoardEntriesForCenterProvider(widget.centerId));
        ref.invalidate(ecBoardCountsForCenterProvider(widget.centerId));
        if (!mounted) return;
        _showSnack(failure.message, isError: true);
        Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? l10n.ecBoardEditEvacueeTitle
                : l10n.ecBoardAddEvacueeTitle,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.ecBoardFieldSex, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.staffRegSexMale),
                    selected: _draft.sex == 'male',
                    onSelected: (_) => _update((d) => d.copyWith(sex: 'male')),
                  ),
                  ChoiceChip(
                    label: Text(l10n.staffRegSexFemale),
                    selected: _draft.sex == 'female',
                    onSelected: (_) =>
                        _update((d) => d.copyWith(sex: 'female')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.ecBoardFieldAgeBracket,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final bracket in ageBracketValues)
                    ChoiceChip(
                      label: Text(localizedAgeBracket(context, bracket)),
                      selected: _draft.ageBracket == bracket,
                      onSelected: (_) =>
                          _update((d) => d.copyWith(ageBracket: bracket)),
                    ),
                ],
              ),
              const Divider(height: 32),
              Text(
                l10n.ecBoardFieldHousehold,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.ecBoardHouseholdExisting),
                    selected: _draft.householdMode == HouseholdMode.existing,
                    onSelected: (_) => _update(
                      (d) => d.copyWith(householdMode: HouseholdMode.existing),
                    ),
                  ),
                  ChoiceChip(
                    label: Text(l10n.ecBoardHouseholdNew),
                    selected: _draft.householdMode == HouseholdMode.new_,
                    onSelected: (_) => setState(() {
                      _householdLabel = null;
                      _dirty = true;
                      _draft = _draft.copyWith(
                        householdMode: HouseholdMode.new_,
                        clearExistingFamilyRemoteId: true,
                        clearExistingFamilyLocalId: true,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_draft.householdMode == HouseholdMode.existing) ...[
                OutlinedButton.icon(
                  onPressed: _pickExistingHousehold,
                  icon: const Icon(Icons.search),
                  label: Text(
                    _householdLabel ?? l10n.ecBoardSelectHouseholdButton,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_draft.existingFamilyLocalId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.ecBoardPendingHouseholdNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else ...[
                TextFormField(
                  initialValue: _draft.newHouseholdHeadName,
                  decoration: InputDecoration(
                    labelText: l10n.ecBoardNewHouseholdHeadName,
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    setState(() {
                      _householdLabel = value.trim().isEmpty
                          ? null
                          : value.trim();
                      _dirty = true;
                      _draft = _draft.copyWith(newHouseholdHeadName: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final barangaysAsync = ref.watch(barangaysProvider);
                    return barangaysAsync.when(
                      data: (barangays) => DropdownButtonFormField<int>(
                        initialValue: _draft.newHouseholdBarangayId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.staffRegFieldBarangay,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final barangay in barangays)
                            DropdownMenuItem(
                              value: barangay.id,
                              child: Text(
                                barangay.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        selectedItemBuilder: (context) => [
                          for (final barangay in barangays)
                            Text(
                              barangay.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                        onChanged: (id) => _update(
                          (d) => d.copyWith(newHouseholdBarangayId: id),
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stackTrace) => Text(
                        l10n.staffRegLookupUnavailable,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
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
                    : Text(l10n.ecBoardSubmitButton),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseholdPick {
  const _HouseholdPick({
    required this.label,
    this.remoteFamilyId,
    this.localFamilyId,
  });

  final String label;
  final int? remoteFamilyId;
  final String? localFamilyId;
}

/// Lists both already-synced families (real `id`) and this device's
/// own still-pending family registrations (`localId` only) — kept
/// visually distinct (a "Pending" badge) so staff know which choice
/// means "syncs immediately" vs "waits for its own household to sync
/// first" (see `EcBoardEntryDraft`'s doc comment).
class _HouseholdPickerSheet extends ConsumerStatefulWidget {
  const _HouseholdPickerSheet();

  @override
  ConsumerState<_HouseholdPickerSheet> createState() =>
      _HouseholdPickerSheetState();
}

class _HouseholdPickerSheetState extends ConsumerState<_HouseholdPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final syncedAsync = ref.watch(registeredFamiliesCacheOnlyProvider);
    final pendingAsync = ref.watch(pendingRegistrationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ecBoardSelectHouseholdButton,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.ecBoardHouseholdSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...pendingAsync
                        .maybeWhen(
                          data: (items) => _filteredPending(items),
                          orElse: () => const <PendingRegistrationSummary>[],
                        )
                        .map(
                          (item) => ListTile(
                            leading: const Icon(Icons.cloud_off_outlined),
                            title: Text(
                              item.headOfFamilyName.isEmpty
                                  ? l10n.staffPendingNoHeadName
                                  : item.headOfFamilyName,
                            ),
                            subtitle: Text(l10n.ecBoardPendingHouseholdBadge),
                            onTap: () => Navigator.of(context).pop(
                              _HouseholdPick(
                                label: item.headOfFamilyName.isEmpty
                                    ? l10n.staffPendingNoHeadName
                                    : item.headOfFamilyName,
                                localFamilyId: item.localId,
                              ),
                            ),
                          ),
                        ),
                    ...syncedAsync
                        .maybeWhen(
                          data: (items) => _filteredSynced(items),
                          orElse: () => const <RegisteredFamily>[],
                        )
                        .map(
                          (item) => ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(
                              item.headOfFamilyName.isEmpty
                                  ? l10n.staffPendingNoHeadName
                                  : item.headOfFamilyName,
                            ),
                            subtitle: Text(item.barangayName),
                            onTap: () => Navigator.of(context).pop(
                              _HouseholdPick(
                                label: item.headOfFamilyName.isEmpty
                                    ? l10n.staffPendingNoHeadName
                                    : item.headOfFamilyName,
                                remoteFamilyId: item.id,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PendingRegistrationSummary> _filteredPending(
    List<PendingRegistrationSummary> items,
  ) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where((i) => i.headOfFamilyName.toLowerCase().contains(q))
        .toList();
  }

  List<RegisteredFamily> _filteredSynced(List<RegisteredFamily> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where((i) => i.headOfFamilyName.toLowerCase().contains(q))
        .toList();
  }
}

/// Localized display label for an `AgeBracket` — same "don't invent,
/// don't hide" convention as `localizedCenterStatus`.
String localizedAgeBracket(BuildContext context, AgeBracket bracket) {
  final l10n = AppLocalizations.of(context);
  return switch (bracket) {
    AgeBracket.infant => l10n.ecBoardBracketInfant,
    AgeBracket.toddler => l10n.ecBoardBracketToddler,
    AgeBracket.preschooler => l10n.ecBoardBracketPreschooler,
    AgeBracket.schoolAge => l10n.ecBoardBracketSchoolAge,
    AgeBracket.teenage => l10n.ecBoardBracketTeenage,
    AgeBracket.adult => l10n.ecBoardBracketAdult,
    AgeBracket.seniorCitizen => l10n.ecBoardBracketSeniorCitizen,
  };
}

/// Localized display label for a `SectoralGroup` — read-only display
/// use only (see that enum's doc comment for why this app never lets
/// staff set these values itself).
String localizedSectoralGroup(BuildContext context, SectoralGroup group) {
  final l10n = AppLocalizations.of(context);
  return switch (group) {
    SectoralGroup.pwd => l10n.ecBoardSectoralPwd,
    SectoralGroup.childHeadedFamily => l10n.ecBoardSectoralChildHeadedFamily,
    SectoralGroup.singleHeadedFamily => l10n.ecBoardSectoralSingleHeadedFamily,
    SectoralGroup.soloParent => l10n.ecBoardSectoralSoloParent,
    SectoralGroup.pregnantWomen => l10n.ecBoardSectoralPregnantWomen,
    SectoralGroup.lactatingMothers => l10n.ecBoardSectoralLactatingMothers,
    SectoralGroup.fourPsBeneficiary => l10n.ecBoardSectoralFourPsBeneficiary,
    SectoralGroup.indigenousPeoples => l10n.ecBoardSectoralIndigenousPeoples,
  };
}
