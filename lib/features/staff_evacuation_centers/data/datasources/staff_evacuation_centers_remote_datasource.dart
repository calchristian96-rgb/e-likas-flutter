import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/debug/center_photo_debug_log.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../evacuation_centers/data/models/evacuation_center_model.dart';
import '../../domain/entities/evacuation_center_draft.dart';

const _uploadTimeout = Duration(seconds: 45);

/// Raw HTTP for the authenticated staff evacuation-center endpoints —
/// `GET/POST/PATCH /evacuation-centers[/{id}]`. No JSON→entity mapping
/// here (that's `StaffEvacuationCentersRepositoryImpl`'s job, same
/// split as every other feature's remote data source).
class StaffEvacuationCentersRemoteDataSource {
  StaffEvacuationCentersRemoteDataSource(this._client);

  final StaffApiClient _client;

  Future<EvacuationCenterModel> getCenter(int id) async {
    final response = await _client.get('/evacuation-centers/$id');
    final json = _extractData(response);
    final model = EvacuationCenterModel.fromStaffJson(json);
    centerPhotoDebugLog(
      'verification read id=$id status=${response.statusCode} '
      'photo_url=${model.photoUrl}',
    );
    return model;
  }

  /// `POST /evacuation-centers` — a real `POST`, so no method-override
  /// dance is needed here regardless of whether [photo] is attached
  /// (unlike [updateCenter] — see its doc comment).
  Future<EvacuationCenterModel> createCenter(
    EvacuationCenterDraft draft, {
    File? photo,
  }) async {
    centerPhotoDebugLog('mode=create photo selected=${photo != null}');
    if (photo != null) {
      centerPhotoDebugLog(
        'file exists=${await photo.exists()} filename=${_fileName(photo)} '
        'file size=${await _safeLength(photo)}',
      );
    }

    final formData = FormData.fromMap(draft.toMultipartFields());
    var photoAttached = false;
    if (photo != null) {
      formData.files.add(MapEntry('photo', await _multipartFile(photo)));
      photoAttached = true;
    }
    centerPhotoDebugLog(
      'request method=POST request endpoint=/evacuation-centers '
      'multipart=true photo attached=$photoAttached method override=none',
    );

    final response = await _client.post(
      '/evacuation-centers',
      data: formData,
      timeout: _uploadTimeout,
    );
    _logResponse(response);
    final json = _extractData(response);
    final model = EvacuationCenterModel.fromStaffJson(json);
    centerPhotoDebugLog('parsed model.photoUrl=${model.photoUrl}');
    return model;
  }

  /// `PATCH /evacuation-centers/{id}` when no new photo is attached —
  /// a plain JSON body, which every field (including an explicit
  /// `null` to clear an optional one) round-trips correctly.
  ///
  /// When [photo] *is* attached, sends `POST /evacuation-centers/{id}`
  /// with a `_method: PATCH` field instead of a real HTTP `PATCH`.
  /// This is standard, widely-documented Laravel behavior (its own
  /// method-spoofing convention), not a guess specific to this
  /// backend: PHP does not reliably populate `$_FILES` for a native
  /// `PATCH`/`PUT` request with a multipart body across common PHP/
  /// web-server configurations, so Laravel apps that accept file
  /// uploads on an update route conventionally send the file via
  /// `POST` and let Laravel's `_method` override resolve it back to
  /// the real `PATCH` route/`UpdateEvacuationCenterRequest`/
  /// controller method. No reference implementation exists in this
  /// project (the desktop companion app has no evacuation-center CRUD
  /// UI at all) to confirm this specific backend's behavior against,
  /// so this is the standard, safe default rather than a verified
  /// fact — flagged here and in the Part 2 report.
  ///
  /// [includeLocation] controls whether `latitude`/`longitude` are
  /// sent at all in the multipart body — see
  /// `StaffEvacuationCentersRepositoryImpl.updateCenter`'s doc comment
  /// for why omitting them here is sometimes deliberate (to avoid
  /// re-sending a location that a *separate* prior request already
  /// cleared).
  Future<EvacuationCenterModel> updateCenter(
    int id,
    EvacuationCenterDraft draft, {
    File? photo,
    bool includeLocation = true,
  }) async {
    centerPhotoDebugLog('mode=edit photo selected=${photo != null}');
    if (photo != null) {
      centerPhotoDebugLog(
        'file exists=${await photo.exists()} filename=${_fileName(photo)} '
        'file size=${await _safeLength(photo)}',
      );
    }

    if (photo == null) {
      centerPhotoDebugLog(
        'request method=PATCH request endpoint=/evacuation-centers/$id '
        'multipart=false photo attached=false method override=none',
      );
      final response = await _client.patch(
        '/evacuation-centers/$id',
        data: draft.toJsonBody(),
      );
      _logResponse(response);
      final json = _extractData(response);
      final model = EvacuationCenterModel.fromStaffJson(json);
      centerPhotoDebugLog('parsed model.photoUrl=${model.photoUrl}');
      return model;
    }

    final fields = draft.toMultipartFields();
    if (!includeLocation) {
      fields.remove('latitude');
      fields.remove('longitude');
    }
    final formData = FormData.fromMap({...fields, '_method': 'PATCH'});
    formData.files.add(MapEntry('photo', await _multipartFile(photo)));
    centerPhotoDebugLog(
      'request method=POST request endpoint=/evacuation-centers/$id '
      'multipart=true photo attached=true method override=PATCH',
    );

    final response = await _client.post(
      '/evacuation-centers/$id',
      data: formData,
      timeout: _uploadTimeout,
    );
    _logResponse(response);
    final json = _extractData(response);
    final model = EvacuationCenterModel.fromStaffJson(json);
    centerPhotoDebugLog('parsed model.photoUrl=${model.photoUrl}');
    return model;
  }

  /// `PATCH` with a plain JSON body and no `photo` key at all — used
  /// only for the "clear location, then separately re-apply the photo
  /// change" two-step sequence (see the repository). A dedicated
  /// method rather than overloading [updateCenter] so that call site
  /// reads unambiguously as "just clear the location, nothing else."
  Future<void> clearLocation(
    int id,
    EvacuationCenterDraft draftWithClearedLocation,
  ) {
    return _client
        .patch(
          '/evacuation-centers/$id',
          data: draftWithClearedLocation.toJsonBody(),
        )
        .then((_) {});
  }

  Future<MultipartFile> _multipartFile(File file) async {
    final fileName = _fileName(file);
    return MultipartFile.fromFile(file.path, filename: fileName);
  }

  String _fileName(File file) => file.path.split(Platform.pathSeparator).last;

  Future<int?> _safeLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _extractData(Response<dynamic> response) {
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  void _logResponse(Response<dynamic> response) {
    final body = response.data;
    final dataValue = body is Map ? body['data'] : null;
    final dataPresent = dataValue != null;
    final photoUrlPresent =
        dataValue is Map && dataValue.containsKey('photo_url');
    final photoUrlValue = dataValue is Map ? dataValue['photo_url'] : null;
    centerPhotoDebugLog(
      'response status=${response.statusCode} response data present=$dataPresent '
      'photo_url key present=$photoUrlPresent photo_url is null=${photoUrlValue == null} '
      'photo_url=$photoUrlValue',
    );
    if (photoUrlValue is String) {
      centerPhotoDebugLogUrlShape(photoUrlValue);
    }
  }
}
