import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'section_header.dart';

/// A small, static list of preparedness tips. Deliberately no API or
/// data source — the requirement is explicit that this stays local.
///
/// The tip *content* itself is intentionally left in English in every
/// language, unlike [title] — these are substantive safety
/// instructions (one of them literally is "Follow instructions from
/// local authorities," a phrase the Bikol (Ligao) task explicitly
/// calls out as needing local review before translation), so
/// mistranslating them carries real risk in a way a section heading
/// doesn't. Only the heading is passed in already-localized; the tips
/// wait for the same kind of reviewed translation the critical Bikol
/// strings do.
class SafetyTipsSection extends StatelessWidget {
  const SafetyTipsSection({super.key, required this.title});

  final String title;

  static const _tips = [
    'Keep your phone charged.',
    'Prepare drinking water and essential medicines.',
    'Bring valid identification and important documents.',
    'Know your nearest evacuation center.',
    'Follow instructions from local authorities.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = theme.extension<AppSemanticColors>()!.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final tip in _tips)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(tip, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
