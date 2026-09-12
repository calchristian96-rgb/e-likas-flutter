import 'package:flutter/material.dart';

/// Horizontally-scrollable single-select filter chips — shared by
/// Alerts (severity) and Evacuation Centers (status). A chip's own
/// label is always short (a severity/status word), so a fixed row
/// height is safe here in a way it wasn't for the multi-line card
/// content that caused this app's earlier overflow bug: a longer
/// translated label just makes the chip wider, which horizontal
/// scrolling already absorbs, never taller.
class FilterChipRow<T> extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.colorBuilder,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onSelected;
  final Color? Function(T option)? colorBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          final color = colorBuilder?.call(option) ?? theme.colorScheme.primary;
          return ChoiceChip(
            label: Text(labelBuilder(option)),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.cardColor,
            selectedColor: color.withValues(alpha: 0.14),
            side: BorderSide(
              color: isSelected ? color : theme.colorScheme.outline,
            ),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}
