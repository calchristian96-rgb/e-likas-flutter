import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_locale.dart';
import '../../core/localization/app_theme_mode.dart';
import '../../features/settings/presentation/providers/notification_preference_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

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

  static const Duration minimumDisplayDuration = Duration(milliseconds: 1800);

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
    if (mounted) context.go('/home');
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
        ref.read(notificationPreferenceProvider.notifier).load(),
      ]);
    } catch (_) {
      // Swallowed deliberately — see doc comment above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: semantic.navy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/elikas_background.png',
              fit: BoxFit.cover,
              // Falls back to a plain navy gradient if the artwork is ever
              // missing, rather than a blank/broken-image screen — same
              // reasoning as the logo's own fallback below.
              errorBuilder: (context, error, stackTrace) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [semantic.navy, semantic.deepNavy],
                  ),
                ),
              ),
            ),
            // Dark navy overlay so the logo/text stay readable regardless
            // of how bright or busy the background artwork is underneath.
            Container(color: semantic.deepNavy.withValues(alpha: 0.68)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 32,
                ),
                // A short, one-time fade-in on entry — TweenAnimationBuilder
                // animates from 0 to 1 automatically as soon as it first
                // builds, no AnimationController/vsync plumbing needed for
                // something this simple.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  builder: (context, opacity, child) {
                    return Opacity(opacity: opacity, child: child);
                  },
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/elikas_logo.png',
                          fit: BoxFit.contain,
                          // The real logo file is dropped into assets/images/
                          // outside this codebase's own tooling — until it's
                          // there, fall back to a placeholder rather than let
                          // a missing asset show as a blank circle with no
                          // indication why.
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.shield_outlined,
                            size: 96,
                            color: semantic.navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'E-LIKAS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Electronic Ligao Kaligtasan Sistema',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ligao City, Albay',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 4),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppLocalizations.of(context).preparingEmergencyInfo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
