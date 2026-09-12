import 'package:flutter/material.dart';

/// A compact, always-local search box — every call site in this app
/// filters an already-loaded in-memory list, never sends a request
/// per keystroke. The clear (×) button only appears once there's text
/// to clear.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.clearTooltip,
    this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? clearTooltip;

  /// Optional — only needed by callers that must know when this field
  /// gains/loses focus (e.g. the GIS map's search, which shows/hides a
  /// results overlay based on focus) or want to programmatically
  /// dismiss the keyboard. Every existing call site omits this and
  /// behaves exactly as before.
  final FocusNode? focusNode;

  /// Optional — supports "keyboard submit" (the search/return key) in
  /// addition to live-as-you-type filtering via [onChanged].
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: clearTooltip,
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            );
          },
        ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
