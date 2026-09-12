import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../registered_families/domain/entities/registered_family.dart';
import '../../../registered_families/presentation/providers/registered_families_provider.dart';
import '../../../registered_families/presentation/widgets/registered_family_detail_sheet.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../domain/duplicate_match/duplicate_name_matcher.dart';
import '../../domain/entities/family_member_draft.dart';
import '../../domain/entities/family_registration_draft.dart';
import '../../domain/entities/lookup_entities.dart';
import '../../domain/entities/pending_registration_status.dart';
import '../../domain/validators/contact_number_validator.dart';
import '../providers/lookup_providers.dart';
import '../providers/pending_queue_provider.dart';
import '../providers/registration_submit_provider.dart';
import '../widgets/family_member_card.dart';

/// Also the Review/Edit screen for an existing `needsAttention` queue
/// record: pass [editingLocalId] + [initialDraft] (the Pending
/// Registrations detail page does this) and every save writes back
/// onto that same record instead of creating a new one.
class FamilyRegistrationFormPage extends StatelessWidget {
  const FamilyRegistrationFormPage({
    super.key,
    this.editingLocalId,
    this.initialDraft,
    this.initialFieldErrors = const {},
  });

  final String? editingLocalId;
  final FamilyRegistrationDraft? initialDraft;
  final Map<String, List<String>> initialFieldErrors;

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) => _FamilyRegistrationFormBody(
        session: session,
        editingLocalId: editingLocalId,
        initialDraft: initialDraft,
        initialFieldErrors: initialFieldErrors,
      ),
    );
  }
}

class _FamilyRegistrationFormBody extends ConsumerStatefulWidget {
  const _FamilyRegistrationFormBody({
    required this.session,
    this.editingLocalId,
    this.initialDraft,
    this.initialFieldErrors = const {},
  });

  final StaffSession session;
  final String? editingLocalId;
  final FamilyRegistrationDraft? initialDraft;
  final Map<String, List<String>> initialFieldErrors;

  @override
  ConsumerState<_FamilyRegistrationFormBody> createState() =>
      _FamilyRegistrationFormBodyState();
}

class _FamilyRegistrationFormBodyState
    extends ConsumerState<_FamilyRegistrationFormBody> {
  late FamilyRegistrationDraft _draft;
  late Map<String, List<String>> _fieldErrors;
  bool _submitting = false;
  bool _dirty = false;

  /// Cache-only snapshot (Phase 2's `getCachedOnly()`, never a network
  /// call) that local duplicate-name checking runs against. Loaded
  /// once and held in memory rather than re-read per keystroke — see
  /// [_scheduleDuplicateCheck] for the actual debounce.
  List<RegisteredFamily> _duplicateCheckCache = const [];
  final Map<int, RegisteredFamily?> _possibleMatches = {};
  final Map<int, Timer> _debounceTimers = {};

  bool get _isEditing => widget.editingLocalId != null;

  @override
  void initState() {
    super.initState();
    _loadDuplicateCheckCache();
    _draft =
        widget.initialDraft ??
        const FamilyRegistrationDraft(
          evacuationEventId: null,
          barangayId: null,
          displacementType: null,
        );
    _fieldErrors = widget.initialFieldErrors;

    // The family's home barangay and the staff member's own assigned
    // barangay are separate concepts — a barangay official may
    // legitimately register a displaced family whose home barangay
    // isn't their own (the backend's own barangay-scoping rule is
    // about who is allowed to *submit* the registration, not which
    // barangay the family may be from). So this only ever pre-fills a
    // convenient starting value for a brand-new registration — it
    // never locks the field, and it never overwrites an existing
    // draft's real saved barangay when editing (initialDraft != null
    // skips this entirely).
    if (widget.initialDraft == null &&
        widget.session.isBarangayOfficial &&
        widget.session.barangayId != null) {
      _draft = _draft.copyWith(barangayId: widget.session.barangayId);
    }
  }

  void _markDirty() => _dirty = true;

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _loadDuplicateCheckCache() async {
    final cache = await ref.read(registeredFamiliesCacheOnlyProvider.future);
    if (!mounted) return;
    setState(() => _duplicateCheckCache = cache);
  }

  /// Member indices shift on add/remove, so any per-index match/timer
  /// state from before is no longer meaningfully attached to the right
  /// member — cleared rather than left stale. A warning that was
  /// showing simply reappears on the next edit of that field.
  void _resetDuplicateChecks() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _possibleMatches.clear();
  }

  /// 400ms after the member's name fields stop changing, checks it
  /// against [_duplicateCheckCache] — local only, never a network
  /// call, and never blocks anything (see
  /// `duplicate_name_matcher.dart`'s doc comment for the matching
  /// rules themselves).
  void _scheduleDuplicateCheck(int index) {
    _debounceTimers[index]?.cancel();
    _debounceTimers[index] = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || index >= _draft.members.length) return;
      final member = _draft.members[index];
      RegisteredFamily? match;
      for (final family in _duplicateCheckCache) {
        final hit = family.memberNames.any(
          (name) => isPossibleDuplicateMember(
            firstName: member.firstName,
            middleName: member.middleName ?? '',
            lastName: member.lastName,
            candidateFullName: name,
          ),
        );
        if (hit) {
          match = family;
          break;
        }
      }
      if (!mounted) return;
      setState(() => _possibleMatches[index] = match);
    });
  }

  void _updateDraft(
    FamilyRegistrationDraft Function(FamilyRegistrationDraft) update,
  ) {
    setState(() {
      _draft = update(_draft);
      _markDirty();
    });
  }

  void _addMember() {
    _resetDuplicateChecks();
    _updateDraft(
      (d) => d.copyWith(
        members: [
          ...d.members,
          FamilyMemberDraft(
            firstName: '',
            lastName: '',
            sex: 'male',
            dateOfBirth: '',
            isHeadOfFamily: d.members.isEmpty,
          ),
        ],
      ),
    );
  }

  void _removeMember(int index) {
    _resetDuplicateChecks();
    _updateDraft((d) {
      final members = [...d.members]..removeAt(index);
      return d.copyWith(members: members);
    });
  }

  void _updateMember(int index, FamilyMemberDraft member) {
    _updateDraft((d) {
      final members = [...d.members];
      members[index] = member;
      return d.copyWith(members: members);
    });
    _scheduleDuplicateCheck(index);
  }

  void _setHeadOfFamily(int index) {
    _updateDraft((d) {
      final members = [
        for (var i = 0; i < d.members.length; i++)
          d.members[i].copyWith(isHeadOfFamily: i == index),
      ];
      return d.copyWith(members: members);
    });
  }

  /// "Same as head of family" — copies whichever member is *currently*
  /// marked head (never assumed to be index 0, and re-resolved on
  /// every tap so it still works correctly after the head changes)
  /// onto [index]. Copies nothing and shows feedback instead of
  /// crashing when there's no head yet or the head has no number of
  /// its own to copy.
  void _copyHeadContactNumber(int index) {
    final l10n = AppLocalizations.of(context);
    final headNumber = _draft.headOfFamily?.contactNumber?.trim();
    if (headNumber == null || headNumber.isEmpty) {
      _showSnack(l10n.staffRegHeadContactMissing, isError: true);
      return;
    }
    _updateMember(
      index,
      _draft.members[index].copyWith(contactNumber: headNumber),
    );
  }

  /// Every member's contact number, required and PH-format-checked —
  /// a Flutter-only policy stricter than the backend's own (nullable,
  /// no format) rule, run before a registration can enter the pending
  /// queue or attempt online submission at all (see
  /// `contact_number_validator.dart`'s doc comment for why enforcing
  /// something stricter than the backend here is safe). Keyed exactly
  /// like backend 422 field errors (`members.$i.contact_number`) so
  /// it renders through the same `FamilyMemberCard` error-text path a
  /// real backend validation error would.
  Map<String, List<String>> _contactNumberErrors(AppLocalizations l10n) {
    final errors = <String, List<String>>{};
    for (var i = 0; i < _draft.members.length; i++) {
      final raw = _draft.members[i].contactNumber?.trim() ?? '';
      if (raw.isEmpty) {
        errors['members.$i.contact_number'] = [l10n.staffRegContactRequired];
      } else if (!isValidPhMobileNumber(raw)) {
        errors['members.$i.contact_number'] = [l10n.staffRegContactInvalid];
      }
    }
    return errors;
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _fieldErrors = const {};
    });

    if (!_draft.hasExactlyOneHead) {
      _showSnack(l10n.staffRegExactlyOneHeadError, isError: true);
      return;
    }

    // Blocks entry into the pending queue entirely — checked before
    // isSubmittable (a backend-alignment check) since this is a
    // stricter, Flutter-only requirement layered on top of it. Every
    // one of create/update/online-submit routes through this same
    // _submit(), so editing an existing pending registration is held
    // to the same rule.
    final contactErrors = _contactNumberErrors(l10n);
    if (contactErrors.isNotEmpty) {
      setState(() => _fieldErrors = contactErrors);
      _showSnack(l10n.staffRegValidationBanner, isError: true);
      return;
    }

    if (!_draft.isSubmittable) {
      _showSnack(l10n.staffRegValidationBanner, isError: true);
      return;
    }

    setState(() => _submitting = true);
    final isOnline = await ref.read(connectivityServiceProvider).hasConnection;
    final queueRepo = ref.read(pendingQueueRepositoryProvider);

    if (!isOnline) {
      if (widget.editingLocalId case final localId?) {
        await queueRepo.updateDraft(localId, _draft);
      } else {
        await queueRepo.enqueue(_draft);
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      _dirty = false;
      ref.invalidate(pendingQueueCountsProvider);
      ref.invalidate(pendingRegistrationsProvider);
      _showSnack(l10n.staffRegSavedOfflineMessage, isError: false);
      Navigator.of(context).maybePop();
      return;
    }

    final result = await ref.read(registrationSubmitProvider).submit(_draft);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Success():
        _dirty = false;
        if (widget.editingLocalId case final localId?) {
          await queueRepo.delete(localId);
        }
        if (!mounted) return;
        ref.invalidate(pendingQueueCountsProvider);
        ref.invalidate(pendingRegistrationsProvider);
        _showSnack(l10n.staffRegSuccessMessage, isError: false);
        Navigator.of(context).maybePop();
      case Failed(:final failure):
        if (failure is ValidationFailure) {
          setState(() => _fieldErrors = failure.fieldErrors);
          if (widget.editingLocalId case final localId?) {
            await queueRepo.updateDraft(localId, _draft);
            await queueRepo.markNeedsAttention(
              localId,
              category: PendingErrorCategory.validation,
              message: failure.message,
              fieldErrors: failure.fieldErrors,
            );
            ref.invalidate(pendingRegistrationDetailProvider(localId));
          }
          _showSnack(l10n.staffRegValidationBanner, isError: true);
        } else if (failure is AmbiguousWriteFailure) {
          // The POST may have already reached the server — queuing it
          // again here would risk a duplicate the backend can't
          // detect on its own (confirmed: no idempotency support).
          // Queue it as needsAttention instead of silently retrying.
          final localId = switch (widget.editingLocalId) {
            final id? => id,
            null => await queueRepo.enqueue(_draft),
          };
          if (widget.editingLocalId != null) {
            await queueRepo.updateDraft(localId, _draft);
          }
          await queueRepo.markNeedsAttention(
            localId,
            category: PendingErrorCategory.ambiguous,
            message: failure.message,
          );
          ref.invalidate(pendingQueueCountsProvider);
          ref.invalidate(pendingRegistrationsProvider);
          if (!mounted) return;
          _showSnack(l10n.staffRegAmbiguousMessage, isError: true);
          Navigator.of(context).maybePop();
        } else {
          _showSnack(failure.message, isError: true);
        }
    }
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

  List<String>? _errorsFor(String field) => _fieldErrors[field];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final barangaysAsync = ref.watch(barangaysProvider);
    final eventsAsync = ref.watch(evacuationEventsLookupProvider);
    final centersAsync = ref.watch(evacuationCentersLookupProvider);

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
                ? l10n.staffRegEditRegistrationTitle
                : l10n.staffRegisterFamilyTitle,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              barangaysAsync.when(
                data: (barangays) => _BarangayField(
                  barangays: barangays,
                  value: _draft.barangayId,
                  errors: _errorsFor('barangay_id'),
                  onChanged: (id) =>
                      _updateDraft((d) => d.copyWith(barangayId: id)),
                ),
                loading: () => const _LoadingField(),
                error: (error, stackTrace) =>
                    _LookupErrorField(message: l10n.staffRegLookupUnavailable),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _draft.homeAddress,
                decoration: InputDecoration(
                  labelText: l10n.staffRegFieldHomeAddress,
                  hintText: l10n.staffRegFieldHomeAddressHint,
                  border: const OutlineInputBorder(),
                  errorText: _errorsFor('home_address')?.join(' '),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) =>
                    _updateDraft((d) => d.copyWith(homeAddress: value)),
              ),
              const SizedBox(height: 12),
              eventsAsync.when(
                data: (events) => _EvacuationEventField(
                  events: events,
                  value: _draft.evacuationEventId,
                  errors: _errorsFor('evacuation_event_id'),
                  onChanged: (id) =>
                      _updateDraft((d) => d.copyWith(evacuationEventId: id)),
                ),
                loading: () => const _LoadingField(),
                error: (error, stackTrace) =>
                    _LookupErrorField(message: l10n.staffRegLookupUnavailable),
              ),
              const SizedBox(height: 12),
              _DisplacementTypeField(
                value: _draft.displacementType,
                errors: _errorsFor('displacement_type'),
                onChanged: (type) => _updateDraft(
                  (d) => d.copyWith(
                    displacementType: type,
                    clearEvacuationCenterId: type != 'inside_center',
                  ),
                ),
              ),
              if (_draft.displacementType == 'inside_center') ...[
                const SizedBox(height: 12),
                centersAsync.when(
                  data: (centers) => _EvacuationCenterField(
                    centers: centers,
                    barangayId: _draft.barangayId,
                    value: _draft.evacuationCenterId,
                    errors: _errorsFor('evacuation_center_id'),
                    onChanged: (id) =>
                        _updateDraft((d) => d.copyWith(evacuationCenterId: id)),
                  ),
                  loading: () => const _LoadingField(),
                  error: (error, stackTrace) => _LookupErrorField(
                    message: l10n.staffRegLookupUnavailable,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.staffReg4psBeneficiaryLabel),
                value: _draft.is4psBeneficiary,
                onChanged: (value) =>
                    _updateDraft((d) => d.copyWith(is4psBeneficiary: value)),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.staffRegMembersSectionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.staffRegAddMemberButton),
                  ),
                ],
              ),
              if (_fieldErrors['members'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  _fieldErrors['members']!.join(' '),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              for (var i = 0; i < _draft.members.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FamilyMemberCard(
                    index: i,
                    member: _draft.members[i],
                    fieldErrors: _fieldErrors,
                    onChanged: (member) => _updateMember(i, member),
                    onRemove: () => _removeMember(i),
                    onSetHead: () => _setHeadOfFamily(i),
                    onCopyFromHead: () => _copyHeadContactNumber(i),
                    possibleMatch: _possibleMatches[i],
                    onViewMatch: _possibleMatches[i] == null
                        ? null
                        : () => showRegisteredFamilyDetailSheet(
                            context,
                            _possibleMatches[i]!,
                          ),
                  ),
                ),
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
                    : Text(l10n.staffRegSubmitButton),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField();

  @override
  Widget build(BuildContext context) => const LinearProgressIndicator();
}

class _LookupErrorField extends StatelessWidget {
  const _LookupErrorField({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

/// The family's home barangay — deliberately never locked or filtered
/// to the signed-in staff member's own assigned barangay. All staff
/// roles (administrator, cswd_personnel, and barangay_official alike)
/// see every barangay from the real cached lookup data here.
///
/// Confirmed directly against the newest `FamilyController::store()`:
/// registration is intentionally *not* restricted by
/// `AuthorizesBarangayAccess` (that trait still gates `show()`/
/// `index()` — viewing/listing an *existing* family stays scoped to a
/// barangay official's own barangay, a deliberately separate rule
/// from who they may register). So a barangay official registering a
/// family whose home barangay differs from their own assignment is a
/// real, backend-supported case — not something Flutter is working
/// around.
class _BarangayField extends StatelessWidget {
  const _BarangayField({
    required this.barangays,
    required this.value,
    required this.errors,
    required this.onChanged,
  });

  final List<Barangay> barangays;
  final int? value;
  final List<String>? errors;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.staffRegFieldBarangay,
        border: const OutlineInputBorder(),
        errorText: errors?.join(' '),
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
      // Shown only in the closed field, separate from the open menu's
      // (up to 2-line) items above — this is what actually stops a
      // long name from pushing the dropdown arrow outside the field:
      // without `isExpanded: true` the selected `Text` lays out at its
      // own unconstrained intrinsic width inside the button's row, and
      // a name longer than the field simply overflows past it.
      selectedItemBuilder: (context) => [
        for (final barangay in barangays)
          Text(barangay.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      onChanged: onChanged,
    );
  }
}

class _EvacuationEventField extends StatelessWidget {
  const _EvacuationEventField({
    required this.events,
    required this.value,
    required this.errors,
    required this.onChanged,
  });

  final List<EvacuationEventLookup> events;
  final int? value;
  final List<String>? errors;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final openEvents = events.where((e) => e.isOpen).toList();
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.staffRegFieldEvacuationEvent,
        border: const OutlineInputBorder(),
        errorText: errors?.join(' '),
      ),
      items: [
        for (final event in openEvents)
          DropdownMenuItem(
            value: event.id,
            child: Text(
              event.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selectedItemBuilder: (context) => [
        for (final event in openEvents)
          Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      onChanged: onChanged,
    );
  }
}

class _DisplacementTypeField extends StatelessWidget {
  const _DisplacementTypeField({
    required this.value,
    required this.errors,
    required this.onChanged,
  });

  final String? value;
  final List<String>? errors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.staffRegFieldDisplacementType,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.staffRegDisplacementInsideCenter),
              selected: value == 'inside_center',
              onSelected: (_) => onChanged('inside_center'),
            ),
            ChoiceChip(
              label: Text(l10n.staffRegDisplacementOutsideCenter),
              selected: value == 'outside_center',
              onSelected: (_) => onChanged('outside_center'),
            ),
          ],
        ),
        if (errors != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errors!.join(' '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _EvacuationCenterField extends StatelessWidget {
  const _EvacuationCenterField({
    required this.centers,
    required this.barangayId,
    required this.value,
    required this.errors,
    required this.onChanged,
  });

  final List<EvacuationCenterLookup> centers;
  final int? barangayId;
  final int? value;
  final List<String>? errors;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.staffRegFieldEvacuationCenter,
        border: const OutlineInputBorder(),
        errorText: errors?.join(' '),
      ),
      items: [
        for (final center in centers)
          DropdownMenuItem(
            value: center.id,
            child: Text(
              center.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selectedItemBuilder: (context) => [
        for (final center in centers)
          Text(center.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      onChanged: onChanged,
    );
  }
}

/// Shared date formatting for the date-of-birth field, matching the
/// backend's `date_of_birth` format exactly (`Y-m-d` per
/// `EvacueeResource`/the validation rule).
String formatIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
