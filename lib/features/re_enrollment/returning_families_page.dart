import '../../core/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/error_state.dart';
import '../../core/widgets/search_field.dart';
import '../../l10n/app_localizations.dart';
import '../ec_board/domain/entities/age_bracket.dart';
import '../ec_board/presentation/pages/add_evacuee_form_page.dart'
    show localizedAgeBracket;
import 're_enrollment_api.dart';

/// Returning families (backend step 10): a family from a past event is
/// entered into this event by ticking who arrived, instead of typing
/// everyone again. Online only. Returns true when someone was added.
class ReturningFamiliesPage extends ConsumerStatefulWidget {
  const ReturningFamiliesPage({
    super.key,
    required this.centerId,
    required this.eventId,
  });

  final int centerId;
  final int eventId;

  @override
  ConsumerState<ReturningFamiliesPage> createState() =>
      _ReturningFamiliesPageState();
}

class _ReturningFamiliesPageState extends ConsumerState<ReturningFamiliesPage> {
  final _search = TextEditingController();
  int? _sourceEventId;
  Future<ReturningFamiliesResult>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = ref
          .read(reEnrollmentApiProvider)
          .list(
            centerId: widget.centerId,
            eventId: widget.eventId,
            sourceEventId: _sourceEventId,
            search: _search.text,
          );
    });
  }

  Future<void> _open(ReturningFamily family) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ReEnrollFamilyPage(
          centerId: widget.centerId,
          eventId: widget.eventId,
          family: family,
        ),
      ),
    );
    if (added == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.returningFamiliesTitle)),
      body: FutureBuilder<ReturningFamiliesResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: ErrorState(
                message: l10n.returningFamiliesNeedsConnection,
                onRetry: _load,
              ),
            );
          }
          final page = snapshot.data;
          if (page == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (page.pastEvents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.returningFamiliesNoPastEvents,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: pagePadding(context),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _sourceEventId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.returningFamiliesPastEvent,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final e in page.pastEvents)
                    DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        '${e.name} (${e.familyCount})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  _sourceEventId = id;
                  _load();
                },
              ),
              if (_sourceEventId != null) ...[
                const SizedBox(height: 16),
                SearchField(
                  controller: _search,
                  hintText: l10n.returningFamiliesSearchHint,
                  clearTooltip: l10n.clearSearch,
                  onChanged: (_) {},
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 16),
                if (page.families.isEmpty)
                  Text(l10n.returningFamiliesNone)
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < page.families.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            minTileHeight: 56,
                            title: Text(page.families[i].name),
                            subtitle: Text(
                              page.families[i].reEnrolledFamilyId != null
                                  ? l10n.returningFamilyAlreadyIn
                                  : [
                                      ?page.families[i].purokName,
                                      ?page.families[i].lastCenterName,
                                    ].join(' · '),
                              style: page.families[i].reEnrolledFamilyId != null
                                  ? theme.textTheme.bodySmall
                                  : null,
                            ),
                            enabled:
                                page.families[i].reEnrolledFamilyId == null,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(page.families[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Answers {
  bool ticked = true;
  AgeBracket? ageBracket;
  bool pregnant = false;
  bool lactating = false;
}

class _ReEnrollFamilyPage extends ConsumerStatefulWidget {
  const _ReEnrollFamilyPage({
    required this.centerId,
    required this.eventId,
    required this.family,
  });

  final int centerId;
  final int eventId;
  final ReturningFamily family;

  @override
  ConsumerState<_ReEnrollFamilyPage> createState() =>
      _ReEnrollFamilyPageState();
}

class _ReEnrollFamilyPageState extends ConsumerState<_ReEnrollFamilyPage> {
  late final Map<int, _Answers> _answers = {
    for (final m in widget.family.members)
      m.id: _Answers()..ticked = !m.checkedIn,
  };
  bool _sending = false;
  String? _error;

  /// One client_ref for this family's re-enrolment, kept across the 409
  /// "same family?" resend and a retry (docs/client-ref-api.md).
  final String _clientRef = const Uuid().v4();

  List<ReturningMember> get _ticked => [
    for (final m in widget.family.members)
      if (!m.checkedIn && _answers[m.id]!.ticked) m,
  ];

  bool get _complete =>
      _ticked.isNotEmpty &&
      _ticked.every(
        (m) => !m.needsAgeBracket || _answers[m.id]!.ageBracket != null,
      );

  Future<void> _submit({String? decision, int? linkFamilyId}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    final outcome = await ref
        .read(reEnrollmentApiProvider)
        .reEnroll(
          centerId: widget.centerId,
          eventId: widget.eventId,
          sourceFamilyId: widget.family.id,
          duplicateDecision: decision,
          linkFamilyId: linkFamilyId,
          clientRef: _clientRef,
          members: [
            for (final m in _ticked)
              ReEnrollMember(
                evacueeId: m.id,
                ageBracket: m.needsAgeBracket
                    ? _answers[m.id]!.ageBracket!.wireValue
                    : null,
                isPregnant: m.isFemale ? _answers[m.id]!.pregnant : null,
                isLactating: m.isFemale ? _answers[m.id]!.lactating : null,
              ),
          ],
        );
    if (!mounted) return;
    setState(() => _sending = false);
    switch (outcome) {
      case ReEnrolled(:final membersAdded, :final membersLinked):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.returningFamilyDone(membersAdded + membersLinked),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      case NeedsDuplicateDecision(:final candidates):
        final choice = await _askSameFamily(candidates);
        if (choice == null) return;
        await _submit(
          decision: choice == 0 ? 'different' : 'link',
          linkFamilyId: choice == 0 ? null : choice,
        );
      case ReEnrollRefused(:final message):
        setState(() => _error = message);
    }
  }

  /// 0 = a different family; otherwise the id of the family to link.
  Future<int?> _askSameFamily(List<PossibleDuplicate> candidates) {
    final l10n = AppLocalizations.of(context);
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.returningFamilyDuplicateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.returningFamilyDuplicateBody),
            const SizedBox(height: 16),
            for (final c in candidates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(c.familyId),
                  child: Text(
                    l10n.returningFamilyLinkTo(
                      c.name,
                      c.centerName ?? '',
                      l10n.ecBoardFamilyMembers(c.memberCount),
                    ),
                    textAlign: TextAlign.center,
                  ),
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
            onPressed: () => Navigator.of(context).pop(0),
            child: Text(l10n.returningFamilyDifferent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final family = widget.family;
    return Scaffold(
      appBar: AppBar(title: Text(family.name)),
      body: ListView(
        padding: pagePadding(context),
        children: [
          Text(
            l10n.returningFamilyWhoArrived,
            style: theme.textTheme.titleMedium,
          ),
          if (family.unnamedMemberCount > 0)
            Text(
              l10n.returningFamilyUnnamed(family.unnamedMemberCount),
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 8),
          for (final m in family.members) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: !m.checkedIn && _answers[m.id]!.ticked,
              onChanged: m.checkedIn
                  ? null
                  : (v) => setState(() => _answers[m.id]!.ticked = v ?? false),
              title: Text(m.fullName),
              subtitle: Text(
                m.checkedIn
                    ? l10n.returningMemberCheckedIn
                    : [
                        if (m.age != null) l10n.returningMemberAge(m.age!),
                        if (AgeBracket.fromWire(m.ageBracket ?? '')
                            case final bracket?)
                          localizedAgeBracket(context, bracket),
                      ].join(' · '),
              ),
            ),
            if (!m.checkedIn && _answers[m.id]!.ticked) ...[
              if (m.needsAgeBracket)
                Padding(
                  padding: const EdgeInsets.only(left: 48, bottom: 8),
                  child: DropdownButtonFormField<AgeBracket>(
                    initialValue: _answers[m.id]!.ageBracket,
                    decoration: InputDecoration(
                      labelText: l10n.returningMemberAgeGroup,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final b in AgeBracket.values)
                        DropdownMenuItem(
                          value: b,
                          child: Text(localizedAgeBracket(context, b)),
                        ),
                    ],
                    onChanged: (b) =>
                        setState(() => _answers[m.id]!.ageBracket = b),
                  ),
                ),
              if (m.isFemale && (m.wasPregnant || m.wasLactating))
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    children: [
                      if (m.wasPregnant)
                        CheckboxListTile(
                          dense: false,
                          value: _answers[m.id]!.pregnant,
                          onChanged: (v) => setState(
                            () => _answers[m.id]!.pregnant = v ?? false,
                          ),
                          title: Text(l10n.returningMemberStillPregnant),
                        ),
                      if (m.wasLactating)
                        CheckboxListTile(
                          value: _answers[m.id]!.lactating,
                          onChanged: (v) => setState(
                            () => _answers[m.id]!.lactating = v ?? false,
                          ),
                          title: Text(l10n.returningMemberStillLactating),
                        ),
                    ],
                  ),
                ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _complete && !_sending ? () => _submit() : null,
            child: Text(l10n.returningFamilyEnroll(_ticked.length)),
          ),
        ],
      ),
    );
  }
}
