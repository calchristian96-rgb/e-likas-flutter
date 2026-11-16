import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/staff_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/staff_api_client.dart';
import '../../../core/network/staff_api_error_mapper.dart';
import '../domain/pending_action.dart';

/// The offline queue for single-request field actions (C15).
///
/// Sent one at a time, oldest first, scoped to the signed-in account:
/// - 2xx: done, the row is removed;
/// - 401: stop the run (sign in again), nothing else is touched;
/// - a refusal (403, 404, 409, 422) or an answer lost in transit (the
///   request may have been applied): needs attention, never retried on
///   its own, except a repeat refusal of an action that can only be
///   refused because it already happened, which counts as done;
/// - no connection, a timeout before sending, 5xx: stays pending for
///   the next run.
class OutboxRepository {
  OutboxRepository(this._db, this._api, this._connectivity, this._ownerStaffId);

  final StaffDatabase _db;
  final StaffApiClient _api;
  final ConnectivityService _connectivity;
  final int? _ownerStaffId;

  static const _uuid = Uuid();
  bool _running = false;

  Future<PendingAction> enqueue({
    required PendingActionKind kind,
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String summary,
    String? subjectKey,
  }) async {
    final owner = _ownerStaffId;
    if (owner == null) throw StateError('Not signed in.');
    final action = PendingAction(
      localId: _uuid.v4(),
      kind: kind,
      method: method,
      path: path,
      body: body,
      summary: summary,
      subjectKey: subjectKey,
      status: PendingActionStatus.pending,
      createdAt: DateTime.now(),
    );
    await _db
        .into(_db.pendingActions)
        .insert(
          PendingActionsCompanion.insert(
            localId: action.localId,
            kind: kind.name,
            method: method,
            path: path,
            bodyJson: jsonEncode(body),
            summary: summary,
            subjectKey: Value(subjectKey),
            status: action.status.wire,
            createdAtEpochMs: action.createdAt.millisecondsSinceEpoch,
            ownerStaffId: owner,
          ),
        );
    return action;
  }

  Future<List<PendingAction>> getAll() async {
    final owner = _ownerStaffId;
    if (owner == null) return const [];
    final rows =
        await (_db.select(_db.pendingActions)
              ..where((t) => t.ownerStaffId.equals(owner))
              ..orderBy([(t) => OrderingTerm(expression: t.createdAtEpochMs)]))
            .get();
    return [
      for (final r in rows)
        if (PendingActionKind.fromName(r.kind) case final kind?)
          PendingAction(
            localId: r.localId,
            kind: kind,
            method: r.method,
            path: r.path,
            body: jsonDecode(r.bodyJson) as Map<String, dynamic>,
            summary: r.summary,
            subjectKey: r.subjectKey,
            status: PendingActionStatus.fromWire(r.status),
            attemptCount: r.attemptCount,
            lastErrorMessage: r.lastErrorMessage,
            createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAtEpochMs),
          ),
    ];
  }

  /// Discard (the user decided) or remove after success.
  Future<void> delete(String localId) async {
    await (_db.delete(
      _db.pendingActions,
    )..where((t) => t.localId.equals(localId))).go();
  }

  /// Back in line for the next run, after the user looked at it.
  Future<void> retry(String localId) async {
    await (_db.update(
      _db.pendingActions,
    )..where((t) => t.localId.equals(localId))).write(
      PendingActionsCompanion(
        status: Value(PendingActionStatus.pending.wire),
        lastErrorMessage: const Value(null),
      ),
    );
  }

  Future<OutboxRunResult> run() async {
    if (_running) return const OutboxRunResult();
    _running = true;
    try {
      return await _run();
    } finally {
      _running = false;
    }
  }

  Future<OutboxRunResult> _run() async {
    final queue = [
      for (final a in await getAll())
        if (!a.needsAttention) a,
    ];
    if (queue.isEmpty) return const OutboxRunResult();
    if (!await _connectivity.hasConnection) {
      return const OutboxRunResult(wasOffline: true);
    }
    var sent = 0;
    var attention = 0;
    for (final action in queue) {
      final outcome = await _send(action);
      switch (outcome) {
        case _Outcome.done:
          await delete(action.localId);
          sent++;
        case _Outcome.stopForAuth:
          return OutboxRunResult(
            sent: sent,
            needAttention: attention,
            stoppedForAuth: true,
          );
        case _Outcome.needsAttention:
          attention++;
        case _Outcome.retryLater:
          // Offline again mid-run: leave the rest for the next run.
          return OutboxRunResult(sent: sent, needAttention: attention);
      }
    }
    return OutboxRunResult(sent: sent, needAttention: attention);
  }

  Future<_Outcome> _send(PendingAction action) async {
    try {
      await switch (action.method) {
        'PATCH' => _api.patch(action.path, data: action.body),
        'PUT' => _api.put(action.path, data: action.body),
        _ => _api.post(action.path, data: action.body),
      };
      return _Outcome.done;
    } on DioException catch (e) {
      final failure = mapStaffDioError(e);
      final status = e.response?.statusCode;
      if (failure is AuthFailure) return _Outcome.stopForAuth;
      if (failure is NetworkFailure && status == null) {
        await _markAttempt(action);
        return _Outcome.retryLater;
      }
      if (failure is ServerFailure && status != null && status >= 500) {
        await _markAttempt(action, error: failure.message);
        return _Outcome.retryLater;
      }
      if (action.kind.alreadyDoneOnRepeat &&
          action.attemptCount > 0 &&
          status == 422) {
        return _Outcome.done;
      }
      await _markAttention(action, _message(failure, e));
      return _Outcome.needsAttention;
    } on TimeoutException {
      // The request may have reached the server: never resend blindly.
      await _markAttention(action, const AmbiguousWriteFailure().message);
      return _Outcome.needsAttention;
    }
  }

  static String _message(Failure failure, DioException e) {
    if (failure is ValidationFailure && failure.fieldErrors.isNotEmpty) {
      return failure.fieldErrors.values.expand((m) => m).join(' ');
    }
    return failure.message;
  }

  Future<void> _markAttempt(PendingAction action, {String? error}) async {
    await (_db.update(
      _db.pendingActions,
    )..where((t) => t.localId.equals(action.localId))).write(
      PendingActionsCompanion(
        attemptCount: Value(action.attemptCount + 1),
        lastErrorMessage: Value(error),
      ),
    );
  }

  Future<void> _markAttention(PendingAction action, String message) async {
    await (_db.update(
      _db.pendingActions,
    )..where((t) => t.localId.equals(action.localId))).write(
      PendingActionsCompanion(
        status: Value(PendingActionStatus.needsAttention.wire),
        attemptCount: Value(action.attemptCount + 1),
        lastErrorMessage: Value(message),
      ),
    );
  }
}

enum _Outcome { done, stopForAuth, needsAttention, retryLater }
