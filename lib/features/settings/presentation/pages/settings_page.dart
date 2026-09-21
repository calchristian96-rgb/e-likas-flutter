import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/localization/app_theme_mode.dart';
import '../../../../core/localization/language_selector_sheet.dart';
import '../../../../core/localization/theme_mode_selector_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../../staff_auth/presentation/widgets/staff_identity_card.dart';
import '../providers/notification_preference_provider.dart';

/// Every row here either does something real or shows a genuinely
/// measured value — no fake toggles, no placeholder rows for
/// unimplemented features. Privacy/Terms/Support rows from the design
/// reference are deliberately omitted entirely: no actual content or
/// route exists for any of them yet, and a dead row that goes nowhere
/// is worse than not having the row.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Hidden entry point to the developer backend-override screen —
  // Android's own long-established "tap the build number 7 times"
  // convention, so anyone who'd look for a hidden dev menu already
  // knows the gesture. Resets if taps come more than 2s apart, so an
  // idle app left open over a session can't accumulate stray taps into
  // an accidental unlock. A no-op entirely in a release build: the row
  // itself gets no onTap at all in that case (see build() below), so
  // this counter is never even incremented.
  int _aboutTapCount = 0;
  Timer? _aboutTapResetTimer;

  void _handleAboutTap() {
    _aboutTapResetTimer?.cancel();
    _aboutTapCount++;
    if (_aboutTapCount >= 7) {
      _aboutTapCount = 0;
      context.push('/settings/dev');
      return;
    }
    _aboutTapResetTimer = Timer(
      const Duration(seconds: 2),
      () => _aboutTapCount = 0,
    );
  }

  @override
  void dispose() {
    _aboutTapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isConnected = ref.watch(connectivityStatusProvider).value ?? false;
    final staffSession = ref.watch(staffAuthProvider).value;
    final notificationsEnabled = ref.watch(notificationPreferenceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(title: l10n.settingsSectionOfflineData),
          _SettingsCard(
            children: [
              // No standalone "Sync Now" row here — it would just be a
              // second way to trigger the exact same `syncAll()` the
              // Offline Data Management screen's own "Update All"
              // button already does, one tap into the row above, next
              // to the real per-domain freshness it's actually about.
              _SettingsRow(
                icon: Icons.cloud_download_outlined,
                iconColor: theme.colorScheme.primary,
                title: l10n.settingsOfflineData,
                subtitle: l10n.settingsOfflineDataSubtitle,
                onTap: () => context.push('/settings/offline-data'),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: isConnected
                    ? Icons.wifi_outlined
                    : Icons.wifi_off_outlined,
                iconColor: isConnected ? semantic.success : semantic.warning,
                title: l10n.settingsConnectivity,
                subtitle: isConnected ? l10n.online : l10n.offlineModeLabel,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(title: l10n.settingsSectionNotifications),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.notifications_outlined,
                iconColor: theme.colorScheme.primary,
                title: l10n.pushNotificationsTitle,
                subtitle: l10n.pushNotificationsSubtitle,
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) => ref
                      .read(notificationPreferenceProvider.notifier)
                      .setEnabled(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(title: l10n.settingsSectionPreferences),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.language,
                iconColor: theme.colorScheme.primary,
                title: l10n.language,
                subtitle: appLocaleDisplayName(l10n, locale),
                onTap: () => showLanguageSelectorSheet(context),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: Icons.palette_outlined,
                iconColor: theme.colorScheme.tertiary,
                title: l10n.appAppearance,
                subtitle: appThemeModeDisplayName(l10n, themeMode),
                onTap: () => showThemeModeSelectorSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(title: l10n.settingsSectionStaff),
          if (staffSession == null)
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.badge_outlined,
                  iconColor: semantic.navy,
                  title: l10n.settingsStaffAccess,
                  subtitle: l10n.settingsStaffAccessSubtitle,
                  onTap: () => context.push('/settings/staff'),
                ),
              ],
            )
          else ...[
            StaffIdentityCard(session: staffSession),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: Icons.dashboard_outlined,
                  iconColor: theme.colorScheme.tertiary,
                  title: l10n.staffDashboardTitle,
                  subtitle: l10n.staffDashboardSubtitle,
                  onTap: () => context.push('/settings/staff'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _SectionLabel(title: l10n.settingsSectionAbout),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.shield_outlined,
                iconColor: semantic.navy,
                title: 'E-LIKAS',
                subtitle: l10n.aboutTagline,
                // Deliberately no onTap at all in a release build —
                // not just an inert one — so the tap sequence can't
                // even begin to count there.
                onTap: kReleaseMode ? null : _handleAboutTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: semantic.navy,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
  }) : assert(
         subtitle == null || subtitleWidget == null,
         'Pass either subtitle or subtitleWidget, not both.',
       );

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  child:
                      subtitleWidget ??
                      (subtitle != null
                          ? Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
