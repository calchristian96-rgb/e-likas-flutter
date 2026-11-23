/// A signed-in staff member, built from `AuthUserResource` -- the shape
/// both `POST /auth/login` and `GET /auth/me` return: id, name, email,
/// status, role, role_display_name, barangay{id,name}|null, and the
/// user's named `permissions` (`App\Auth\Permissions` on the backend).
///
/// Screens decide what to show from [permissions], never from the role
/// name (backend docs, admin-403-endpoints-step5.md).
class StaffSession {
  const StaffSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleDisplayName,
    this.barangayId,
    this.barangayName,
    this.permissions = const {},
    this.isFromCache = false,
    this.username,
    this.mustChangePassword = false,
  });

  /// `brgy.<barangay>` for the administrator-made official accounts.
  final String? username;

  /// On a temporary password: change it before anything else.
  final bool mustChangePassword;

  StaffSession copyWith({bool? mustChangePassword}) => StaffSession(
    id: id,
    name: name,
    email: email,
    role: role,
    roleDisplayName: roleDisplayName,
    barangayId: barangayId,
    barangayName: barangayName,
    permissions: permissions,
    isFromCache: isFromCache,
    username: username,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  final int id;
  final String name;
  final String email;

  /// Raw backend role string: administrator | cswd_personnel | barangay_official.
  /// Shown to the user only; access decisions use [can].
  final String role;
  final String roleDisplayName;

  final int? barangayId;
  final String? barangayName;

  /// The user's named permissions, e.g. `operations.access`,
  /// `centers.edit`, `box_relief.distribute`.
  final Set<String> permissions;

  /// True when this session came from the local cache (see
  /// `SecureTokenStorage.readCachedSession`) rather than a fresh
  /// `/auth/me` response.
  final bool isFromCache;

  bool can(String permission) => permissions.contains(permission);

  /// Any operational screen at all. The administrator has none of them
  /// and is sent to the web.
  bool get hasOperationsAccess => can(StaffPermission.operationsAccess);

  /// Barangay field work: EC Board, centers of their own barangay,
  /// relief boxes, barangay status.
  bool get isFieldOfficial =>
      hasOperationsAccess &&
      !can(StaffPermission.allBarangays) &&
      barangayId != null;

  /// City-wide read-only monitoring (CSWD).
  bool get isCityMonitor =>
      hasOperationsAccess && can(StaffPermission.allBarangays);

  bool get isBarangayOfficial => role == 'barangay_official';

  factory StaffSession.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    final barangay = json['barangay'] as Map<String, dynamic>?;
    final rawPermissions = json['permissions'];
    return StaffSession(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      roleDisplayName:
          json['role_display_name'] as String? ?? json['role'] as String,
      barangayId: barangay?['id'] as int?,
      barangayName: barangay?['name'] as String?,
      permissions: rawPermissions is List
          ? {for (final p in rawPermissions) p.toString()}
          : StaffPermission.legacyForRole(json['role'] as String?),
      isFromCache: isFromCache,
      username: json['username'] as String?,
      mustChangePassword: json['must_change_password'] == true,
    );
  }

  /// Only the non-secret fields -- safe to keep in
  /// `SecureTokenStorage`'s cached-session slot for offline restore.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'role_display_name': roleDisplayName,
    if (barangayId != null && barangayName != null)
      'barangay': {'id': barangayId, 'name': barangayName},
    'permissions': permissions.toList()..sort(),
    'username': ?username,
    'must_change_password': mustChangePassword,
  };
}

/// Permission names from the backend's `App\Auth\Permissions::MAP`.
abstract final class StaffPermission {
  static const operationsAccess = 'operations.access';
  static const allBarangays = 'scope.all_barangays';
  static const monitoring = 'page.monitoring';
  static const centersEdit = 'centers.edit';
  static const centersSetStatus = 'centers.set_status';
  static const facilityRequestsCreate = 'facility_requests.create';
  static const countSubmit = 'count_submissions.submit';
  static const reEnroll = 'families.re_enroll';
  static const boxDistribute = 'box_relief.distribute';
  static const situationUpdate = 'situation.update';
  static const puroksView = 'puroks.view';
  static const countSubmitOnBehalf = 'count_submissions.submit_on_behalf';
  static const setEvacuation = 'situation.set_evacuation';
  static const evacueesManage = 'evacuees.manage';
  static const evacueesTransfer = 'evacuees.transfer';
  static const transfersRequest = 'transfers.request';
  static const transfersReceive = 'transfers.receive';
  static const transfersManage = 'transfers.manage';
  static const centersSetLocation = 'centers.set_location';
  static const eventsManage = 'events.manage';
  static const familiesToEvacuateManage = 'families_to_evacuate.manage';
  static const supportReport = 'support.report';

  /// For a session cached before the backend sent `permissions` (an app
  /// upgraded while offline): the same map as the backend, by role,
  /// until the next `/auth/me` replaces it.
  static Set<String> legacyForRole(String? role) => switch (role) {
    'barangay_official' => const {
      operationsAccess,
      monitoring,
      centersEdit,
      centersSetStatus,
      facilityRequestsCreate,
      countSubmit,
      reEnroll,
      boxDistribute,
      situationUpdate,
      puroksView,
      evacueesManage,
      evacueesTransfer,
      transfersRequest,
      transfersReceive,
    },
    // families.re_enroll is officials only now (backend 75792e7).
    'cswd_personnel' => const {
      operationsAccess,
      allBarangays,
      monitoring,
      centersSetStatus,
      situationUpdate,
      puroksView,
      countSubmitOnBehalf,
      setEvacuation,
      evacueesTransfer,
      transfersManage,
    },
    _ => const {},
  };
}
