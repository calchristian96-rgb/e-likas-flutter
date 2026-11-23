import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// The three alert levels (apps-api-2026-11-22.md section 8): Emergency
/// (`severity: mandatory`, always SMS), Advisory, Info. `all_clear` keeps
/// its own word.
enum AlertLevel { emergency, advisory, info, allClear }

AlertLevel? alertLevelOf(String? severity) => switch (severity) {
  'mandatory' || 'emergency' => AlertLevel.emergency,
  'advisory' => AlertLevel.advisory,
  'info' => AlertLevel.info,
  'all_clear' => AlertLevel.allClear,
  _ => null,
};

/// "Emergency", "Advisory", "Info" with its colour.
class AlertLevelChip extends StatelessWidget {
  const AlertLevelChip({super.key, required this.severity});

  final String? severity;

  @override
  Widget build(BuildContext context) {
    final level = alertLevelOf(severity);
    if (level == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final (label, color) = switch (level) {
      AlertLevel.emergency => (
        l10n.alertLevelEmergency,
        theme.colorScheme.error,
      ),
      AlertLevel.advisory => (l10n.alertLevelAdvisory, semantic.warning),
      AlertLevel.info => (l10n.alertLevelInfo, theme.colorScheme.primary),
      AlertLevel.allClear => (l10n.alertLevelAllClear, semantic.success),
    };
    return _Pill(label: label, color: color);
  }
}

/// The "New" mark on an alert not opened on this phone yet.
class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) => _Pill(
    label: AppLocalizations.of(context).alertNew,
    color: Theme.of(context).colorScheme.primary,
    filled: true,
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: filled ? theme.colorScheme.onPrimary : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Alert ids already opened on this phone, per [scope] (`resident`,
/// `staff`), so a newer one carries "New". Kept in SharedPreferences;
/// the newest 200 ids only.
class SeenAlerts extends Notifier<Set<int>> {
  SeenAlerts(this.scope);

  final String scope;

  static String _key(String scope) => 'seen_alert_ids_$scope';

  @override
  Set<int> build() {
    _load(scope);
    return const {};
  }

  Future<void> _load(String scope) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key(scope)) ?? const [];
      state = {...state, for (final s in ids) ?int.tryParse(s)};
    } catch (_) {
      // Everything stays "New" for this run.
    }
  }

  Future<void> markSeen(Iterable<int> ids) async {
    final next = {...state, ...ids};
    if (next.length == state.length) return;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sorted = next.toList()..sort((a, b) => b.compareTo(a));
      await prefs.setStringList(_key(scope), [
        for (final id in sorted.take(200)) '$id',
      ]);
    } catch (_) {
      // Kept in memory.
    }
  }
}

final seenAlertsProvider =
    NotifierProvider.family<SeenAlerts, Set<int>, String>(SeenAlerts.new);
