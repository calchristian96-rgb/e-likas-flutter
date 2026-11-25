import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../l10n/app_localizations.dart';
import '../../ec_board/domain/entities/age_bracket.dart';
import '../../ec_board/presentation/pages/add_evacuee_form_page.dart'
    show localizedAgeBracket;
import '../data/sent_family_api.dart';
import '../domain/sent_family.dart';
import 'sent_providers.dart';

/// The words for a failure here: the server's own message (a 422 says
/// what to fix), or that an internet connection is needed.
String sentFailureText(AppLocalizations l10n, Failure failure) =>
    failure is NeedsConnectionFailure
    ? l10n.sentEditNeedsConnection
    : failure.message;

/// Correct a sent registration on the server: the family as the server
/// has it now, its household answers and each person. Every save is one
/// request, online only; nothing is queued.
class SentFamilyPage extends ConsumerWidget {
  const SentFamilyPage({super.key, required this.familyId, this.personId});

  final int familyId;

  /// The person this phone added (EC Board), shown first and marked.
  final int? personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final familyAsync = ref.watch(sentFamilyProvider(familyId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sentFamilyTitle)),
      body: familyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: e is Failure
                  ? sentFailureText(l10n, e)
                  : l10n.sentCouldNotLoad,
              onRetry: () => ref.invalidate(sentFamilyProvider(familyId)),
            ),
          ),
        ),
        data: (family) {
          final members = [...family.members]
            ..sort((a, b) {
              if (a.id == personId) return -1;
              if (b.id == personId) return 1;
              if (a.id == family.headId) return -1;
              if (b.id == family.headId) return 1;
              return a.id.compareTo(b.id);
            });
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sentFamilyProvider(familyId)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pagePadding(context),
              children: [
                Text(family.title, style: theme.textTheme.headlineSmall),
                if (family.barangayName != null)
                  Text(
                    family.barangayName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(l10n.sentFamilyIntro, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                Text(
                  l10n.sentHouseholdSection,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    minTileHeight: 56,
                    title: Text(
                      l10n.sentHeadIs(
                        family.headName ??
                            family.name ??
                            l10n.sentHeadNotListed,
                      ),
                    ),
                    subtitle: Text(
                      '${l10n.ecBoardSingleHeadedQuestion} '
                      '${_answer(l10n, family.isSingleHeaded)}',
                    ),
                    trailing: TextButton(
                      onPressed: () => _open(
                        context,
                        ref,
                        HouseholdEditPage(family: family),
                      ),
                      child: Text(l10n.sentEdit),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.sentMembersSection,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final m in members)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      minTileHeight: 56,
                      title: Text(m.fullName ?? l10n.sentPersonNoName),
                      subtitle: Text(
                        [
                          if (m.id == family.headId)
                            l10n.staffRegHeadOfFamilyBadge,
                          if (m.id == personId) l10n.sentAddedFromPhone,
                          if (m.sex != null) _sex(l10n, m.sex!),
                          if (m.dateOfBirth != null)
                            m.dateOfBirth!
                          else if (AgeBracket.fromWire(m.ageBracket)
                              case final bracket?)
                            localizedAgeBracket(context, bracket),
                        ].join(' · '),
                      ),
                      trailing: TextButton(
                        onPressed: () => _open(
                          context,
                          ref,
                          MemberEditPage(familyId: family.id, member: m),
                        ),
                        child: Text(l10n.sentEdit),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Widget page) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => page));
    if (saved != true || !context.mounted) return;
    ref.invalidate(sentFamilyProvider(familyId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).sentSaved)),
    );
  }
}

String _answer(AppLocalizations l10n, bool? value) => switch (value) {
  true => l10n.ecBoardAnswerYes,
  false => l10n.ecBoardAnswerNo,
  null => l10n.ecBoardAnswerNotYetKnown,
};

String _sex(AppLocalizations l10n, String sex) =>
    sex == 'female' ? l10n.staffRegSexFemale : l10n.staffRegSexMale;

/// The server's refusal: its message, and the field errors no field on
/// the form shows.
class _ServerError extends StatelessWidget {
  const _ServerError({required this.message, this.otherErrors = const []});

  final String message;
  final List<String> otherErrors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.error,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: style),
          for (final e in otherErrors) Text(e, style: style),
        ],
      ),
    );
  }
}

/// One person (`PATCH /evacuees/{id}`), with the fields the server takes
/// (EvacueeController::update). Its 422 messages are shown under the
/// fields they are about.
class MemberEditPage extends ConsumerStatefulWidget {
  const MemberEditPage({
    super.key,
    required this.familyId,
    required this.member,
  });

  final int familyId;
  final SentMember member;

  @override
  ConsumerState<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends ConsumerState<MemberEditPage> {
  late final _first = TextEditingController(text: widget.member.firstName);
  late final _middle = TextEditingController(text: widget.member.middleName);
  late final _last = TextEditingController(text: widget.member.lastName);
  late final _suffix = TextEditingController(text: widget.member.suffix);
  late final _contact = TextEditingController(
    text: widget.member.contactNumber,
  );
  late final _pwdType = TextEditingController(text: widget.member.pwdType);
  late String? _sexValue = widget.member.sex;
  late String? _dob = widget.member.dateOfBirth;
  late String? _civil = widget.member.civilStatus;
  late bool _pwd = widget.member.isPwd;
  late bool _pregnant = widget.member.isPregnant;
  late bool _lactating = widget.member.isLactating;
  late bool _soloParent = widget.member.isSoloParent;
  late bool _indigenous = widget.member.isIndigenousPerson;
  late bool _fourPs = widget.member.is4psBeneficiary;
  late final AgeBracket? _ageBefore = AgeBracket.fromWire(
    widget.member.ageBracket,
  );
  late AgeBracket? _ageBracket = _ageBefore;

  /// A birthdate on the server decides the age group (backend 41b5e5d).
  bool get _ageSetByBirthdate => widget.member.dateOfBirth != null;

  bool _saving = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};

  static const _shownFields = {
    'first_name',
    'middle_name',
    'last_name',
    'suffix',
    'date_of_birth',
    'sex',
    'civil_status',
    'contact_number',
    'pwd_type',
    'age_bracket_override',
  };

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _suffix, _contact, _pwdType]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _fieldError(String key) => _fieldErrors[key]?.join(' ');

  static String? _textOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  /// What the server takes. A name, sex or birth date it already has is
  /// sent even when cleared, so the server says it cannot be blank.
  Map<String, dynamic> _body() {
    final m = widget.member;
    final first = _textOrNull(_first);
    final last = _textOrNull(_last);
    return {
      if (first != null || m.firstName != null) 'first_name': first,
      'middle_name': _textOrNull(_middle),
      if (last != null || m.lastName != null) 'last_name': last,
      'suffix': _textOrNull(_suffix),
      if (_dob != null || m.dateOfBirth != null) 'date_of_birth': _dob,
      if (_sexValue != null || m.sex != null) 'sex': _sexValue,
      'civil_status': _civil,
      'contact_number': _textOrNull(_contact),
      'is_pwd': _pwd,
      'pwd_type': _pwd ? _textOrNull(_pwdType) : null,
      'is_pregnant': _sexValue == 'male' ? false : _pregnant,
      'is_lactating': _sexValue == 'male' ? false : _lactating,
      'is_solo_parent': _soloParent,
      'is_indigenous_person': _indigenous,
      'is_4ps_beneficiary': _fourPs,
      // Only when changed, and only while no birthdate decides it.
      if (!_ageSetByBirthdate &&
          _ageBracket != null &&
          _ageBracket != _ageBefore)
        'age_bracket_override': _ageBracket!.wireValue,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
    });
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(sentFamilyApiProvider)
        .updateMember(widget.member.id, _body());
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Failed(:final failure):
        setState(() {
          _saving = false;
          _error = sentFailureText(l10n, failure);
          if (failure is ValidationFailure) {
            _fieldErrors = failure.fieldErrors;
          }
        });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dob ?? '') ?? DateTime(now.year - 30);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dob =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final others = [
      for (final e in _fieldErrors.entries)
        if (!_shownFields.contains(e.key)) ...e.value,
    ];
    InputDecoration deco(String label, String key) =>
        InputDecoration(labelText: label, errorText: _fieldError(key));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sentEditPerson)),
      body: ListView(
        padding: pagePadding(context),
        children: [
          if (_error != null)
            _ServerError(message: _error!, otherErrors: others),
          TextField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: deco(l10n.staffRegFieldFirstName, 'first_name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _middle,
            textCapitalization: TextCapitalization.words,
            decoration: deco(l10n.staffRegFieldMiddleName, 'middle_name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: deco(l10n.staffRegFieldLastName, 'last_name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _suffix,
            decoration: deco(l10n.staffRegFieldSuffix, 'suffix'),
          ),
          const SizedBox(height: 16),
          Text(l10n.staffRegFieldSex, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: [
              ButtonSegment(value: 'male', label: Text(l10n.staffRegSexMale)),
              ButtonSegment(
                value: 'female',
                label: Text(l10n.staffRegSexFemale),
              ),
            ],
            selected: {?_sexValue},
            onSelectionChanged: (s) =>
                setState(() => _sexValue = s.isEmpty ? null : s.first),
          ),
          if (_fieldError('sex') != null)
            _FieldError(text: _fieldError('sex')!),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: deco(l10n.staffRegFieldDateOfBirth, 'date_of_birth'),
            child: InkWell(
              onTap: _pickDob,
              child: Text(_dob ?? l10n.staffRegSelectDate),
            ),
          ),
          const SizedBox(height: 16),
          if (_ageSetByBirthdate)
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.ecBoardFieldAgeBracket,
                helperText: l10n.sentAgeSetByBirthdate,
                enabled: false,
              ),
              child: Text(
                _ageBefore == null
                    ? l10n.staffRegNotSpecified
                    : localizedAgeBracket(context, _ageBefore),
              ),
            )
          else
            DropdownButtonFormField<AgeBracket>(
              initialValue: _ageBracket,
              decoration: deco(
                l10n.ecBoardFieldAgeBracket,
                'age_bracket_override',
              ),
              items: [
                for (final b in AgeBracket.values)
                  DropdownMenuItem(
                    value: b,
                    child: Text(localizedAgeBracket(context, b)),
                  ),
              ],
              onChanged: (v) => setState(() => _ageBracket = v),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _civil,
            decoration: deco(l10n.staffRegFieldCivilStatus, 'civil_status'),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.staffRegNotSpecified),
              ),
              for (final (value, label) in [
                ('single', l10n.staffRegCivilStatusSingle),
                ('married', l10n.staffRegCivilStatusMarried),
                ('widowed', l10n.staffRegCivilStatusWidowed),
                ('separated', l10n.staffRegCivilStatusSeparated),
                ('divorced', l10n.staffRegCivilStatusDivorced),
              ])
                DropdownMenuItem(value: value, child: Text(label)),
            ],
            onChanged: (v) => setState(() => _civil = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contact,
            keyboardType: TextInputType.phone,
            decoration: deco(l10n.staffRegFieldContactNumber, 'contact_number'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.staffRegIsPwd),
            value: _pwd,
            onChanged: (v) => setState(() => _pwd = v),
          ),
          if (_pwd)
            TextField(
              controller: _pwdType,
              decoration: deco(l10n.staffRegFieldPwdType, 'pwd_type'),
            ),
          if (_sexValue != 'male') ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.staffRegIsPregnant),
              value: _pregnant,
              onChanged: (v) => setState(() => _pregnant = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.staffRegIsLactating),
              value: _lactating,
              onChanged: (v) => setState(() => _lactating = v),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.staffRegIsSoloParent),
            value: _soloParent,
            onChanged: (v) => setState(() => _soloParent = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.staffRegIsIndigenous),
            value: _indigenous,
            onChanged: (v) => setState(() => _indigenous = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.staffRegIs4psMember),
            value: _fourPs,
            onChanged: (v) => setState(() => _fourPs = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.registerSave),
          ),
        ],
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// The household answers (`PATCH /families/{id}/household`,
/// FamilyController::updateHousehold): who heads it, and whether it is
/// single-headed. A head who is not listed is allowed only while the
/// family has no head on file (the server refuses to leave it without
/// one); then the head's sex and whether they are a minor are asked.
class HouseholdEditPage extends ConsumerStatefulWidget {
  const HouseholdEditPage({super.key, required this.family});

  final SentFamily family;

  @override
  ConsumerState<HouseholdEditPage> createState() => _HouseholdEditPageState();
}

class _HouseholdEditPageState extends ConsumerState<HouseholdEditPage> {
  late int? _headId = widget.family.headId;
  late bool? _singleHeaded = widget.family.isSingleHeaded;
  late String? _headSex = widget.family.headSex;
  late bool? _headIsMinor = widget.family.headId == null
      ? widget.family.isChildHeaded
      : null;
  late final _name = TextEditingController(text: widget.family.name);
  bool _saving = false;
  String? _error;
  List<String> _errors = const [];
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The household's name, only when changed (backend 41b5e5d: trimmed,
  /// never blank, max 150; the server says so when it is).
  Map<String, dynamic> _body() {
    final name = _name.text.trim();
    return {
      'head_of_family_evacuee_id': _headId,
      'is_single_headed': _singleHeaded,
      if (_headId == null) 'head_sex': _headSex,
      if (_headId == null) 'head_is_minor': _headIsMinor,
      if (name != (widget.family.name ?? '').trim()) 'name': name,
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
      _errors = const [];
      _nameError = null;
    });
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(sentFamilyApiProvider)
        .updateHousehold(widget.family.id, _body());
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Failed(:final failure):
        setState(() {
          _saving = false;
          _error = sentFailureText(l10n, failure);
          if (failure is ValidationFailure) {
            final errors = failure.fieldErrors;
            _nameError = errors['name']?.join(' ');
            _errors = [
              for (final e in errors.entries)
                if (e.key != 'name') ...e.value,
            ];
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final family = widget.family;
    final canLeaveUnlisted = family.headId == null;
    Widget triState(bool? value, ValueChanged<bool?> onChanged) =>
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 1, label: Text(l10n.ecBoardAnswerYes)),
            ButtonSegment(value: 0, label: Text(l10n.ecBoardAnswerNo)),
            ButtonSegment(
              value: -1,
              label: Text(l10n.ecBoardAnswerNotYetKnown),
            ),
          ],
          selected: {
            switch (value) {
              true => 1,
              false => 0,
              null => -1,
            },
          },
          onSelectionChanged: (s) => onChanged(switch (s.first) {
            1 => true,
            0 => false,
            _ => null,
          }),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sentHouseholdSection)),
      body: ListView(
        padding: pagePadding(context),
        children: [
          if (_error != null)
            _ServerError(message: _error!, otherErrors: _errors),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: l10n.ecBoardNewHouseholdHeadName,
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: _headId,
            decoration: InputDecoration(labelText: l10n.sentHeadLabel),
            items: [
              if (canLeaveUnlisted)
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.sentHeadNotListed),
                ),
              for (final m in family.members)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(m.fullName ?? l10n.sentPersonNoName),
                ),
            ],
            onChanged: (v) => setState(() => _headId = v),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.ecBoardSingleHeadedQuestion,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          triState(_singleHeaded, (v) => setState(() => _singleHeaded = v)),
          if (_headId == null) ...[
            const SizedBox(height: 16),
            Text(l10n.ecBoardHeadSexLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: [
                ButtonSegment(value: 'male', label: Text(l10n.staffRegSexMale)),
                ButtonSegment(
                  value: 'female',
                  label: Text(l10n.staffRegSexFemale),
                ),
              ],
              selected: {?_headSex},
              onSelectionChanged: (s) =>
                  setState(() => _headSex = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ecBoardHeadIsMinorLabel,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            triState(_headIsMinor, (v) => setState(() => _headIsMinor = v)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.registerSave),
          ),
        ],
      ),
    );
  }
}
