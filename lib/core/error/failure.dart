/// Failure hierarchy every repository returns instead of throwing.
///
/// Sealed so the presentation layer can exhaustively switch over it.
/// This is what a package like dartz's Either or fpdart would normally
/// be pulled in for — Dart 3's sealed classes and pattern matching
/// cover it natively, so no extra dependency is needed just for this.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Could not reach the server.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No cached data available yet.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Which of [LocationService.getCurrentPosition]'s four failure
/// branches produced a [LocationFailure] — lets the UI layer pick a
/// localized message instead of [LocationFailure.message] (which stays
/// English-only, since it's set from a plain Dart service with no
/// [BuildContext] to localize from). Purely a classification tag added
/// alongside the existing messages — [LocationService]'s actual
/// permission-checking calls and branching are unchanged.
enum LocationFailureReason {
  servicesDisabled,
  permissionDenied,
  permanentlyDenied,
  positionUnavailable,
}

class LocationFailure extends Failure {
  const LocationFailure([
    super.message = 'Location permission was denied.',
    this.permanentlyDenied = false,
    this.reason,
  ]);

  /// True only when the OS reports [LocationPermission.deniedForever] —
  /// the one case where retrying the in-app request can't work and the
  /// resident needs to be sent to system settings instead.
  final bool permanentlyDenied;

  final LocationFailureReason? reason;
}

/// Staff-only failures (lib/core/network/staff_api_error_mapper.dart)
/// covering the parts of the API surface the resident app never
/// touches: authenticated requests can be rejected, rate-limited, or
/// fail validation in ways a public GET never can.
///
/// Every existing `switch`/pattern-match over [Failure] in the app
/// (map and nearest-center pages) uses a wildcard `_` case, so adding
/// these four subclasses here doesn't break any existing exhaustive
/// match.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired. Sign in again.']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(
    this.fieldErrors, [
    super.message = 'Review the highlighted information.',
  ]);

  /// Raw field → messages map from the backend's 422 response body
  /// (e.g. `"members.0.first_name": ["The first name field is required."]`),
  /// so the form can map each error back onto the exact field it came
  /// from instead of showing a single generic message.
  final Map<String, List<String>> fieldErrors;
}

/// A 422 that refuses a change because of the event's state, not the
/// data typed in (docs/backend/apps-api-2026-11-22.md section 1, Locks):
/// the event is closed, no event is open, or the event is still being
/// monitored and the action waits for "Start evacuation". The server's
/// [message] is shown as it comes, with the lock look, never as an error.
class EventLockFailure extends ValidationFailure {
  const EventLockFailure(
    super.fieldErrors,
    super.message, {
    this.kind = EventLockKind.other,
  });

  final EventLockKind kind;
}

enum EventLockKind { monitored, closed, noEvent, other }

/// 423 at sign-in: five failed sign-ins lock the account for 15
/// minutes. The server's message says when to try again.
class AccountLockedFailure extends Failure {
  const AccountLockedFailure(super.message);
}

/// 503 `maintenance`: the administrator's message; try again later.
class MaintenanceFailure extends Failure {
  const MaintenanceFailure(super.message);
}

/// 403 `password_change_required`: a temporary password must be changed
/// before anything else.
class PasswordChangeRequiredFailure extends ForbiddenFailure {
  const PasswordChangeRequiredFailure([super.message]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Too many requests. Please wait and try again.',
  ]);
}

/// A request that may or may not have reached the server before the
/// connection dropped — specifically Dio's `receiveTimeout`, which
/// means the request body was fully sent and the client was waiting
/// on a response when it gave up. Distinct from [NetworkFailure]
/// (which covers failures before/during sending, e.g.
/// `connectionError`/`connectionTimeout`/`sendTimeout` — safe to
/// assume nothing reached the server): the backend has no
/// idempotency protection (confirmed by the E-LIKAS backend audit),
/// so a write that hits this can't be auto-retried without risking a
/// duplicate record. See `StaffSyncService`.
class AmbiguousWriteFailure extends Failure {
  const AmbiguousWriteFailure([
    super.message =
        'The request may or may not have been saved before the connection was lost.',
  ]);
}
