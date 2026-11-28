import 'package:flutter/material.dart';

import '../../app/theme/sheet_tokens.dart';

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
    this.leadingBuilder,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onSelected;
  final Color? Function(T option)? colorBuilder;

  /// A symbol before the words (e.g. a CenterSymbol for a center
  /// state); wins over [colorBuilder]'s swatch. [selected] is true on
  /// the inverted (ink) chip.
  final Widget? Function(T option, bool selected)? leadingBuilder;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          final color = colorBuilder?.call(option);
          // Selected inverts to ink, like the web's line button; a status
          // filter keeps a swatch of its colour next to its words.
          final leading = leadingBuilder?.call(option, isSelected);
          return ChoiceChip(
            avatar:
                leading ??
                (color == null
                    ? null
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: p.symbolStroke),
                        ),
                      )),
            label: Text(labelBuilder(option).toUpperCase()),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
            backgroundColor: p.ground,
            selectedColor: p.ink,
            side: BorderSide(color: p.ink, width: Sheet.rule),
            labelStyle: SheetText.label(
              isSelected ? p.ground : p.ink,
              size: 15,
            ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
          );
        },
      ),
    );
  }
}
