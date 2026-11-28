import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_locale.dart';
import '../../core/localization/app_theme_mode.dart';
import '../../features/barangay_status/presentation/barangay_status_providers.dart';
import '../../features/staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../../core/localization/app_text_scale.dart';

/// The app's cold-start loading screen — the branded E-LIKAS mark over
/// the Ligao evacuation artwork.
///
/// Shown for at least [minimumDisplayDuration] so the branding is
/// actually visible rather than flashing past in a single frame, but
/// not a moment longer than that once real startup work is done: see
/// [_SplashPageState._bootstrap], which races the minimum-duration
/// timer against [_SplashPageState._initializeApp] with `Future.wait`
/// rather than adding a fixed delay on top of however long init takes.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const Duration minimumDisplayDuration = Duration(milliseconds: 800);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // The minimum-duration delay and real init run concurrently, not
    // sequentially: on a fast device init finishes almost instantly
    // and the delay is what sets the pace; on a slow one init is what
    // sets the pace and no extra time gets added on top of it.
    await Future.wait([
      _initializeApp(),
      Future.delayed(SplashPage.minimumDisplayDuration),
    ]);
    // Signed-in staff open their staff home directly (Part 3.1); the
    // resident app is for everyone else. A stored token is enough: the
    // staff screens restore the session (offline from the saved copy).
    var staff = false;
    try {
      staff = await ref.read(staffAuthRepositoryProvider).hasStoredToken();
    } catch (_) {}
    if (mounted) context.go(staff ? '/staff/home' : '/home');
  }

  /// The real startup work this app has: loading the resident's
  /// previously-selected language, theme, and notification preference
  /// (if any) so Home never flashes the defaults before switching.
  /// Each of these only runs once per app launch, here. The Drift
  /// databases themselves are opened lazily by whichever repository
  /// first needs them — no eager database initialization is needed on
  /// this path.
  ///
  /// Failing any of these isn't fatal to reaching Home: every
  /// repository already treats a missing/unavailable cache as "no
  /// offline data yet" rather than crashing, and a failed
  /// preference read just leaves the app on its default — so the
  /// splash shouldn't block navigation over any of them.
  Future<void> _initializeApp() async {
    try {
      await Future.wait([
        ref.read(appLocaleProvider.notifier).load(),
        ref.read(appThemeModeProvider.notifier).load(),
        ref.read(appTextScaleProvider.notifier).load(),
        ref.read(residentBarangayProvider.notifier).load(),
      ]);
    } catch (_) {
      // Swallowed deliberately — see doc comment above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // Map paper (ink at night): the same ground as the native launch
        // screen (android/app/src/main/res/values/colors.xml), so the
        // hand-over has no flash. Navy is for live status only.
        backgroundColor: p.ground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            // A short, one-time fade-in on entry.
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // The mark on its white seal, ringed in ink.
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.rule, width: 2),
                    ),
                    child: Image.asset(
                      'assets/images/elikas_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.shield_outlined,
                        size: 96,
                        color: Sheet.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('E-LIKAS', style: SheetText.title(p.ink, size: 44)),
                  const SizedBox(height: 10),
                  Text(
                    'Electronic Ligao Kaligtasan Sistema'.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: SheetText.label(p.ink2, size: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ligao City, Albay',
                    style: SheetText.caption(p.caption),
                  ),
                  const Spacer(flex: 4),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context).preparingEmergencyInfo,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: p.ink2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
