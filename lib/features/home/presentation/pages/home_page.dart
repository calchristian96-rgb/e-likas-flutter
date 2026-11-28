import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/data_freshness_formatter.dart';
import '../../../../core/utils/philippine_time.dart';
import '../../../../core/widgets/connectivity_badge.dart';
import '../../../../core/widgets/last_updated_label.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/presentation/providers/alerts_summary_provider.dart';
import '../../../barangay_status/presentation/barangay_status_providers.dart';
import '../../../barangay_status/presentation/resident_area.dart';
import '../../../evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../../settings/presentation/providers/offline_data_provider.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../domain/dashboard_summary.dart';
import '../providers/home_provider.dart';
import '../widgets/emergency_status_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/welcome_section.dart';
import '../../../resident_safety/resident_safety.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  DateTime? _lastUpdated;

  /// The single "current time" every clock-dependent widget on this
  /// page reads from — the header's date/time line and the greeting
  /// below it both take this same value rather than each calling
  /// [philippineNow] independently, so the two can never disagree
  /// about what time it currently is.
  ///
  /// Always Philippine Standard Time (Asia/Manila, UTC+8), regardless
  /// of whatever timezone the device itself is configured for — see
  /// [philippineNow]'s own doc comment for why that's safe to display
  /// directly.
  DateTime _now = philippineNow();
  Timer? _clockTimer;

  /// True while the Quick Actions "Refresh" tile's own sync is in
  /// flight — reuses [OfflineDataOverview.syncAll], the same
  /// invalidate-then-await-all-four-domains action Settings' "Sync Now"
  /// already uses, rather than a second refresh implementation.
  bool _isQuickRefreshing = false;

  Future<void> _handleQuickRefresh() async {
    if (_isQuickRefreshing) return;
    setState(() => _isQuickRefreshing = true);
    final ok = await ref.read(offlineDataOverviewProvider.notifier).syncAll();
    if (!mounted) return;
    setState(() => _isQuickRefreshing = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.syncCompleted : l10n.syncPartialFailure),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scheduleNextClockTick();
  }

  /// Aligns the first tick to the start of the next real minute
  /// (rather than a flat 60s from whenever this widget happened to
  /// build), then settles into an exact one-per-minute cadence —
  /// otherwise the displayed minute could lag up to 59s behind the
  /// device clock depending on build timing. Entirely local to this
  /// page: independent of AppShell's 60s alert-polling timer, so
  /// neither can affect the other's cadence, lifecycle, or disposal.
  ///
  /// The alignment math itself still reads the device's own
  /// `DateTime.now()` — deliberately, not a bug: PST's offset from the
  /// device's clock is always a whole number of hours (never a
  /// fractional-minute offset), so "how many seconds until the next
  /// minute boundary" is identical in both timezones. Only the
  /// *displayed* value ([philippineNow]) needs the PST conversion.
  void _scheduleNextClockTick() {
    final now = DateTime.now();
    final untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: 1000 - now.millisecond,
    );
    _clockTimer = Timer(untilNextMinute, () {
      if (!mounted) return;
      setState(() => _now = philippineNow());
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() => _now = philippineNow());
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final centersAsync = ref.watch(allEvacuationCentersProvider);
    final alertsAsync = ref.watch(alertsSummaryProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    // "Last updated" tracks the moment the centers section last
    // resolved to real data — a single, simple anchor rather than
    // trying to track each of the dashboard's several data sources
    // independently, which would add real complexity for a
    // first-pass dashboard timestamp.
    ref.listen(allEvacuationCentersProvider, (previous, next) {
      if (next.hasValue) {
        setState(() => _lastUpdated = DateTime.now());
      }
    });

    final isConnected = connectivityAsync.value ?? false;
    final hasAnyData = centersAsync.hasValue || alertsAsync.hasValue;
    final hasAnyError = centersAsync.hasError || alertsAsync.hasError;
    final freshness = deriveFreshness(
      isConnected: isConnected,
      hasAnyData: hasAnyData,
      hasAnyError: hasAnyError,
    );

    return Scaffold(
      // No SafeArea at the Scaffold level — the header below paints
      // its own navy background behind the status bar (handled via
      // its own internal SafeArea(bottom: false)) so the brand color
      // reaches the very top edge instead of stopping short of it.
      body: Column(
        children: [
          _BrandedHeader(isConnected: isConnected, now: _now, l10n: l10n),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  OfflineBanner(
                    isOffline: freshness == DataFreshness.offline,
                    lastUpdated: _lastUpdated,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      // Same action as the Quick Actions "Refresh" tile
                      // and Settings' "Sync Now" — one synchronization
                      // path for the whole app, not three copies of the
                      // same invalidate-then-await logic. Each section
                      // already shows its own error state via
                      // AsyncValue.error, so the bool result here isn't
                      // needed — this callback's only job is to let the
                      // pull-to-refresh spinner finish.
                      onRefresh: () {
                        ref.invalidate(residentPositionProvider);
                        return ref
                            .read(offlineDataOverviewProvider.notifier)
                            .syncAll();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          // Answer first (web design rule 2): is this a
                          // drill, how urgent is it, my barangay, where
                          // to go. Nothing decorative.
                          // An evacuation order for this barangay comes
                          // before everything.
                          const EvacuationOrderBanner(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: EmergencyStatusCard(
                              key: ValueKey(alertsAsync.value?.latest?.id),
                              latestAlert: alertsAsync.value?.latest,
                              isLoading: alertsAsync.isLoading,
                              isUnavailable: alertsAsync.hasError,
                              isOffline: !isConnected,
                              lastChecked: _lastUpdated,
                              situation: ref
                                  .watch(barangayStatusBoardProvider)
                                  .value,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Where the phone is now: its barangay's
                          // status and what to do (hidden without a
                          // location).
                          const YourAreaCard(),
                          // The three nearest safe centers (never Full,
                          // Closed or inside Mayon's danger zone).
                          const SafeCentersCard(),
                          const HazardsCard(),
                          const _PrepareCard(),
                          const SizedBox(height: 24),
                          SectionHeader(title: l10n.quickActions),
                          const SizedBox(height: 8),
                          _QuickActionsGrid(
                            l10n: l10n,
                            onRefresh: _handleQuickRefresh,
                            isRefreshing: _isQuickRefreshing,
                          ),
                          const SizedBox(height: 24),
                          _LastUpdatedFooter(
                            lastUpdated: _lastUpdated,
                            freshness: freshness,
                            l10n: l10n,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sheet's title box across the top of Home: the E-LIKAS mark and
/// name in condensed caps, the place, the connectivity tag and the date,
/// on map paper ruled off below. Navy is kept for live status only (the
/// bulletin strip above, when there is news), so it is not used here.
class _BrandedHeader extends StatelessWidget {
  const _BrandedHeader({
    required this.isConnected,
    required this.now,
    required this.l10n,
  });

  final bool isConnected;

  /// Device-local time only — never fetched from Laravel or any
  /// network source. Passed down from [_HomePageState] so this and
  /// [WelcomeSection]'s greeting always agree on what time it is.
  final DateTime now;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.ground,
          border: Border(bottom: BorderSide(color: p.rule, width: Sheet.frame)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _LogoBadge(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'E-LIKAS',
                            style: SheetText.title(p.ink, size: 34),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Electronic Ligao Kaligtasan Sistema'.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SheetText.label(p.ink2, size: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _StaffSignInButton(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: p.ink2),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Ligao City, Albay'.toUpperCase(),
                        style: SheetText.label(
                          p.ink,
                          size: 14,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ConnectivityBadge(isConnected: isConnected),
                  ],
                ),
                const SizedBox(height: 6),
                _HeaderDateTimeRow(now: now),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live local date/time line for the header — device clock only
/// ([HomePage] passes down the one shared [DateTime] both this and
/// [WelcomeSection]'s greeting read from), set as the sheet's italic
/// caption. A [Wrap], so a long weekday/month on a narrow phone or under
/// a larger text-scale flows the time onto its own line.
class _HeaderDateTimeRow extends StatelessWidget {
  const _HeaderDateTimeRow({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final style = SheetText.caption(SheetPalette.of(context).caption);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(DateFormat('EEEE, MMMM d, yyyy').format(now), style: style),
        Text('  ·  ${DateFormat('h:mm a').format(now)}', style: style),
      ],
    );
  }
}

/// The E-LIKAS mark on a white disc (a seal is one of the few round
/// forms on the sheet), ringed in ink.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: p.rule, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Image.asset(
          'assets/images/elikas_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.shield_outlined, size: 26, color: Sheet.ink),
        ),
      ),
    );
  }
}

/// The way into Staff Mode, in plain sight on the resident app (C14):
/// "Staff sign in", or "Staff Mode" once signed in. 48 dp tall.
class _StaffSignInButton extends ConsumerWidget {
  const _StaffSignInButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.watch(staffAuthProvider).value != null;
    // A line button (2 px ink); once signed in it inverts to the solid
    // ink of the Staff Mode band.
    final p = SheetPalette.of(context);
    final fg = signedIn ? p.ground : p.ink;
    return OutlinedButton.icon(
      onPressed: () => context.go('/staff'),
      icon: Icon(Icons.badge_outlined, color: fg, size: 20),
      label: Text(
        (signedIn ? l10n.staffModeButton : l10n.staffSignInButton)
            .toUpperCase(),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: fg,
        backgroundColor: signedIn ? p.ink : null,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: SheetText.label(
          fg,
          size: 15,
        ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
    );
  }
}

class _LastUpdatedFooter extends StatelessWidget {
  const _LastUpdatedFooter({
    required this.lastUpdated,
    required this.freshness,
    required this.l10n,
  });

  final DateTime? lastUpdated;
  final DataFreshness freshness;
  final AppLocalizations l10n;

  bool get _isStale =>
      (freshness == DataFreshness.cached ||
          freshness == DataFreshness.offline) &&
      isDataStale(lastUpdated);

  /// Distinguishes how old the cached data actually is instead of a
  /// single fixed "showing saved information" line — "Saved" for data
  /// that resolved on this device only moments ago, "Last updated" for
  /// anything older than that, and an explicit "Caution" once it's
  /// 24h+ old, since emergency information that stale deserves more
  /// than a quiet colour change.
  ///
  /// The elapsed-time suffix itself (`formatElapsedSince`, e.g. "5m
  /// ago") stays in English regardless of the selected language — a
  /// known, intentionally-scoped gap; see the final report for why.
  String get _message {
    if (freshness == DataFreshness.live) return l10n.youAreViewingLiveData;
    if (freshness == DataFreshness.unavailable) {
      return '${l10n.liveDataUnavailable} — ${l10n.showingSavedInfo}';
    }
    final since = lastUpdated;
    if (since == null) {
      return '${l10n.offlineModeLabel} — ${l10n.showingSavedInfo}';
    }
    if (_isStale) {
      return '${l10n.freshnessCaution} — ${l10n.freshnessLastUpdatedVerb} '
          '${formatElapsedSince(since)}.';
    }
    final verb = DateTime.now().difference(since).inMinutes < 5
        ? l10n.freshnessSavedVerb
        : l10n.freshnessLastUpdatedVerb;
    return '${l10n.offline} • $verb ${formatElapsedSince(since)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stale = _isStale;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                stale ? Icons.warning_amber_rounded : Icons.history_outlined,
                size: 14,
                color: stale
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              // Expanded is what actually makes this wrap — without it a
              // Row's Text child always renders at its single-line
              // intrinsic width, which is wider than the screen for this
              // message and overflows off the right edge regardless of
              // the Row's own mainAxisSize.
              Expanded(
                child: Text(
                  _message,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stale ? theme.colorScheme.error : null,
                    fontWeight: stale ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: LastUpdatedLabel(timestamp: lastUpdated),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onRefresh,
    required this.isRefreshing,
    required this.l10n,
  });

  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    // "Find Nearest Center", "Open Hazard Map", "View Alerts",
    // "Emergency Hotlines", "Settings", and "Language" all stay out of
    // this list now — each one opens exactly what its own bottom-nav
    // tab (or, for Language, Settings → Language) already opens, so
    // keeping them here would just give a resident two ways to reach
    // the same screen with no way to tell them apart. What's left is
    // the one destination the bottom nav genuinely can't reach (the
    // full centers list — Evacuation Centers has no tab of its own)
    // plus a one-tap refresh.
    final actions = [
      QuickActionCard(
        label: l10n.viewAllEvacuationCenters,
        icon: Icons.home_work_outlined,
        accentColor: theme.colorScheme.primary,
        onTap: () => context.push('/centers'),
      ),
      QuickActionCard(
        label: isRefreshing ? l10n.refreshing : l10n.refreshData,
        icon: Icons.refresh,
        accentColor: semantic.success,
        onTap: isRefreshing ? () {} : onRefresh,
      ),
    ];

    // LayoutBuilder + manually-chunked Row/Expanded pairs, not a
    // GridView with a guessed mainAxisExtent — the exact anti-pattern
    // that caused a real "RenderFlex overflowed" crash elsewhere in
    // this app (see Offline Data Management's overview tiles). Each
    // row's height comes from IntrinsicHeight measuring its own
    // content, so a longer translated label wrapping to a second line
    // just makes the row taller instead of overflowing a fixed cell.
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseColumns = constraints.maxWidth >= 600 ? 3 : 2;
        // Never wider than the actual number of actions — with only
        // two left, a 3-column wide-screen layout would otherwise
        // leave one invisible spacer cell dangling in the row instead
        // of the two real cards filling it naturally.
        final columns = actions.length < baseColumns
            ? actions.length
            : baseColumns;
        final rowsOfActions = <List<Widget>>[];
        for (var i = 0; i < actions.length; i += columns) {
          final end = (i + columns < actions.length)
              ? i + columns
              : actions.length;
          rowsOfActions.add(actions.sublist(i, end));
        }

        return Column(
          children: [
            for (var r = 0; r < rowsOfActions.length; r++) ...[
              if (r > 0) const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: 10),
                      Expanded(
                        // Pads out an incomplete final row (e.g. 5
                        // actions in 3 columns leaves 2 empty cells)
                        // with invisible spacers so the real cards keep
                        // a consistent width instead of stretching to
                        // fill the row on their own.
                        child: c < rowsOfActions[r].length
                            ? rowsOfActions[r][c]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Be prepared: go-bag, checklists, family plan (all offline).
class _PrepareCard extends StatelessWidget {
  const _PrepareCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 64,
        leading: Icon(
          Icons.backpack_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(l10n.prepTitle),
        subtitle: Text(l10n.prepSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/prepare'),
      ),
    );
  }
}
