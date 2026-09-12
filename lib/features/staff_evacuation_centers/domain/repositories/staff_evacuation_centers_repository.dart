import 'dart:io';

import '../../../../core/error/result.dart';
import '../../../evacuation_centers/domain/entities/evacuation_center.dart';
import '../entities/evacuation_center_draft.dart';

/// Online-only staff evacuation-center management — no offline queue,
/// no local cache of its own (see this feature's top-level doc
/// comment for why: Add/Edit Center is deliberately online-only,
/// unlike Family Registration).
abstract class StaffEvacuationCentersRepository {
  /// The full authenticated detail for one center (`GET
  /// /evacuation-centers/{id}`) — the only response shape that
  /// includes `created_by`, needed both to prefill the edit form and
  /// to decide whether Edit should be shown at all.
  Future<Result<EvacuationCenter>> getCenterDetail(int id);

  /// `POST /evacuation-centers`. [photo], if provided, is sent as the
  /// `photo` multipart field.
  Future<Result<EvacuationCenter>> createCenter(
    EvacuationCenterDraft draft, {
    File? photo,
  });

  /// `PATCH /evacuation-centers/{id}` (or, when [photo] is provided,
  /// `POST` with Laravel's `_method=PATCH` override — see the remote
  /// data source's doc comment for why).
  ///
  /// [locationWasCleared] must be true when this edit changed a
  /// previously-set location to "no location" — see
  /// `EvacuationCenterDraft.toMultipartFields`'s doc comment for why
  /// that specific combination (clearing location *and* changing the
  /// photo in the same save) needs special handling to actually take
  /// effect.
  Future<Result<EvacuationCenter>> updateCenter(
    int id,
    EvacuationCenterDraft draft, {
    File? photo,
    bool locationWasCleared = false,
  });
}
