import 'package:dio/dio.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/registered_family.dart';
import '../../domain/entities/registered_families_snapshot.dart';
import '../../domain/repositories/registered_families_repository.dart';
import '../datasources/registered_families_local_datasource.dart';
import '../datasources/registered_families_remote_datasource.dart';
import '../models/cached_family_model.dart';
import '../services/registered_families_sync_timestamps.dart';

/// Network-first with cache fallback, same shape as
/// `LookupRepositoryImpl` — just against the account-scoped
/// registered-families cache instead of the shared lookup caches.
///
/// Every read/write here is scoped to [_ownerStaffId], the same
/// pattern `PendingQueueRepositoryImpl` uses: null means "no staff
/// session currently resolved," treated as "nothing accessible" rather
/// than falling back to showing anyone's cache.
class RegisteredFamiliesRepositoryImpl implements RegisteredFamiliesRepository {
  RegisteredFamiliesRepositoryImpl({
    required RegisteredFamiliesRemoteDataSource remote,
    required RegisteredFamiliesLocalDataSource local,
    required ConnectivityService connectivity,
    required RegisteredFamiliesSyncTimestampService syncTimestamps,
    required int? ownerStaffId,
  }) : _remote = remote,
       _local = local,
       _connectivity = connectivity,
       _syncTimestamps = syncTimestamps,
       _ownerStaffId = ownerStaffId;

  final RegisteredFamiliesRemoteDataSource _remote;
  final RegisteredFamiliesLocalDataSource _local;
  final ConnectivityService _connectivity;
  final RegisteredFamiliesSyncTimestampService _syncTimestamps;
  final int? _ownerStaffId;

  @override
  Future<Result<RegisteredFamiliesSnapshot>> getAll() async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) {
      return const Failed(
        CacheFailure('Sign in again to load registered families.'),
      );
    }

    if (await _connectivity.hasConnection) {
      try {
        final rawFamilies = await _remote.fetchAll();
        final models = rawFamilies
            .map((json) => _toCachedModel(json, ownerStaffId))
            .toList();
        await _local.replaceAllForOwner(ownerStaffId, models);
        await _syncTimestamps.markSynced(ownerStaffId);
        return Success(
          RegisteredFamiliesSnapshot(
            families: models.map(_toEntity).toList(),
            isFromCache: false,
            lastSyncedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } on DioException catch (_) {
        // fall through to cache — an authenticated-but-unauthorized
        // (403) response also falls through here rather than being
        // surfaced specially, since the honest fallback ("show
        // whatever's cached, or an honest empty state") is the same
        // either way.
      }
    }

    final cachedModels = await _local.getAllForOwner(ownerStaffId);
    if (cachedModels.isEmpty) {
      return const Failed(
        NetworkFailure('No saved family data available offline yet.'),
      );
    }
    final lastSynced = await _syncTimestamps.getSyncedEpochMs(ownerStaffId);
    return Success(
      RegisteredFamiliesSnapshot(
        families: cachedModels.map(_toEntity).toList(),
        isFromCache: true,
        lastSyncedAtEpochMs: lastSynced,
      ),
    );
  }

  @override
  Future<List<RegisteredFamily>> getCachedOnly() async {
    final ownerStaffId = _ownerStaffId;
    if (ownerStaffId == null) return const [];
    final cachedModels = await _local.getAllForOwner(ownerStaffId);
    return cachedModels.map(_toEntity).toList();
  }

  CachedFamilyModel _toCachedModel(
    Map<String, dynamic> json,
    int ownerStaffId,
  ) {
    final familyId = json['id'] as int;
    final barangay = json['barangay'] as Map<String, dynamic>?;
    final headOfFamily = json['head_of_family'] as Map<String, dynamic>?;
    final evacuationCenter = json['evacuation_center'] as Map<String, dynamic>?;
    final members = (json['members'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final createdAt = json['created_at'] as String?;

    return CachedFamilyModel(
      id: cachedFamilyId(ownerStaffId: ownerStaffId, familyId: familyId),
      familyId: familyId,
      ownerStaffId: ownerStaffId,
      barangayId: barangay?['id'] as int?,
      barangayName: (barangay?['name'] as String?) ?? '',
      headOfFamilyName: (headOfFamily?['full_name'] as String?) ?? '',
      homeAddress: json['home_address'] as String?,
      memberCount: (json['member_count'] as int?) ?? members.length,
      evacuationCenterName: evacuationCenter?['name'] as String?,
      is4psBeneficiary: json['is_4ps_beneficiary'] as bool? ?? false,
      createdAtEpochMs: createdAt == null
          ? null
          : DateTime.tryParse(createdAt)?.millisecondsSinceEpoch,
      memberNames: members
          .map((m) => m['full_name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
    );
  }

  RegisteredFamily _toEntity(CachedFamilyModel m) => RegisteredFamily(
    id: m.familyId,
    barangayId: m.barangayId,
    barangayName: m.barangayName,
    headOfFamilyName: m.headOfFamilyName,
    homeAddress: m.homeAddress,
    memberCount: m.memberCount,
    evacuationCenterName: m.evacuationCenterName,
    is4psBeneficiary: m.is4psBeneficiary,
    createdAt: m.createdAtEpochMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m.createdAtEpochMs!),
    memberNames: m.memberNames,
  );
}
