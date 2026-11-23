import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import 'push_service.dart';

const _askedKey = 'push_permission_asked_v1';

/// Asks once (Android 13+ shows its own prompt after this), with the
/// reason first: "E-LIKAS tells you about emergency alerts and
/// evacuation orders for your barangay".
Future<void> askNotificationPermissionOnce(
  BuildContext context,
  PushService push,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) return;
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(l10n.pushPermissionTitle),
        content: Text(l10n.pushPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.pushPermissionLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.pushPermissionAllow),
          ),
        ],
      ),
    );
    await prefs.setBool(_askedKey, true);
    if (ok == true) await push.requestPermission();
  } catch (_) {
    // Asked again next start.
  }
}
