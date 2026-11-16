import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _user(
  String role,
  List<String> permissions, {
  Map<String, dynamic>? barangay,
}) => {
  'id': 4,
  'name': 'Ana',
  'email': 'ana@example.test',
  'role': role,
  'role_display_name': role,
  'barangay': barangay,
  'permissions': permissions,
};

void main() {
  test('reads permissions and survives the cached-session round trip', () {
    final session = StaffSession.fromJson(
      _user(
        'barangay_official',
        ['operations.access', 'centers.edit'],
        barangay: {'id': 13, 'name': 'Binatagan'},
      ),
    );
    expect(session.can('centers.edit'), isTrue);
    expect(session.isFieldOfficial, isTrue);
    expect(session.isCityMonitor, isFalse);

    final restored = StaffSession.fromJson(session.toJson(), isFromCache: true);
    expect(restored.permissions, session.permissions);
    expect(restored.barangayId, 13);
  });

  test('administrator has no operations access', () {
    final admin = StaffSession.fromJson(
      _user('administrator', ['users.manage', 'barangays.view']),
    );
    expect(admin.hasOperationsAccess, isFalse);
    expect(admin.isFieldOfficial, isFalse);
    expect(admin.isCityMonitor, isFalse);
  });

  test('CSWD is the city monitor', () {
    final cswd = StaffSession.fromJson(
      _user('cswd_personnel', [
        'operations.access',
        'scope.all_barangays',
        'page.monitoring',
      ]),
    );
    expect(cswd.isCityMonitor, isTrue);
    expect(cswd.isFieldOfficial, isFalse);
  });

  test('an old cached session without permissions falls back by role', () {
    final old = StaffSession.fromJson(
      _user(
        'barangay_official',
        const [],
        barangay: {'id': 1, 'name': 'Abella'},
      )..remove('permissions'),
    );
    expect(old.isFieldOfficial, isTrue);
    final oldAdmin = StaffSession.fromJson(
      _user('administrator', const [])..remove('permissions'),
    );
    expect(oldAdmin.hasOperationsAccess, isFalse);
  });
}
