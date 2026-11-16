import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/env/env.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/staff_session.dart';
import '../providers/staff_auth_provider.dart';

/// Shown instead of any staff screen to an account with no
/// `operations.access` (the administrator): system upkeep is done on
/// the web, and every operational endpoint answers 403 for it.
class UseTheWebPage extends ConsumerWidget {
  const UseTheWebPage({super.key, required this.session});

  final StaffSession session;

  /// The website the API belongs to: the API base URL without its path.
  static Uri get websiteUri => Uri.parse(Env.apiBaseUrl).replace(path: '/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffUseTheWebTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.desktop_windows_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(session.name, style: theme.textTheme.titleMedium),
          Text(session.roleDisplayName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(l10n.staffUseTheWebBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () =>
                launchUrl(websiteUri, mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.staffOpenWebsite),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await ref.read(staffAuthProvider.notifier).logout();
              if (context.mounted) context.go('/home');
            },
            child: Text(l10n.staffSignOut),
          ),
        ],
      ),
    );
  }
}
