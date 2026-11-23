import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// The device and sync headers sent on every request
/// (docs/backend/apps-api-2026-11-23.md section 2), for the
/// administrator's "Devices and sync" view: a stable id made once per
/// install, the app version, the platform, and the sync counts. Counts
/// only, never what is waiting.
abstract final class DeviceHeaders {
  static const _idKey = 'device_id_v1';
  static const _lastSyncKey = 'device_last_sync_v1';

  static String? deviceId;
  static String? appVersion;
  static int syncPending = 0;
  static int syncFailed = 0;
  static DateTime? lastSync;

  /// Reads (or makes) the device id, the app version and the last sync.
  /// Never throws: without it the headers are simply left out.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_idKey);
      if (id == null || !isValidDeviceId(id)) {
        id = const Uuid().v4();
        await prefs.setString(_idKey, id);
      }
      deviceId = id;
      final last = prefs.getString(_lastSyncKey);
      lastSync = last == null ? null : DateTime.tryParse(last);
    } catch (e) {
      debugPrint('Device id unavailable: $e');
    }
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Left out.
    }
  }

  /// 4-100 characters of `A-Z a-z 0-9 . _ : -`.
  static bool isValidDeviceId(String id) =>
      RegExp(r'^[A-Za-z0-9._:\-]{4,100}$').hasMatch(id);

  /// The phone finished sending what was waiting.
  static Future<void> markSynced([DateTime? at]) async {
    lastSync = (at ?? DateTime.now()).toUtc();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, lastSync!.toIso8601String());
    } catch (_) {
      // Kept in memory for this run.
    }
  }

  static Map<String, String> get headers => {
    'X-Device-Id': ?deviceId,
    'X-App-Version': ?appVersion,
    'X-App-Platform': 'mobile',
    'X-Sync-Pending': '$syncPending',
    'X-Sync-Failed': '$syncFailed',
    if (lastSync != null) 'X-Last-Sync': lastSync!.toUtc().toIso8601String(),
  };

  static Interceptor interceptor() => InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers.addAll(headers);
      handler.next(options);
    },
  );
}
