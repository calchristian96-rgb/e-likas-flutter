import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/ui_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../outbox/presentation/outbox_providers.dart';
import '../../../puroks/puroks.dart';
import '../../../staff_auth/domain/entities/staff_session.dart';
import '../../../staff_auth/presentation/widgets/staff_auth_guard.dart';
import '../../../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import '../../../staff_shell/current_event.dart';
import '../../domain/entities/family_member_draft.dart';
import '../../domain/entities/family_registration_draft.dart';
import '../providers/pending_queue_provider.dart';

/// A Philippine mobile number, as the backend checks it.
final mobilePattern = RegExp(r'^(09|\+639)\d{9}$');

/// One member is complete enough to send (backend RegisterFamilyRequest).
bool memberComplete(FamilyMemberDraft m) =>
    m.firstName.trim().isNotEmpty &&
    m.lastName.trim().isNotEmpty &&
    (m.sex == 'male' || m.sex == 'female') &&
    m.dateOfBirth.isNotEmpty &&
    mobilePattern.hasMatch((m.contactNumber ?? '').trim()) &&
    (!m.isPwd || (m.pwdType ?? '').trim().isNotEmpty);

String _draftKey(int staffId) => 'elikas.registerDraft.$staffId';
String _centerKey(int staffId) => 'elikas.lastCenter.$staffId';

/// Register a family in four steps (Part 2.6): 1 Head of family,
/// 2 Members, 3 Purok and center, 4 Review, then Save. The barangay is
/// the official's own, the event the current one; the last center used
/// is remembered, the draft is kept on this phone until it is saved, and
/// Save queues the registration (sent at once when online, with its
/// client_ref, or by the next sync).
class RegisterFamilyPage extends StatelessWidget {
  const RegisterFamilyPage({super.key});

  @override
  Widget build(BuildContext context) => StaffAuthGuard(
    builder: (context, session) => _RegisterFlow(session: session),
  );
}

class _RegisterFlow extends ConsumerStatefulWidget {
  const _RegisterFlow({required this.session});

  final StaffSession session;

  @override
  ConsumerState<_RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends ConsumerState<_RegisterFlow> {
  int _step = 0;
  bool _saving = false;
  bool _loaded = false;
  late FamilyRegistrationDraft _draft = FamilyRegistrationDraft(
    evacuationEventId: null,
    barangayId: widget.session.barangayId,
    displacementType: 'inside_center',
    members: [_blankMember(head: true)],
  );

  static FamilyMemberDraft _blankMember({bool head = false, String? phone}) =>
      FamilyMemberDraft(
        firstName: '',
        lastName: '',
        sex: '',
        dateOfBirth: '',
        contactNumber: phone,
        isHeadOfFamily: head,
      );

  FamilyMemberDraft get _head => _draft.members.first;
  List<FamilyMemberDraft> get _others => _draft.members.skip(1).toList();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  /// The draft kept on this phone, and the last center used.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey(widget.session.id));
      final lastCenter = prefs.getInt(_centerKey(widget.session.id));
      if (raw != null) {
        final saved = FamilyRegistrationDraft.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (saved.members.isNotEmpty) _draft = saved;
      } else if (lastCenter != null) {
        _draft = _draft.copyWith(evacuationCenterId: lastCenter);
      }
    } catch (_) {
      // A broken draft is simply started again.
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _keepDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _draftKey(widget.session.id),
        jsonEncode(_draft.toJson()),
      );
    } catch (_) {}
  }

  void _update(FamilyRegistrationDraft next) {
    setState(() => _draft = next);
    _keepDraft();
  }

  void _setHead(FamilyMemberDraft head) {
    _update(_draft.copyWith(members: [head, ..._others]));
  }

  bool get _stepValid => switch (_step) {
    0 => memberComplete(_head),
    1 => _others.every(memberComplete),
    2 =>
      _draft.isPrivateHouse
          ? _draft.hasHost
          : _draft.evacuationCenterId != null,
    _ => true,
  };

  Future<void> _save(int eventId) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final draft = _draft.copyWith(
      evacuationEventId: eventId,
      barangayId: widget.session.barangayId,
      displacementType: _draft.displacementType ?? 'inside_center',
    );
    await ref.read(pendingQueueRepositoryProvider).enqueue(draft);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey(widget.session.id));
      if (!draft.isPrivateHouse && draft.evacuationCenterId != null) {
        await prefs.setInt(
          _centerKey(widget.session.id),
          draft.evacuationCenterId!,
        );
      }
    } catch (_) {}
    ref.invalidate(pendingRegistrationsProvider);
    ref.invalidate(pendingQueueCountsProvider);
    // Sent at once when online; otherwise by the next sync.
    ref.read(staffSyncAllProvider)();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.registerSaved(_head.firstName.trim()))),
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _discard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey(widget.session.id));
    } catch (_) {}
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref.watch(currentStaffEventProvider);
    final event = eventAsync.value;
    final titles = [
      l10n.registerStepHead,
      l10n.registerStepMembers,
      l10n.registerStepPlace,
      l10n.registerStepReview,
    ];
    final noEvent = eventAsync.hasValue && event == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerTitle),
        actions: [
          MoreButton(
            title: l10n.registerTitle,
            actions: [
              SheetAction(
                label: l10n.registerDiscardDraft,
                icon: Icons.delete_outline,
                destructive: true,
                onTap: _discard,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: noEvent || !_loaded
          ? null
          : BottomActionBar(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: Text(l10n.registerBack),
                  ),
                FilledButton(
                  onPressed: !_stepValid || _saving
                      ? null
                      : _step < 3
                      ? () => setState(() => _step++)
                      : event == null
                      ? null
                      : () => _save(event.id),
                  child: Text(
                    _step < 3 ? l10n.registerNext : l10n.registerSave,
                  ),
                ),
              ],
            ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : noEvent
          ? ListView(
              padding: pagePadding(context),
              children: [
                EmptyNote(
                  icon: Icons.event_busy_outlined,
                  message: l10n.staffNoOpenEvent,
                ),
              ],
            )
          : ListView(
              padding: pagePadding(context),
              children: [
                _StepHeader(step: _step, titles: titles),
                const SizedBox(height: 16),
                switch (_step) {
                  0 => _MemberForm(
                    key: const ValueKey('head'),
                    member: _head,
                    onChanged: _setHead,
                  ),
                  1 => _MembersStep(
                    members: _others,
                    head: _head,
                    onChanged: (list) =>
                        _update(_draft.copyWith(members: [_head, ...list])),
                  ),
                  2 => _PlaceStep(
                    session: widget.session,
                    draft: _draft,
                    onChanged: _update,
                  ),
                  _ => _ReviewStep(draft: _draft, eventName: event?.name),
                },
              ],
            ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.titles});

  final int step;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.registerStepOf(step + 1, titles.length),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(titles[step], style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < titles.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One person: names, sex and birthdate by picker, a mobile number on
/// the phone keypad, and the sectoral answers as switches.
class _MemberForm extends StatelessWidget {
  const _MemberForm({super.key, required this.member, required this.onChanged});

  final FamilyMemberDraft member;
  final ValueChanged<FamilyMemberDraft> onChanged;

  Future<void> _pickBirthdate(BuildContext context) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(member.dateOfBirth);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      onChanged(
        member.copyWith(dateOfBirth: DateFormat('yyyy-MM-dd').format(picked)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final female = member.sex == 'female';
    final phone = (member.contactNumber ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: member.firstName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.registerFirstName),
          onChanged: (v) => onChanged(member.copyWith(firstName: v)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: member.middleName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.registerMiddleName),
          onChanged: (v) => onChanged(
            v.trim().isEmpty
                ? member.copyWith(clearMiddleName: true)
                : member.copyWith(middleName: v),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: member.lastName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.registerLastName),
          onChanged: (v) => onChanged(member.copyWith(lastName: v)),
        ),
        const SizedBox(height: 16),
        Text(l10n.registerSex, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(value: 'female', label: Text(l10n.sexFemaleShort)),
            ButtonSegment(value: 'male', label: Text(l10n.sexMaleShort)),
          ],
          selected: {if (member.sex.isNotEmpty) member.sex},
          onSelectionChanged: (s) => onChanged(
            member.copyWith(
              sex: s.isEmpty ? '' : s.first,
              isPregnant: false,
              isLactating: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            alignment: Alignment.centerLeft,
          ),
          onPressed: () => _pickBirthdate(context),
          icon: const Icon(Icons.cake_outlined),
          label: Text(
            member.dateOfBirth.isEmpty
                ? l10n.registerBirthdate
                : l10n.registerBirthdateValue(member.dateOfBirth),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: member.contactNumber,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: InputDecoration(
            labelText: l10n.registerMobile,
            hintText: '09XXXXXXXXX',
            errorText: phone.isEmpty || mobilePattern.hasMatch(phone)
                ? null
                : l10n.registerMobileInvalid,
          ),
          onChanged: (v) => onChanged(member.copyWith(contactNumber: v)),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.registerPwd),
          value: member.isPwd,
          onChanged: (v) => onChanged(
            v
                ? member.copyWith(isPwd: true)
                : member.copyWith(isPwd: false, clearPwdType: true),
          ),
        ),
        if (member.isPwd)
          TextFormField(
            initialValue: member.pwdType,
            decoration: InputDecoration(labelText: l10n.registerPwdType),
            onChanged: (v) => onChanged(member.copyWith(pwdType: v)),
          ),
        if (female) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.returningMemberStillPregnant),
            value: member.isPregnant,
            onChanged: (v) => onChanged(member.copyWith(isPregnant: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.returningMemberStillLactating),
            value: member.isLactating,
            onChanged: (v) => onChanged(member.copyWith(isLactating: v)),
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.registerSoloParent),
          value: member.isSoloParent,
          onChanged: (v) => onChanged(member.copyWith(isSoloParent: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.registerIndigenous),
          value: member.isIndigenousPerson,
          onChanged: (v) => onChanged(member.copyWith(isIndigenousPerson: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.register4ps),
          value: member.is4psBeneficiary,
          onChanged: (v) => onChanged(member.copyWith(is4psBeneficiary: v)),
        ),
      ],
    );
  }
}

String _memberName(FamilyMemberDraft m) => [
  m.firstName.trim(),
  if ((m.middleName ?? '').trim().isNotEmpty) m.middleName!.trim(),
  m.lastName.trim(),
].where((s) => s.isNotEmpty).join(' ');

class _MembersStep extends StatelessWidget {
  const _MembersStep({
    required this.members,
    required this.head,
    required this.onChanged,
  });

  final List<FamilyMemberDraft> members;
  final FamilyMemberDraft head;
  final ValueChanged<List<FamilyMemberDraft>> onChanged;

  Future<void> _edit(BuildContext context, int? index) async {
    final l10n = AppLocalizations.of(context);
    var working = index == null
        ? _RegisterFlowState._blankMember(phone: head.contactNumber)
        : members[index];
    final saved = await showModalBottomSheet<FamilyMemberDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    index == null
                        ? l10n.registerAddMember
                        : l10n.registerEditMember,
                    style: Theme.of(sheet).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _MemberForm(
                    member: working,
                    onChanged: (m) => setSheet(() => working = m),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: memberComplete(working)
                        ? () => Navigator.of(sheet).pop(working)
                        : null,
                    child: Text(l10n.registerSaveMember),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (saved == null) return;
    final next = [...members];
    if (index == null) {
      next.add(saved);
    } else {
      next[index] = saved;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.registerMembersHint),
        const SizedBox(height: 16),
        for (var i = 0; i < members.length; i++) ...[
          AppCard(
            onTap: () => _edit(context, i),
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _memberName(members[i]),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(members[i].dateOfBirth),
                    ],
                  ),
                ),
                MoreButton(
                  title: _memberName(members[i]),
                  actions: [
                    SheetAction(
                      label: l10n.registerEditMember,
                      icon: Icons.edit_outlined,
                      onTap: () => _edit(context, i),
                    ),
                    SheetAction(
                      label: l10n.registerRemoveMember,
                      icon: Icons.delete_outline,
                      destructive: true,
                      onTap: () => onChanged([...members]..removeAt(i)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => _edit(context, null),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(l10n.registerAddMember),
        ),
      ],
    );
  }
}

class _PlaceStep extends ConsumerWidget {
  const _PlaceStep({
    required this.session,
    required this.draft,
    required this.onChanged,
  });

  final StaffSession session;
  final FamilyRegistrationDraft draft;
  final ValueChanged<FamilyRegistrationDraft> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final centers = [
      for (final c
          in ref.watch(ownCentersProvider).value ?? const <OwnCenter>[])
        if (c.center.isUsable) c,
    ];
    final puroks = session.barangayId == null
        ? const <Purok>[]
        : ref.watch(puroksForBarangayProvider(session.barangayId!)).value ??
              const <Purok>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The barangay is the official's own: shown, never typed.
        Text(l10n.registerBarangay, style: theme.textTheme.titleSmall),
        Text(session.barangayName ?? '', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (puroks.isNotEmpty) ...[
          DropdownButtonFormField<int?>(
            initialValue: puroks.any((p) => p.id == draft.purokId)
                ? draft.purokId
                : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.purokOptionalLabel),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l10n.purokNone)),
              for (final p in puroks)
                DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
            ],
            onChanged: (id) => onChanged(draft.copyWith(purokId: (value: id))),
          ),
          const SizedBox(height: 16),
        ],
        Text(l10n.registerWhereStaying, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.home_work_outlined),
              label: Text(l10n.registerInCenter),
            ),
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.house_outlined),
              label: Text(l10n.registerPrivateHouse),
            ),
          ],
          selected: {draft.isPrivateHouse},
          onSelectionChanged: (s) => onChanged(
            draft.copyWith(
              displacementType: s.first ? 'outside_center' : 'inside_center',
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (draft.isPrivateHouse) ...[
          Text(
            l10n.registerPrivateHouseHint,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: draft.hostName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.registerHostName),
            onChanged: (v) => onChanged(draft.copyWith(hostName: v)),
          ),
          const SizedBox(height: 16),
          if (puroks.isNotEmpty) ...[
            DropdownButtonFormField<int?>(
              initialValue: puroks.any((p) => p.id == draft.hostPurokId)
                  ? draft.hostPurokId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.registerHostPurok),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.purokNone),
                ),
                for (final p in puroks)
                  DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
              ],
              onChanged: (id) =>
                  onChanged(draft.copyWith(hostPurokId: (value: id))),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            initialValue: draft.hostAddress,
            decoration: InputDecoration(
              labelText: l10n.registerHostAddress,
              helperText: l10n.registerHostWhere,
              helperMaxLines: 2,
            ),
            onChanged: (v) => onChanged(draft.copyWith(hostAddress: v)),
          ),
        ] else if (centers.isEmpty)
          EmptyNote(message: l10n.staffOwnCentersEmpty)
        else
          RadioGroup<int>(
            groupValue: draft.evacuationCenterId,
            onChanged: (id) =>
                onChanged(draft.copyWith(evacuationCenterId: id)),
            child: Column(
              children: [
                for (final c in centers)
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    value: c.id,
                    title: Text(c.name),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: draft.homeAddress,
          decoration: InputDecoration(labelText: l10n.registerHomeAddress),
          onChanged: (v) => onChanged(draft.copyWith(homeAddress: v)),
        ),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.draft, required this.eventName});

  final FamilyRegistrationDraft draft;
  final String? eventName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final center = (ref.watch(ownCentersProvider).value ?? const <OwnCenter>[])
        .where((c) => c.id == draft.evacuationCenterId)
        .firstOrNull;
    final head = draft.members.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.registerStepHead, style: theme.textTheme.bodyMedium),
              Text(_memberName(head), style: theme.textTheme.titleMedium),
              Text(head.contactNumber ?? ''),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.registerStepMembers, style: theme.textTheme.bodyMedium),
              Text(
                l10n.ecBoardFamilyMembers(draft.members.length),
                style: theme.textTheme.titleMedium,
              ),
              for (final m in draft.members.skip(1)) Text(_memberName(m)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.registerStepPlace, style: theme.textTheme.bodyMedium),
              Text(
                draft.isPrivateHouse
                    ? l10n.privateHouseWith((draft.hostName ?? '').trim())
                    : center?.name ?? '',
                style: theme.textTheme.titleMedium,
              ),
              if (draft.isPrivateHouse &&
                  (draft.hostAddress ?? '').trim().isNotEmpty)
                Text(draft.hostAddress!.trim()),
              if (eventName != null) Text(eventName!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.registerSaveNote, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
