import 'package:dio/dio.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/network/device_headers.dart';
import 'package:elikas_mobile/core/network/staff_api_client.dart';
import 'package:elikas_mobile/core/network/staff_api_error_mapper.dart';
import 'package:elikas_mobile/features/staff_auth/domain/entities/staff_session.dart';
import 'package:elikas_mobile/features/staff_auth/presentation/widgets/staff_auth_guard.dart';
import 'package:elikas_mobile/features/staff_home/staff_alerts.dart';
import 'package:elikas_mobile/features/support/support_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';

DioException _answer(int status, Map<String, dynamic> body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
);

void main() {
  test('locked account, maintenance and a required password change', () {
    expect(
      mapStaffDioError(
        _answer(423, {'message': 'Too many attempts. Try again at 3:15 PM.'}),
      ),
      isA<AccountLockedFailure>().having(
        (f) => f.message,
        'message',
        'Too many attempts. Try again at 3:15 PM.',
      ),
    );
    expect(
      mapStaffDioError(
        _answer(503, {
          'message': 'Updating until 10:30 PM.',
          'errors': {'code': 'maintenance'},
        }),
      ),
      isA<MaintenanceFailure>(),
    );
    expect(
      mapStaffDioError(
        _answer(403, {
          'message': 'Change your password first.',
          'errors': {'code': 'password_change_required'},
        }),
      ),
      isA<PasswordChangeRequiredFailure>(),
    );
  });

  test('device and sync headers on every request', () {
    DeviceHeaders.deviceId = '0b9c8f6e-1111-4222-8333-944455566677';
    DeviceHeaders.appVersion = '0.4.0';
    DeviceHeaders.syncPending = 3;
    DeviceHeaders.syncFailed = 1;
    DeviceHeaders.lastSync = DateTime.utc(2026, 11, 23, 14);
    expect(DeviceHeaders.headers, {
      'X-Device-Id': '0b9c8f6e-1111-4222-8333-944455566677',
      'X-App-Version': '0.4.0',
      'X-App-Platform': 'mobile',
      'X-Sync-Pending': '3',
      'X-Sync-Failed': '1',
      'X-Last-Sync': '2026-11-23T14:00:00.000Z',
    });
    expect(DeviceHeaders.isValidDeviceId('abc'), isFalse);
    expect(DeviceHeaders.isValidDeviceId('phone:1.a_b-c'), isTrue);
  });

  test('officials see alerts for the city or their own barangay only', () {
    expect(
      alertIsForOfficial({
        'id': 1,
        'target': {'kind': 'city'},
      }, 13),
      isTrue,
    );
    // target_barangay (apps-api-2026-11-24.md 7.5).
    expect(alertIsForOfficial({'id': 1, 'target_barangay': null}, 13), isTrue);
    expect(
      alertIsForOfficial({
        'id': 2,
        'target_barangay': {'id': 13, 'name': 'Binatagan'},
      }, 13),
      isTrue,
    );
    expect(
      alertIsForOfficial({
        'id': 3,
        'target_barangay': {'id': 49, 'name': 'Tomolin'},
      }, 13),
      isFalse,
    );
    expect(
      alertIsForOfficial({'id': 4, 'archived_at': '2026-11-20T00:00:00Z'}, 13),
      isFalse,
    );
  });

  testWidgets('a temporary password: change it before anything else', (
    tester,
  ) async {
    final api = FakeStaffApi();
    const temporary = StaffSession(
      id: 4,
      name: 'Tuburan Barangay Official',
      email: 'brgy.tuburan@e-likasligao.online',
      role: 'barangay_official',
      roleDisplayName: 'Barangay Official',
      barangayId: 13,
      barangayName: 'Tuburan',
      permissions: {'operations.access'},
      mustChangePassword: true,
    );
    await tester.pumpWidget(
      testApp(
        StaffAuthGuard(builder: (_, _) => const Text('Staff home')),
        overrides: [
          ...signedInAs(temporary),
          staffApiClientProvider.overrideWithValue(api),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose your password'), findsOneWidget);
    expect(find.text('Staff home'), findsNothing);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'tuburan-q7K-2mPd-X4a');
    await tester.enterText(fields.at(1), 'short');
    await tester.enterText(fields.at(2), 'short');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(find.text('At least 10 characters.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'a-much-longer-one');
    await tester.enterText(fields.at(2), 'a-much-longer-one');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /auth/password'));
    expect(api.bodies.last, {
      'current_password': 'tuburan-q7K-2mPd-X4a',
      'password': 'a-much-longer-one',
      'password_confirmation': 'a-much-longer-one',
    });
    expect(find.text('Staff home'), findsOneWidget);
  });

  testWidgets('Report a problem sends what happened, the screen and source', (
    tester,
  ) async {
    final api = FakeStaffApi();
    await tester.pumpWidget(
      testApp(
        const ReportProblemPage(),
        overrides: [
          ...signedInAs(official),
          staffApiClientProvider.overrideWithValue(api),
          connectivityServiceProvider.overrideWithValue(
            ConnectivityService.forTesting(
              hasInterface: () async => true,
              probe: () async => true,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Do not include evacuees\' names or details in the photo.'),
      findsOneWidget,
    );
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).first,
      'Sync stays at 3 waiting after I came back online.',
    );
    await tester.pump();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /support-requests'));
    final form =
        api.bodies[api.calls.indexOf('POST /support-requests')] as FormData;
    expect(
      {for (final f in form.fields) f.key: f.value},
      {
        'what_happened': 'Sync stays at 3 waiting after I came back online.',
        'page': 'Home',
        'source': 'mobile',
      },
    );
  });
}
