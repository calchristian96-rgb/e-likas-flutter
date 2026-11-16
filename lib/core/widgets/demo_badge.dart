import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// The clear mark the backend asks for wherever a demo event appears
/// (`is_demo`, map-api.md): made-up data for demonstrations. [drill]
/// is the resident-facing word for the same thing.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.drill = false});

  final bool drill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.extension<AppSemanticColors>()!.warning;
    return Semantics(
      label: drill ? l10n.drillBadge : l10n.demoBadge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Text(
          drill ? l10n.drillBadge : l10n.demoBadge,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
