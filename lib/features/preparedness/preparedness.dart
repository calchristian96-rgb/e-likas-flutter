import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_locale.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';

/// Text in English, Filipino and Bikol from the data file; English when
/// a language is missing.
class LocalText {
  const LocalText(this.values);

  final Map<String, String> values;

  factory LocalText.fromJson(Object? j) => LocalText({
    if (j is Map)
      for (final e in j.entries)
        if (e.value is String && e.key != 'id') '${e.key}': e.value as String,
  });

  String of(String languageCode) =>
      values[languageCode] ?? values['en'] ?? values.values.firstOrNull ?? '';
}

class PrepItem {
  const PrepItem({required this.id, required this.text});

  final String id;
  final LocalText text;
}

class PrepChecklist {
  const PrepChecklist({
    required this.id,
    required this.source,
    required this.title,
    required this.items,
    this.intro,
  });

  final String id;

  /// The agency whose public guidance the list follows: NDRRMC, DSWD,
  /// PHIVOLCS.
  final String source;
  final LocalText title;
  final LocalText? intro;
  final List<PrepItem> items;
}

class WhatToDo {
  const WhatToDo({
    required this.id,
    required this.source,
    required this.title,
    required this.steps,
  });

  final String id;
  final String source;
  final LocalText title;
  final List<LocalText> steps;
}

class Preparedness {
  const Preparedness({
    required this.checklists,
    required this.whatToDo,
    required this.reviewStatus,
  });

  /// `assets/data/preparedness.json`: the text lives in that file, so
  /// the team edits it without touching code.
  factory Preparedness.fromJson(Map<String, dynamic> j) => Preparedness(
    reviewStatus: LocalText.fromJson(j['review_status']),
    checklists: [
      for (final c in j['checklists'] as List? ?? const [])
        PrepChecklist(
          id: (c as Map<String, dynamic>)['id'] as String,
          source: c['source'] as String? ?? '',
          title: LocalText.fromJson(c['title']),
          intro: c['intro'] == null ? null : LocalText.fromJson(c['intro']),
          items: [
            for (final i in c['items'] as List? ?? const [])
              PrepItem(
                id: (i as Map<String, dynamic>)['id'] as String,
                text: LocalText.fromJson(i),
              ),
          ],
        ),
    ],
    whatToDo: [
      for (final w in j['what_to_do'] as List? ?? const [])
        WhatToDo(
          id: (w as Map<String, dynamic>)['id'] as String,
          source: w['source'] as String? ?? '',
          title: LocalText.fromJson(w['title']),
          steps: [
            for (final s in w['steps'] as List? ?? const [])
              LocalText.fromJson(s),
          ],
        ),
    ],
  );

  final List<PrepChecklist> checklists;
  final List<WhatToDo> whatToDo;
  final LocalText reviewStatus;
}

const preparednessAsset = 'assets/data/preparedness.json';

/// Bundled with the app: works offline from the first start.
final preparednessProvider = FutureProvider<Preparedness>((ref) async {
  final raw = await rootBundle.loadString(preparednessAsset);
  return Preparedness.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Ticked items ("listId:itemId"), kept on this phone only.
class PrepChecks extends Notifier<Set<String>> {
  static const _key = 'prep_checks_v1';

  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = {...state, ...?prefs.getStringList(_key)};
    } catch (_) {
      // Unticked for this run.
    }
  }

  Future<void> toggle(String key) async {
    state = state.contains(key) ? ({...state}..remove(key)) : {...state, key};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.toList()..sort());
    } catch (_) {
      // Kept in memory.
    }
  }
}

final prepChecksProvider = NotifierProvider<PrepChecks, Set<String>>(
  PrepChecks.new,
);

String _lang(WidgetRef ref, BuildContext context) =>
    ref.watch(appLocaleProvider).languageCode;

/// "Source: NDRRMC · for team review".
class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.prepSource(source),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// Be prepared: what to do in a typhoon, a flood and when Mayon is
/// restive; the go-bag and preparedness checklists; the family plan.
/// Everything here works offline.
class PreparePage extends ConsumerWidget {
  const PreparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = _lang(ref, context);
    final async = ref.watch(preparednessProvider);
    final checks = ref.watch(prepChecksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.prepUnavailable)),
        data: (p) => ListView(
          padding: pagePadding(context),
          children: [
            AppCard(
              onTap: () => context.push('/prepare/family-plan'),
              child: Row(
                children: [
                  Icon(
                    Icons.family_restroom,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.familyPlanTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          l10n.familyPlanPhoneOnly,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            SectionTitle(l10n.prepChecklists),
            for (final c in p.checklists)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  minTileHeight: 64,
                  leading: Icon(switch (c.id) {
                    'go_bag' => Icons.backpack_outlined,
                    'typhoon' => Icons.storm_outlined,
                    'volcano' => Icons.volcano_outlined,
                    _ => Icons.checklist,
                  }),
                  title: Text(c.title.of(lang)),
                  subtitle: Text(
                    '${l10n.prepProgress(c.items.where((i) => checks.contains('${c.id}:${i.id}')).length, c.items.length)} · ${l10n.prepSource(c.source)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChecklistPage(checklist: c),
                    ),
                  ),
                ),
              ),
            SectionTitle(l10n.hazardsWhatToDo),
            for (final w in p.whatToDo)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(w.title.of(lang)),
                  subtitle: _SourceLine(source: w.source),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in w.steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(
                              child: Text(
                                s.of(lang),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              p.reviewStatus.of(lang),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One checklist, ticks kept on this phone.
class ChecklistPage extends ConsumerWidget {
  const ChecklistPage({super.key, required this.checklist});

  final PrepChecklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = _lang(ref, context);
    final checks = ref.watch(prepChecksProvider);
    final done = checklist.items
        .where((i) => checks.contains('${checklist.id}:${i.id}'))
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(checklist.title.of(lang))),
      body: ListView(
        padding: pagePadding(context),
        children: [
          if (checklist.intro != null)
            Text(checklist.intro!.of(lang), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          _SourceLine(source: checklist.source),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: checklist.items.isEmpty ? 0 : done / checklist.items.length,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(l10n.prepProgress(done, checklist.items.length)),
          const SizedBox(height: 8),
          for (final i in checklist.items)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: checks.contains('${checklist.id}:${i.id}'),
              onChanged: (_) => ref
                  .read(prepChecksProvider.notifier)
                  .toggle('${checklist.id}:${i.id}'),
              title: Text(i.text.of(lang)),
            ),
        ],
      ),
    );
  }
}

/// The family emergency plan: where to meet, who to call, who needs
/// help. Kept in this phone's storage only and never sent to the server.
class FamilyPlan {
  const FamilyPlan({
    this.meetingPoint = '',
    this.contacts = const [],
    this.specialNeeds = const [],
  });

  factory FamilyPlan.fromJson(Map<String, dynamic> j) => FamilyPlan(
    meetingPoint: j['meeting_point'] as String? ?? '',
    contacts: [
      for (final c in j['contacts'] as List? ?? const [])
        (
          name: (c as Map)['name'] as String? ?? '',
          number: c['number'] as String? ?? '',
        ),
    ],
    specialNeeds: [
      for (final s in j['special_needs'] as List? ?? const [])
        (
          name: (s as Map)['name'] as String? ?? '',
          need: s['need'] as String? ?? '',
        ),
    ],
  );

  final String meetingPoint;
  final List<({String name, String number})> contacts;
  final List<({String name, String need})> specialNeeds;

  Map<String, dynamic> toJson() => {
    'meeting_point': meetingPoint,
    'contacts': [
      for (final c in contacts) {'name': c.name, 'number': c.number},
    ],
    'special_needs': [
      for (final s in specialNeeds) {'name': s.name, 'need': s.need},
    ],
  };
}

/// Local storage only (SharedPreferences): never an API call.
abstract final class FamilyPlanStore {
  static const key = 'family_plan_v1';

  static Future<FamilyPlan> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return const FamilyPlan();
      return FamilyPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FamilyPlan();
    }
  }

  static Future<void> save(FamilyPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(plan.toJson()));
  }
}

class FamilyPlanPage extends StatefulWidget {
  const FamilyPlanPage({super.key});

  @override
  State<FamilyPlanPage> createState() => _FamilyPlanPageState();
}

class _Row {
  _Row([String a = '', String b = ''])
    : first = TextEditingController(text: a),
      second = TextEditingController(text: b);

  final TextEditingController first;
  final TextEditingController second;

  void dispose() {
    first.dispose();
    second.dispose();
  }
}

class _FamilyPlanPageState extends State<FamilyPlanPage> {
  final _meeting = TextEditingController();
  final _contacts = <_Row>[];
  final _needs = <_Row>[];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    FamilyPlanStore.load().then((plan) {
      if (!mounted) return;
      setState(() {
        _meeting.text = plan.meetingPoint;
        _contacts.addAll([
          for (final c in plan.contacts) _Row(c.name, c.number),
        ]);
        _needs.addAll([
          for (final s in plan.specialNeeds) _Row(s.name, s.need),
        ]);
        if (_contacts.isEmpty) _contacts.add(_Row());
        if (_needs.isEmpty) _needs.add(_Row());
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _meeting.dispose();
    for (final r in [..._contacts, ..._needs]) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await FamilyPlanStore.save(
      FamilyPlan(
        meetingPoint: _meeting.text.trim(),
        contacts: [
          for (final r in _contacts)
            if (r.first.text.trim().isNotEmpty ||
                r.second.text.trim().isNotEmpty)
              (name: r.first.text.trim(), number: r.second.text.trim()),
        ],
        specialNeeds: [
          for (final r in _needs)
            if (r.first.text.trim().isNotEmpty ||
                r.second.text.trim().isNotEmpty)
              (name: r.first.text.trim(), need: r.second.text.trim()),
        ],
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.familyPlanSaved)));
  }

  Widget _rows(
    List<_Row> rows,
    String firstLabel,
    String secondLabel, {
    TextInputType? secondKeyboard,
  }) => Column(
    children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: r.first,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: firstLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: r.second,
                  keyboardType: secondKeyboard,
                  decoration: InputDecoration(
                    labelText: secondLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyPlanTitle)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: pagePadding(context),
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.familyPlanPhoneOnly,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _meeting,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    labelText: l10n.familyPlanMeetingPoint,
                    helperText: l10n.familyPlanMeetingPointHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SectionTitle(l10n.familyPlanContacts),
                _rows(
                  _contacts,
                  l10n.familyPlanName,
                  l10n.familyPlanNumber,
                  secondKeyboard: TextInputType.phone,
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _contacts.add(_Row())),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.familyPlanAddContact),
                ),
                SectionTitle(l10n.familyPlanSpecialNeeds),
                Text(
                  l10n.familyPlanSpecialNeedsHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _rows(_needs, l10n.familyPlanName, l10n.familyPlanNeed),
                TextButton.icon(
                  onPressed: () => setState(() => _needs.add(_Row())),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.familyPlanAddPerson),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _save,
                  child: Text(l10n.familyPlanSave),
                ),
              ],
            ),
    );
  }
}
