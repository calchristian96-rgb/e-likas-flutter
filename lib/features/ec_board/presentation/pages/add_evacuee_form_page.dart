import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/domain/entities/lookup_entities.dart';
import '../../../family_registration/domain/entities/pending_registration.dart';
import '../../../family_registration/domain/entities/pending_registration_status.dart';
import '../../../family_registration/presentation/providers/lookup_providers.dart';
import '../../../family_registration/presentation/providers/pending_queue_provider.dart';
import '../../../registered_families/domain/entities/registered_families_snapshot.dart';
import '../../../registered_families/domain/entities/registered_family.dart';
import '../../../registered_families/presentation/providers/registered_families_provider.dart';
import '../../domain/entities/age_bracket.dart';
import '../../domain/entities/ec_board_entry_draft.dart';
import '../../domain/entities/pending_ec_board_entry.dart';
import '../../domain/entities/per_person_sectoral_flag.dart';
import '../../domain/entities/sectoral_group.dart';
import '../providers/ec_board_provider.dart';

/// Add Evacuee — a single evacuee's EC Information Board intake, in the
/// same four sections, order and wording as the web dashboard's Add
/// evacuee panel: who this person is, their household, the household's
/// actual head (only when that's someone else), then optional sectoral
/// details — with a plain-language "Will be recorded" read-back pinned
/// beside the save button. Also the Review/Edit screen for an existing
/// queued entry when [editingLocalId]/[initialDraft] are given, same
/// dual-purpose pattern `FamilyRegistrationFormPage` uses.
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

  /// Whether the chosen "Already here" household has no head linked yet
  /// — the only case "This person is the household head" is offered
  /// there (the real head arriving later). Never offered otherwise: the
  /// server never replaces a linked head from Add Evacuee.
  bool _existingHeadOffered = false;

  bool get _isEditing => widget.editingLocalId != null;

  bool get _isNew => _draft.householdMode == HouseholdMode.new_;

  /// Whether the person being added is being recorded as the head —
  /// the New household tickbox, or the Already here one when offered.
  bool get _personIsHead =>
      _draft.headIsSelf && (_isNew || _existingHeadOffered);

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
    // Reopening a queued entry that links its household's head: it was
    // only ever allowed because that household had no head, so keep
    // offering it; otherwise look the household up to decide.
    _existingHeadOffered =
        _draft.householdMode == HouseholdMode.existing && _draft.headIsSelf;
    if (!_existingHeadOffered &&
        _draft.householdMode == HouseholdMode.existing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookUpHeadOffer());
    }
  }

  /// Best-effort: if the household can't be looked up (nothing cached
  /// yet), the tick simply isn't offered — the safe default, since the
  /// server never links a head over an existing one anyway.
  Future<void> _lookUpHeadOffer() async {
    final remoteId = _draft.existingFamilyRemoteId;
    final localId = _draft.existingFamilyLocalId;
    var offered = false;
    try {
      if (remoteId != null) {
        final cached = await ref.read(
          registeredFamiliesCacheOnlyProvider.future,
        );
        offered = cached.any((f) => f.id == remoteId && !f.hasHeadLinked);
      } else if (localId != null) {
        final pendingNew = await ref.read(
          ecBoardPendingNewHouseholdsProvider(
            widget.centerId,
            widget.evacuationEventId,
          ).future,
        );
        offered = pendingNew.any((e) => e.localId == localId && !e.headIsSelf);
      }
    } catch (_) {
      return;
    }
    if (mounted && offered) setState(() => _existingHeadOffered = true);
  }

  void _update(EcBoardEntryDraft Function(EcBoardEntryDraft) fn) {
    setState(() {
      _draft = fn(_draft);
      _dirty = true;
    });
  }

  void _setMode(HouseholdMode mode) {
    if (mode == _draft.householdMode) return;
    setState(() {
      _dirty = true;
      _householdLabel = mode == HouseholdMode.new_
          ? _trimmedOrNull(_draft.newHouseholdHeadName)
          : null;
      _existingHeadOffered = false;
      _draft = _draft.copyWith(
        householdMode: mode,
        clearExistingFamilyRemoteId: true,
        clearExistingFamilyLocalId: true,
        // A new household defaults to "this person is the head" (the
        // common case, same as the web form); Already here never does.
        headIsSelf: mode == HouseholdMode.new_,
        isSingleHeaded: (value: null),
        headIsMinor: (value: null),
        headSex: (value: null),
      );
    });
  }

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickExistingHousehold() async {
    final picked = await showModalBottomSheet<_HouseholdPick>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _HouseholdPickerSheet(
        centerId: widget.centerId,
        evacuationEventId: widget.evacuationEventId,
      ),
    );
    if (picked == null) return;
    setState(() {
      _householdLabel = picked.label;
      _dirty = true;
      _existingHeadOffered = !picked.headLinked;
      _draft = _draft.copyWith(
        existingFamilyRemoteId: picked.remoteFamilyId,
        clearExistingFamilyRemoteId: picked.remoteFamilyId == null,
        existingFamilyLocalId: picked.localFamilyId,
        clearExistingFamilyLocalId: picked.localFamilyId == null,
        // A different household: the head tick was about the old one.
        headIsSelf: false,
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

    // Never send a head tick for an existing household that wasn't
    // offered one (e.g. its head got linked since the entry was queued).
    final draft = _isNew || _existingHeadOffered
        ? _draft
        : _draft.copyWith(headIsSelf: false);

    setState(() => _submitting = true);
    final isOnline = await ref.read(connectivityServiceProvider).hasConnection;
    final queueRepo = ref.read(ecBoardRepositoryProvider);

    // Never attempted online even if connectivity is present: the
    // household reference is still only a local pending-registration
    // id, so the backend has nothing real to attach this evacuee to
    // yet — same reasoning as `EcBoardEntryDraft.isReadyToSync`.
    if (!isOnline || !draft.isReadyToSync) {
      if (widget.editingLocalId case final localId?) {
        await queueRepo.updateDraft(
          localId,
          draft,
          householdLabel: householdLabel,
        );
      } else {
        await queueRepo.enqueue(draft, householdLabel: householdLabel);
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

    final result = await ref.read(ecBoardSubmitProvider)(draft);
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
        // The household's head link/answers may have just changed.
        ref.invalidate(registeredFamiliesProvider);
        _showSnack(l10n.ecBoardSuccessMessage, isError: false);
        Navigator.of(context).maybePop();
      case Failed(:final failure):
        final localId = switch (widget.editingLocalId) {
          final id? => id,
          null => await queueRepo.enqueue(
            draft,
            householdLabel: householdLabel,
          ),
        };
        if (widget.editingLocalId != null) {
          await queueRepo.updateDraft(
            localId,
            draft,
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

  /// The "Will be recorded" read-back: plain sentences built from
  /// exactly what [_submit] will send, so a wrong answer is visible
  /// before saving — the same sentences the web form shows.
  List<String> _summaryLines(AppLocalizations l10n, List<Barangay> barangays) {
    String minorText(bool? isMinor) => switch (isMinor) {
      null => l10n.ecBoardSummaryMinorUnknown,
      true => l10n.ecBoardSummaryMinor,
      false => l10n.ecBoardSummaryNotMinor,
    };
    String sexText(String? sex) => switch (sex) {
      'male' => l10n.ecBoardSummaryMale,
      'female' => l10n.ecBoardSummaryFemale,
      _ => l10n.ecBoardSummarySexNotYetKnown,
    };
    final bracket = _draft.ageBracket;
    final lines = <String>[
      if (_draft.sex == null || bracket == null)
        l10n.ecBoardSummaryChooseAgeSex
      else
        l10n.ecBoardSummaryAdding(
          sexText(_draft.sex),
          localizedAgeBracket(context, bracket).toLowerCase(),
        ),
    ];

    if (!_isNew) {
      final label = _householdLabel;
      lines.add(
        label == null
            ? l10n.ecBoardSummaryChooseHousehold
            : l10n.ecBoardSummaryJoinsHousehold(label),
      );
      if (_personIsHead) {
        lines.add(l10n.ecBoardSummaryBecomesHead(minorText(bracket?.isMinor)));
      }
    } else {
      final barangayName = barangays
          .where((b) => b.id == _draft.newHouseholdBarangayId)
          .map((b) => b.name)
          .firstOrNull;
      lines
        ..add(
          l10n.ecBoardSummaryNewHousehold(
            _trimmedOrNull(_draft.newHouseholdHeadName) ??
                l10n.ecBoardSummaryNoHeadName,
            barangayName ?? l10n.ecBoardSummaryNoBarangay,
          ),
        )
        ..add(
          _draft.headIsSelf
              ? l10n.ecBoardSummaryHeadIsThisPerson(minorText(bracket?.isMinor))
              : l10n.ecBoardSummaryHeadIsSomeoneElse(
                  sexText(_draft.headSex),
                  minorText(_draft.headIsMinor),
                ),
        )
        ..add(
          l10n.ecBoardSummarySingleHeaded(switch (_draft.isSingleHeaded) {
            null => l10n.ecBoardSummaryAnswerUnknown,
            true => l10n.ecBoardSummaryAnswerYes,
            false => l10n.ecBoardSummaryAnswerNo,
          }),
        );
    }

    final flags = [
      for (final flag in PerPersonSectoralFlag.values)
        if (_draft.sectoralFlags.contains(flag)) localizedFlag(context, flag),
    ];
    lines.add(
      flags.isEmpty
          ? l10n.ecBoardSummaryNoSectoral
          : l10n.ecBoardSummarySectoral(flags.join(', ')),
    );
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Only a new household names a barangay (for the read-back).
    final barangays = _isNew
        ? ref.watch(barangaysProvider).value ?? const <Barangay>[]
        : const <Barangay>[];

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
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Text(
                      l10n.ecBoardAddEvacueeIntro,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: l10n.ecBoardSectionWhoIsThisPerson,
                      children: [
                        _FieldLabel(l10n.ecBoardFieldAgeBracket),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final bracket in ageBracketValues)
                              ChoiceChip(
                                label: Text(
                                  localizedAgeBracket(context, bracket),
                                ),
                                selected: _draft.ageBracket == bracket,
                                onSelected: (_) => _update(
                                  (d) => d.copyWith(ageBracket: bracket),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(l10n.ecBoardFieldSex),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.staffRegSexMale),
                              selected: _draft.sex == 'male',
                              // Pregnant/lactating are hidden for a male
                              // evacuee, so any already ticked are
                              // cleared too — a hidden flag would
                              // otherwise still be sent (and rejected).
                              onSelected: (_) => _update(
                                (d) => d.copyWith(
                                  sex: 'male',
                                  sectoralFlags: d.sectoralFlags
                                      .where((f) => !f.femaleOnly)
                                      .toSet(),
                                ),
                              ),
                            ),
                            ChoiceChip(
                              label: Text(l10n.staffRegSexFemale),
                              selected: _draft.sex == 'female',
                              onSelected: (_) =>
                                  _update((d) => d.copyWith(sex: 'female')),
                            ),
                          ],
                        ),
                        if (_personIsHead) ...[
                          const SizedBox(height: 12),
                          _HeadNote(text: l10n.ecBoardHeadNote),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: l10n.ecBoardFieldHousehold,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<HouseholdMode>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: HouseholdMode.existing,
                                label: Text(l10n.ecBoardHouseholdExisting),
                              ),
                              ButtonSegment(
                                value: HouseholdMode.new_,
                                label: Text(l10n.ecBoardHouseholdNew),
                              ),
                            ],
                            selected: {_draft.householdMode},
                            onSelectionChanged: (s) => _setMode(s.first),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isNew) ...[
                          OutlinedButton.icon(
                            onPressed: _pickExistingHousehold,
                            icon: const Icon(Icons.search),
                            label: Text(
                              _householdLabel ??
                                  l10n.ecBoardSelectHouseholdButton,
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
                          if (_existingHeadOffered)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _draft.headIsSelf,
                              title: Text(l10n.ecBoardThisPersonIsHead),
                              subtitle: Text(l10n.ecBoardNoHeadLinkedYet),
                              onChanged: (on) => _update(
                                (d) => d.copyWith(headIsSelf: on ?? false),
                              ),
                            ),
                        ] else ...[
                          _BarangayDropdown(
                            value: _draft.newHouseholdBarangayId,
                            onChanged: (id) => _update(
                              (d) => d.copyWith(newHouseholdBarangayId: id),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _draft.newHouseholdHeadName,
                            decoration: InputDecoration(
                              labelText: l10n.ecBoardNewHouseholdHeadName,
                              hintText: 'e.g. Juan Dela Cruz',
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) => setState(() {
                              _householdLabel = _trimmedOrNull(value);
                              _dirty = true;
                              _draft = _draft.copyWith(
                                newHouseholdHeadName: value,
                              );
                            }),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _draft.headIsSelf,
                            title: Text(l10n.ecBoardThisPersonIsHead),
                            // Head's sex / minor describe someone else,
                            // so they're cleared when this person heads
                            // the household instead.
                            onChanged: (on) => _update(
                              (d) => d.copyWith(
                                headIsSelf: on ?? false,
                                headSex: (value: null),
                                headIsMinor: (value: null),
                              ),
                            ),
                          ),
                          _FieldLabel(l10n.ecBoardSingleHeadedQuestion),
                          _TriStateAnswer<bool>(
                            value: _draft.isSingleHeaded,
                            options: [
                              (true, l10n.ecBoardAnswerYes),
                              (false, l10n.ecBoardAnswerNo),
                            ],
                            onChanged: (v) => _update(
                              (d) => d.copyWith(isSingleHeaded: (value: v)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isNew && !_draft.headIsSelf) ...[
                      const SizedBox(height: 12),
                      _HeadOfHouseholdInset(
                        headSex: _draft.headSex,
                        headIsMinor: _draft.headIsMinor,
                        onHeadSexChanged: (v) =>
                            _update((d) => d.copyWith(headSex: (value: v))),
                        onHeadIsMinorChanged: (v) =>
                            _update((d) => d.copyWith(headIsMinor: (value: v))),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SectoralFlagsSection(
                      selected: _draft.sectoralFlags,
                      isMale: _draft.sex == 'male',
                      onChanged: (flags) =>
                          _update((d) => d.copyWith(sectoralFlags: flags)),
                    ),
                  ],
                ),
              ),
              // Hidden while typing: above the keyboard it would leave
              // only a sliver of the form visible.
              if (MediaQuery.viewInsetsOf(context).bottom == 0)
                _WillBeRecordedFooter(
                  lines: _summaryLines(l10n, barangays),
                  submitting: _submitting,
                  onSubmit: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One titled section of the form — each about ONE subject, so a field
/// never leaves it unclear who it describes.
class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _HeadNote extends StatelessWidget {
  const _HeadNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.how_to_reg_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Not yet known" plus the given answers. "Not yet known" is always
/// available and is stored as null — never guessed as "no".
class _TriStateAnswer<T> extends StatelessWidget {
  const _TriStateAnswer({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.ecBoardAnswerNotYetKnown),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final (option, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == option,
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}

/// Only when the head is someone OTHER than the person being added: set
/// apart (a tinted inset, the web form's dashed box) so these two answers
/// can't be mistaken for this person's own.
class _HeadOfHouseholdInset extends StatelessWidget {
  const _HeadOfHouseholdInset({
    required this.headSex,
    required this.headIsMinor,
    required this.onHeadSexChanged,
    required this.onHeadIsMinorChanged,
  });

  final String? headSex;
  final bool? headIsMinor;
  final ValueChanged<String?> onHeadSexChanged;
  final ValueChanged<bool?> onHeadIsMinorChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ecBoardHeadSectionTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            l10n.ecBoardHeadSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(l10n.ecBoardHeadSexLabel),
          _TriStateAnswer<String>(
            value: headSex,
            options: [
              ('male', l10n.staffRegSexMale),
              ('female', l10n.staffRegSexFemale),
            ],
            onChanged: onHeadSexChanged,
          ),
          const SizedBox(height: 12),
          _FieldLabel(l10n.ecBoardHeadIsMinorLabel),
          _TriStateAnswer<bool>(
            value: headIsMinor,
            options: [
              (true, l10n.ecBoardAnswerYesUnder18),
              (false, l10n.ecBoardAnswerNo),
            ],
            onChanged: onHeadIsMinorChanged,
          ),
        ],
      ),
    );
  }
}

class _BarangayDropdown extends ConsumerWidget {
  const _BarangayDropdown({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ref
        .watch(barangaysProvider)
        .when(
          data: (barangays) => DropdownButtonFormField<int>(
            initialValue: value,
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
            onChanged: onChanged,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text(
            l10n.staffRegLookupUnavailable,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        );
  }
}

/// Pinned below the scrolling form, so the read-back and the save
/// button stay in view however many questions are open above them.
class _WillBeRecordedFooter extends StatelessWidget {
  const _WillBeRecordedFooter({
    required this.lines,
    required this.submitting,
    required this.onSubmit,
  });

  final List<String> lines;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ecBoardWillBeRecordedTitle,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(line, style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: submitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.ecBoardSubmitButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optional sectoral flags for the ONE person being added, collapsed by
/// default so the common case (most evacuees are none of these) stays
/// fast — and opened already when editing an entry that has some set.
/// Unticked means "not recorded", not "no".
class _SectoralFlagsSection extends StatelessWidget {
  const _SectoralFlagsSection({
    required this.selected,
    required this.isMale,
    required this.onChanged,
  });

  final Set<PerPersonSectoralFlag> selected;
  final bool isMale;
  final ValueChanged<Set<PerPersonSectoralFlag>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: selected.isNotEmpty,
        title: Text(l10n.ecBoardSectoralFlagsTitle),
        subtitle: selected.isEmpty
            ? null
            : Text(l10n.ecBoardSectoralFlagsTicked(selected.length)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final flag in PerPersonSectoralFlag.values)
                if (!(flag.femaleOnly && isMale))
                  FilterChip(
                    label: Text(localizedFlag(context, flag)),
                    selected: selected.contains(flag),
                    onSelected: (on) => onChanged(
                      on ? {...selected, flag} : ({...selected}..remove(flag)),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.ecBoardSectoralFlagsHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one person's own flag label — the same words the full
/// registration form uses for a member ("Pregnant", not the board's
/// "Pregnant Women" row name).
String localizedFlag(BuildContext context, PerPersonSectoralFlag flag) {
  final l10n = AppLocalizations.of(context);
  return switch (flag) {
    PerPersonSectoralFlag.pwd => l10n.staffRegIsPwd,
    PerPersonSectoralFlag.pregnant => l10n.staffRegIsPregnant,
    PerPersonSectoralFlag.lactating => l10n.staffRegIsLactating,
    PerPersonSectoralFlag.soloParent => l10n.staffRegIsSoloParent,
    PerPersonSectoralFlag.indigenousPerson => l10n.staffRegIsIndigenous,
    PerPersonSectoralFlag.fourPsBeneficiary => l10n.staffRegIs4psMember,
  };
}

class _HouseholdPick {
  const _HouseholdPick({
    required this.label,
    required this.headLinked,
    this.remoteFamilyId,
    this.localFamilyId,
  });

  final String label;

  /// Whether this household already has its head — when not, the form
  /// offers "This person is the household head".
  final bool headLinked;
  final int? remoteFamilyId;
  final String? localFamilyId;
}

/// Lists both already-synced families (real `id`) and this device's
/// own still-pending family registrations (`localId` only) — kept
/// visually distinct (a "Pending" badge) so staff know which choice
/// means "syncs immediately" vs "waits for its own household to sync
/// first" (see `EcBoardEntryDraft`'s doc comment).
class _HouseholdPickerSheet extends ConsumerStatefulWidget {
  const _HouseholdPickerSheet({
    required this.centerId,
    required this.evacuationEventId,
  });

  final int centerId;
  final int evacuationEventId;

  @override
  ConsumerState<_HouseholdPickerSheet> createState() =>
      _HouseholdPickerSheetState();
}

class _HouseholdPickerSheetState extends ConsumerState<_HouseholdPickerSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Forces a genuine network attempt every time the picker opens,
    // rather than showing whatever `registeredFamiliesProvider` last
    // happened to have cached — a household registered earlier in this
    // same session must show up here without leaving this screen.
    // Deferred to right after the first frame: `ref.invalidate` needs
    // this element's `InheritedWidget` dependencies (the surrounding
    // `ProviderScope`) already resolved, which isn't true yet inside
    // `initState` itself — calling it here directly throws
    // "dependOnInheritedWidgetOfExactType... was called before
    // initState() completed".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(registeredFamiliesProvider);
    });
  }

  Future<void> _refreshSynced() async {
    ref.invalidate(registeredFamiliesProvider);
    try {
      await ref.read(registeredFamiliesProvider.future);
    } catch (_) {
      // The error state below already handles this — this callback
      // just needs to let the pull-to-refresh spinner finish.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final syncedAsync = ref.watch(registeredFamiliesProvider);
    final pendingAsync = ref.watch(pendingRegistrationsProvider);
    final pendingNewHouseholdsAsync = ref.watch(
      ecBoardPendingNewHouseholdsProvider(
        widget.centerId,
        widget.evacuationEventId,
      ),
    );

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.ecBoardSelectHouseholdButton,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: syncedAsync.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: l10n.ecBoardRefreshHouseholdsTooltip,
                    onPressed: syncedAsync.isLoading ? null : _refreshSynced,
                  ),
                ],
              ),
              _SyncedFreshnessLine(syncedAsync: syncedAsync, l10n: l10n),
              const SizedBox(height: 4),
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
                child: RefreshIndicator(
                  onRefresh: _refreshSynced,
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      ...pendingNewHouseholdsAsync
                          .maybeWhen(
                            data: (items) => _filteredNewHouseholds(items),
                            orElse: () => const <PendingEcBoardEntrySummary>[],
                          )
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.cloud_off_outlined),
                              title: Text(item.householdLabel),
                              subtitle: Text(
                                l10n.ecBoardPendingNewHouseholdBadge,
                              ),
                              onTap: () => Navigator.of(context).pop(
                                _HouseholdPick(
                                  label: item.householdLabel,
                                  localFamilyId: item.localId,
                                  headLinked: item.headIsSelf,
                                ),
                              ),
                            ),
                          ),
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
                                  // A full registration always has
                                  // exactly one head.
                                  headLinked: true,
                                ),
                              ),
                            ),
                          ),
                      ...switch (syncedAsync) {
                        AsyncData(:final value) => _filteredSynced(
                          value.families,
                        ).map(_syncedTile),
                        AsyncError(:final error) => [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: ErrorState(
                              message: _describeSyncedError(error, l10n),
                              onRetry: _refreshSynced,
                            ),
                          ),
                        ],
                        _ => const <Widget>[],
                      },
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ListTile _syncedTile(RegisteredFamily item) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
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
          headLinked: item.hasHeadLinked,
        ),
      ),
    );
  }

  String _describeSyncedError(Object error, AppLocalizations l10n) {
    if (error is NetworkFailure) return l10n.staffFamiliesNoCacheMessage;
    if (error is Failure) return error.message;
    return l10n.staffFamiliesLoadError;
  }

  List<PendingEcBoardEntrySummary> _filteredNewHouseholds(
    List<PendingEcBoardEntrySummary> items,
  ) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where((i) => i.householdLabel.toLowerCase().contains(q))
        .toList();
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

  /// Never offers a legacy bulk-entry household: it isn't a real family,
  /// and the server refuses to add anyone to one.
  List<RegisteredFamily> _filteredSynced(List<RegisteredFamily> items) {
    final q = _query.toLowerCase();
    return items
        .where((i) => !i.isLegacyBulkEntry)
        .where((i) => q.isEmpty || i.headOfFamilyName.toLowerCase().contains(q))
        .toList();
  }
}

/// The synced-households freshness note under the picker's title —
/// same "Showing data as of ..." / "Showing saved data" convention as
/// `RegisteredFamiliesPage`'s own `_FreshnessLine`, so a household
/// list that's actually still a cached fallback (offline, or the fetch
/// this sheet just triggered failed) is never presented as if it were
/// live without saying so.
class _SyncedFreshnessLine extends StatelessWidget {
  const _SyncedFreshnessLine({required this.syncedAsync, required this.l10n});

  final AsyncValue<RegisteredFamiliesSnapshot> syncedAsync;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final snapshot = syncedAsync.value;
    final theme = Theme.of(context);
    if (snapshot == null) return const SizedBox.shrink();

    final String text;
    final epochMs = snapshot.lastSyncedAtEpochMs;
    if (!snapshot.isFromCache) {
      text = l10n.ecBoardHouseholdsUpToDate;
    } else if (epochMs != null) {
      final formatted = DateFormat.yMMMd().add_jm().format(
        DateTime.fromMillisecondsSinceEpoch(epochMs),
      );
      text = l10n.staffFamiliesShowingAsOf(formatted);
    } else {
      text = l10n.staffFamiliesShowingSaved;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
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
