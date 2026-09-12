import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/localization/app_theme_mode.dart';
import '../../../../core/localization/language_selector_sheet.dart';
import '../../../../core/localization/theme_mode_selector_sheet.dart';
import '../../../../core/widgets/last_updated_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../../staff_auth/presentation/widgets/staff_identity_card.dart';
import '../providers/notification_preference_provider.dart';
import '../providers/offline_data_provider.dart';

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
  bool _isSyncing = false;

  Future<void> _handleSyncNow() async {
    setState(() => _isSyncing = true);
    final ok = await ref.read(offlineDataOverviewProvider.notifier).syncAll();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.syncCompleted : l10n.syncPartialFailure),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final isConnected = ref.watch(connectivityStatusProvider).value ?? false;
    final overviewAsync = ref.watch(offlineDataOverviewProvider);
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
              _SettingsRow(
                icon: Icons.cloud_download_outlined,
                iconColor: theme.colorScheme.primary,
                title: l10n.settingsOfflineData,
                subtitle: l10n.settingsOfflineDataSubtitle,
                onTap: () => context.push('/settings/offline-data'),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: Icons.sync,
                iconColor: semantic.success,
                title: l10n.settingsSyncNow,
                subtitleWidget: overviewAsync.when(
                  data: (snapshot) =>
                      LastUpdatedLabel(timestamp: snapshot.mostRecentSync),
                  loading: () => Text(l10n.checkingForAlerts),
                  error: (_, _) => Text(l10n.settingsSyncNeverRun),
                ),
                trailing: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : FilledButton(
                        onPressed: _handleSyncNow,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(72, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(l10n.settingsSyncButton),
                      ),
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
