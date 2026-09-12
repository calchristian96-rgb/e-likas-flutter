import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_theme_mode.dart';

/// Same modal-bottom-sheet pattern as [showLanguageSelectorSheet] —
/// three options, a checkmark on the active one, applies immediately.
void showThemeModeSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _ThemeModeSelectorSheet(),
  );
}

class _ThemeModeSelectorSheet extends ConsumerWidget {
  const _ThemeModeSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(appThemeModeProvider);

    final options = <(ThemeMode, String)>[
      (ThemeMode.system, l10n.appearanceSystem),
      (ThemeMode.light, l10n.appearanceLight),
      (ThemeMode.dark, l10n.appearanceDark),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appAppearance, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final (mode, label) in options)
              _ThemeModeOption(
                label: label,
                selected: mode == current,
                onTap: () {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
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
