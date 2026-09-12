/// A signed-in staff member, built from `UserResource` (confirmed
/// fields: id, name, email, contact_number, status, role,
/// role_display_name, barangay{id,name}|null) — matches the exact
/// shape both `POST /auth/login` and `GET /auth/me` return.
class StaffSession {
  const StaffSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleDisplayName,
    this.barangayId,
    this.barangayName,
    this.isFromCache = false,
  });

  final int id;
  final String name;
  final String email;

  /// Raw backend role string: administrator | cswd_personnel | barangay_official.
  final String role;
  final String roleDisplayName;

  final int? barangayId;
  final String? barangayName;

  /// True when this session came from the local cache (see
  /// `SecureTokenStorage.readCachedSession`) rather than a fresh
  /// `/auth/me` response — the app couldn't reach the server to
  /// re-validate the token, so the UI should show it's working from a
  /// saved session rather than implying it's live.
  final bool isFromCache;

  bool get isBarangayOfficial => role == 'barangay_official';

  factory StaffSession.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    final barangay = json['barangay'] as Map<String, dynamic>?;
    return StaffSession(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      roleDisplayName:
          json['role_display_name'] as String? ?? json['role'] as String,
      barangayId: barangay?['id'] as int?,
      barangayName: barangay?['name'] as String?,
      isFromCache: isFromCache,
    );
  }

  /// Only the non-secret fields — safe to keep in
  /// `SecureTokenStorage`'s cached-session slot for offline session
  /// restoration.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'role_display_name': roleDisplayName,
    if (barangayId != null && barangayName != null)
      'barangay': {'id': barangayId, 'name': barangayName},
  };
}
