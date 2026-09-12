import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../registered_families/domain/entities/registered_family.dart';
import '../../domain/entities/family_member_draft.dart';
import '../pages/family_registration_form_page.dart' show formatIsoDate;

/// One dynamic member card on the registration form. Every field maps
/// 1:1 to a `members.*` rule in `RegisterFamilyRequest` — nothing
/// here is a field the backend doesn't accept. Root layout is a
/// `Column` of full-width fields plus a `Wrap` for the boolean
/// sectoral flags, so nothing here has a fixed height that could
/// overflow at a larger text scale or on a narrow phone.
class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.index,
    required this.member,
    required this.fieldErrors,
    required this.onChanged,
    required this.onRemove,
    required this.onSetHead,
    required this.onCopyFromHead,
    this.possibleMatch,
    this.onViewMatch,
  });

  final int index;
  final FamilyMemberDraft member;
  final Map<String, List<String>> fieldErrors;
  final ValueChanged<FamilyMemberDraft> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onSetHead;

  /// "Same as head of family" — only ever shown for non-head members
  /// (see `build()`). Locating the actual current head, validating it
  /// has a number to copy, and doing the copy all happen one level up
  /// in the form's own state (it needs every member, not just this
  /// one) — this card only triggers it.
  final VoidCallback onCopyFromHead;

  /// A locally-cached registered family whose member list might
  /// already include this in-progress entry (Phase 3 duplicate
  /// checking — debounced and matched one level up in the form's own
  /// state, since that's where the local cache snapshot lives). Null
  /// means no match, or none checked yet.
  final RegisteredFamily? possibleMatch;

  /// Opens a read-only look at [possibleMatch]. Only ever non-null
  /// when [possibleMatch] itself is non-null.
  final VoidCallback? onViewMatch;

  String? _errorText(String field) =>
      fieldErrors['members.$index.$field']?.join(' ');

  Future<void> _pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(member.dateOfBirth) ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      onChanged(member.copyWith(dateOfBirth: formatIsoDate(picked)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.staffRegMemberCardTitle(index + 1),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (member.isHeadOfFamily)
                  Chip(
                    label: Text(l10n.staffRegHeadOfFamilyBadge),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  TextButton(
                    onPressed: onSetHead,
                    child: Text(l10n.staffRegSetAsHead),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.staffRegRemoveMember,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: member.firstName,
              decoration: InputDecoration(
                labelText: l10n.staffRegFieldFirstName,
                border: const OutlineInputBorder(),
                errorText: _errorText('first_name'),
              ),
              onChanged: (value) =>
                  onChanged(member.copyWith(firstName: value)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: member.middleName,
              decoration: InputDecoration(
                labelText: l10n.staffRegFieldMiddleName,
                border: const OutlineInputBorder(),
                errorText: _errorText('middle_name'),
              ),
              onChanged: (value) =>
                  onChanged(member.copyWith(middleName: value)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: member.lastName,
              decoration: InputDecoration(
                labelText: l10n.staffRegFieldLastName,
                border: const OutlineInputBorder(),
                errorText: _errorText('last_name'),
              ),
              onChanged: (value) => onChanged(member.copyWith(lastName: value)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: member.suffix,
              decoration: InputDecoration(
                labelText: l10n.staffRegFieldSuffix,
                border: const OutlineInputBorder(),
                errorText: _errorText('suffix'),
              ),
              onChanged: (value) => onChanged(member.copyWith(suffix: value)),
            ),
            if (possibleMatch != null) ...[
              const SizedBox(height: 8),
              _PossibleDuplicateWarning(
                match: possibleMatch!,
                onViewMatch: onViewMatch,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: member.sex,
                    decoration: InputDecoration(
                      labelText: l10n.staffRegFieldSex,
                      border: const OutlineInputBorder(),
                      errorText: _errorText('sex'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(l10n.staffRegSexMale),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(l10n.staffRegSexFemale),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onChanged(member.copyWith(sex: value));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDateOfBirth(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.staffRegFieldDateOfBirth,
                  border: const OutlineInputBorder(),
                  errorText: _errorText('date_of_birth'),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  member.dateOfBirth.isEmpty
                      ? l10n.staffRegSelectDate
                      : member.dateOfBirth,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: member.civilStatus,
              decoration: InputDecoration(
                labelText: l10n.staffRegFieldCivilStatus,
                border: const OutlineInputBorder(),
                errorText: _errorText('civil_status'),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.staffRegNotSpecified),
                ),
                DropdownMenuItem(
                  value: 'single',
                  child: Text(l10n.staffRegCivilStatusSingle),
                ),
                DropdownMenuItem(
                  value: 'married',
                  child: Text(l10n.staffRegCivilStatusMarried),
                ),
                DropdownMenuItem(
                  value: 'widowed',
                  child: Text(l10n.staffRegCivilStatusWidowed),
                ),
                DropdownMenuItem(
                  value: 'separated',
                  child: Text(l10n.staffRegCivilStatusSeparated),
                ),
                DropdownMenuItem(
                  value: 'divorced',
                  child: Text(l10n.staffRegCivilStatusDivorced),
                ),
              ],
              onChanged: (value) => onChanged(
                member.copyWith(
                  civilStatus: value,
                  clearCivilStatus: value == null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: member.contactNumber,
              // TextInputType.phone rather than a digits-only
              // formatter: a valid number here can start with "+"
              // (+639XXXXXXXXX), which a digits-only input formatter
              // would make impossible to type. Nothing here
              // reformats/strips what's typed — validation (in the
              // parent form, keyed members.$index.contact_number)
              // either accepts it as-is or rejects it, never silently
              // rewrites it into a different number.
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.staffRegFieldContactNumber,
                border: const OutlineInputBorder(),
                errorText: _errorText('contact_number'),
              ),
              onChanged: (value) =>
                  onChanged(member.copyWith(contactNumber: value)),
            ),
            if (!member.isHeadOfFamily) ...[
              const SizedBox(height: 4),
              // Align + TextButton rather than a Row: this button's
              // width is content-driven, so it can never force an
              // overflow next to the field above regardless of locale
              // wording length or text-scale setting.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onCopyFromHead,
                  icon: const Icon(Icons.content_copy_outlined, size: 16),
                  label: Text(l10n.staffRegSameAsHead),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: Text(l10n.staffRegIsPwd),
                  selected: member.isPwd,
                  onSelected: (value) => onChanged(
                    member.copyWith(isPwd: value, clearPwdType: !value),
                  ),
                ),
                FilterChip(
                  label: Text(l10n.staffRegIsPregnant),
                  selected: member.isPregnant,
                  onSelected: (value) =>
                      onChanged(member.copyWith(isPregnant: value)),
                ),
                FilterChip(
                  label: Text(l10n.staffRegIsLactating),
                  selected: member.isLactating,
                  onSelected: (value) =>
                      onChanged(member.copyWith(isLactating: value)),
                ),
                FilterChip(
                  label: Text(l10n.staffRegIsSoloParent),
                  selected: member.isSoloParent,
                  onSelected: (value) =>
                      onChanged(member.copyWith(isSoloParent: value)),
                ),
                FilterChip(
                  label: Text(l10n.staffRegIsIndigenous),
                  selected: member.isIndigenousPerson,
                  onSelected: (value) =>
                      onChanged(member.copyWith(isIndigenousPerson: value)),
                ),
                FilterChip(
                  label: Text(l10n.staffRegIs4psMember),
                  selected: member.is4psBeneficiary,
                  onSelected: (value) =>
                      onChanged(member.copyWith(is4psBeneficiary: value)),
                ),
              ],
            ),
            if (member.isPwd) ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: member.pwdType,
                decoration: InputDecoration(
                  labelText: l10n.staffRegFieldPwdType,
                  border: const OutlineInputBorder(),
                  errorText: _errorText('pwd_type'),
                ),
                onChanged: (value) =>
                    onChanged(member.copyWith(pwdType: value)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Possible existing match" — informational only, never blocking
/// (see `duplicate_name_matcher.dart`'s doc comment for the matching
/// rules). Uses the app's `warning` semantic color rather than
/// `colorScheme.error`: two people can legitimately share a name, so
/// this is a nudge to double-check, not a validation failure.
class _PossibleDuplicateWarning extends StatelessWidget {
  const _PossibleDuplicateWarning({required this.match, this.onViewMatch});

  final RegisteredFamily match;
  final VoidCallback? onViewMatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning = theme.extension<AppSemanticColors>()!.warning;
    final matchName = match.headOfFamilyName.isEmpty
        ? l10n.staffFamiliesUnnamedFamily
        : match.headOfFamilyName;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.staffRegPossibleDuplicateTitle,
                  style: theme.textTheme.labelLarge?.copyWith(color: warning),
                ),
                const SizedBox(height: 2),
                Text(matchName, style: theme.textTheme.bodyMedium),
                Text(
                  l10n.staffFamiliesRegisteredIn(match.barangayName),
                  style: theme.textTheme.bodySmall,
                ),
                if (onViewMatch != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onViewMatch,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                      ),
                      child: Text(l10n.staffRegViewRecord),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
