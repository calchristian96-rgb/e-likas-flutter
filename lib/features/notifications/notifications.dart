import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/staff_read_cache.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../transfers/transfers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.createdAt,
    this.href,
    this.type,
    this.urgent = false,
  });

  /// The server's notification kind when it sends one (e.g.
  /// `RegistrationOpen`); null on older servers.
  final String? type;

  /// CSWD: the first evacuee at a pending center (`urgent: true`).
  final bool urgent;

  /// The web path it points to, e.g. /transfer-requests.
  final String? href;

  final String id;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;
}

class NotificationsState {
  const NotificationsState({required this.unread, required this.items});

  final int unread;
  final List<AppNotification> items;
}

/// `GET /notifications` (backend b0ff476): the latest ten for this
/// account and how many are unread, e.g. "an event is now active".
final notificationsProvider = FutureProvider.autoDispose<NotificationsState>((
  ref,
) async {
  final read = await ref.watch(staffReadCacheProvider).get('/notifications');
  return NotificationsState(
    unread: (read.data['unread'] as num?)?.toInt() ?? 0,
    items: [
      for (final n in read.data['notifications'] as List? ?? const [])
        AppNotification(
          id: (n as Map<String, dynamic>)['id'].toString(),
          title: n['title'] as String? ?? '',
          message: n['message'] as String? ?? '',
          read: n['read'] == true,
          href: n['href'] as String?,
          type: (n['type'] ?? n['kind']) as String?,
          urgent: n['urgent'] == true,
          createdAt: DateTime.tryParse(
            n['created_at'] as String? ?? '',
          )?.toLocal(),
        ),
    ],
  );
});

/// The app screen for a notification's web `href`, or null when the
/// app has none.
String? appPathForHref(String? href) {
  final path = Uri.tryParse(href ?? '')?.path ?? '';
  if (path.startsWith('/transfer-requests')) return '/staff/home/transfers';
  return null;
}

/// The bell with its unread badge.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(notificationsProvider).value?.unread ?? 0;
    return IconButton(
      tooltip: l10n.notificationsTitle,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => context.go('/staff/home/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

/// The notifications; opening the page marks them all read.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    try {
      await ref.read(staffApiClientProvider).post('/notifications/read');
      if (mounted) ref.invalidate(notificationsProvider);
    } catch (_) {
      // Offline: they stay unread until the next visit.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ListView(
        padding: pagePadding(context),
        children: async.when(
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (_, _) => [
            EmptyNote(
              icon: Icons.cloud_off_outlined,
              message: l10n.notificationsNeedConnection,
            ),
          ],
          data: (s) => s.items.isEmpty
              ? [
                  EmptyNote(
                    icon: Icons.notifications_none,
                    message: l10n.notificationsNone,
                  ),
                ]
              : [
                  for (final n in s.items) ...[
                    AppCard(
                      highlight: !n.read,
                      onTap: appPathForHref(n.href) == null
                          ? null
                          : () {
                              ref.invalidate(transferRequestsProvider);
                              context.go(appPathForHref(n.href)!);
                            },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: theme.textTheme.titleMedium),
                          if (n.message.isNotEmpty) Text(n.message),
                          if (n.createdAt != null)
                            Text(
                              formatElapsedSince(n.createdAt!),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
        ),
      ),
    );
  }
}
