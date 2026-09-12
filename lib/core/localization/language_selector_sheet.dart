import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_locale.dart';

/// Opens the language picker as a modal bottom sheet — there's no
/// Settings screen in this app to host it on, and a sheet is the
/// lighter-weight, more discoverable choice over adding a whole new
/// route just for three options.
void showLanguageSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _LanguageSelectorSheet(),
  );
}

class _LanguageSelectorSheet extends ConsumerWidget {
  const _LanguageSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(appLocaleProvider);

    // Display names are deliberately identical across all three
    // locales (see app_*.arb: languageEnglish/languageFilipino/
    // languageBikolLigao) — a resident switching away from a language
    // they can't read should still recognize their own language's
    // name in the list.
    final options = <(Locale, String)>[
      (const Locale('en'), l10n.languageEnglish),
      (const Locale('fil'), l10n.languageFilipino),
      (const Locale('bcl'), l10n.languageBikolLigao),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectLanguage, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final (locale, label) in options)
              _LanguageOption(
                label: label,
                selected: locale.languageCode == current.languageCode,
                onTap: () {
                  ref.read(appLocaleProvider.notifier).setLocale(locale);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
