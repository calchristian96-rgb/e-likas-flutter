import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// "Larger text": on top of the phone's own text size, never smaller.
enum AppTextScale {
  normal(1.0),
  large(1.15),
  larger(1.3);

  const AppTextScale(this.factor);

  final double factor;
}

String appTextScaleName(AppLocalizations l10n, AppTextScale s) => switch (s) {
  AppTextScale.normal => l10n.textSizeNormal,
  AppTextScale.large => l10n.textSizeLarge,
  AppTextScale.larger => l10n.textSizeLarger,
};

class AppTextScaleNotifier extends Notifier<AppTextScale> {
  static const _key = 'elikas.textScale';

  @override
  AppTextScale build() => AppTextScale.normal;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      state = AppTextScale.values.firstWhere(
        (s) => s.name == name,
        orElse: () => AppTextScale.normal,
      );
    } catch (_) {
      // Normal.
    }
  }

  Future<void> set(AppTextScale scale) async {
    state = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, scale.name);
    } catch (_) {
      // Kept for this run.
    }
  }
}

final appTextScaleProvider =
    NotifierProvider<AppTextScaleNotifier, AppTextScale>(
      AppTextScaleNotifier.new,
    );

/// Multiplies the phone's text scale by the chosen factor.
class AppTextScaleWrapper extends ConsumerWidget {
  const AppTextScaleWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(appTextScaleProvider).factor;
    if (factor == 1.0) return child;
    final media = MediaQuery.of(context);
    final base = media.textScaler.scale(1);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(base * factor)),
      child: child,
    );
  }
}

Future<void> showTextScaleSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final l10n = AppLocalizations.of(context);
      final current = ref.watch(appTextScaleProvider);
      return SafeArea(
        child: RadioGroup<AppTextScale>(
          groupValue: current,
          onChanged: (s) {
            if (s == null) return;
            ref.read(appTextScaleProvider.notifier).set(s);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in AppTextScale.values)
                RadioListTile<AppTextScale>(
                  value: s,
                  title: Text(
                    appTextScaleName(l10n, s),
                    textScaler: TextScaler.linear(s.factor),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  ),
);
