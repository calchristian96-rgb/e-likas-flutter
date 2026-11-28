import 'package:flutter/material.dart';

import '../../../../app/theme/sheet_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Section title row used above each Home dashboard block, with an
/// optional "View all" action aligned to the trailing edge.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    // The margin head: a map-label over a 1.5 px ink rule.
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.rule, width: Sheet.rule)),
      ),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              semanticsLabel: title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SheetText.label(p.ink, size: 15),
            ),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(44, 36),
            ),
            child: Text(AppLocalizations.of(context).viewAll.toUpperCase()),
          ),
      ],
      ),
    );
  }
}
