import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/staff_auth/presentation/providers/staff_auth_provider.dart';
import '../connectivity/connectivity_service.dart';
import '../database/staff_database.dart';
import '../network/staff_api_client.dart';

/// A staff read's answer, live or the copy saved on this device.
class CachedRead<T> {
  const CachedRead({
    required this.data,
    required this.fetchedAt,
    required this.isFromCache,
  });

  final T data;
  final DateTime fetchedAt;
  final bool isFromCache;
}

/// Network first, then the last saved answer of the same request, per
/// account (the staff database is encrypted). Throws only when there is
/// neither.
class StaffReadCache {
  StaffReadCache(this._api, this._db, this._connectivity, this._ownerStaffId);

  final StaffApiClient _api;
  final StaffDatabase _db;
  final ConnectivityService _connectivity;
  final int? _ownerStaffId;

  Future<CachedRead<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final owner = _ownerStaffId ?? 0;
    final key = query == null || query.isEmpty
        ? path
        : '$path?${(query.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').join('&')}';
    if (await _connectivity.hasConnection) {
      try {
        final response = await _api.get(path, queryParameters: query);
        final data =
            (response.data as Map<String, dynamic>)['data']
                as Map<String, dynamic>;
        final now = DateTime.now();
        await _db
            .into(_db.cachedResponses)
            .insertOnConflictUpdate(
              CachedResponsesCompanion.insert(
                cacheKey: key,
                ownerStaffId: owner,
                json: jsonEncode(data),
                fetchedAtEpochMs: now.millisecondsSinceEpoch,
              ),
            );
        return CachedRead(data: data, fetchedAt: now, isFromCache: false);
      } catch (_) {
        // Fall back to the saved copy.
      }
    }
    final row =
        await (_db.select(_db.cachedResponses)..where(
              (t) => t.cacheKey.equals(key) & t.ownerStaffId.equals(owner),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw StateError('Nothing saved on this device for $key yet.');
    }
    return CachedRead(
      data: jsonDecode(row.json) as Map<String, dynamic>,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(row.fetchedAtEpochMs),
      isFromCache: true,
    );
  }
}

final staffReadCacheProvider = Provider<StaffReadCache>(
  (ref) => StaffReadCache(
    ref.watch(staffApiClientProvider),
    ref.watch(staffDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(staffAuthProvider).value?.id,
  ),
);
