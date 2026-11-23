import 'dart:async';
import 'dart:convert';

import 'package:elikas_mobile/core/push/push_service.dart';
import 'package:elikas_mobile/features/barangay_status/data/barangay_status_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBackend implements PushBackend {
  final calls = <String>[];
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  PushMessage? initial;

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return true;
  }

  @override
  Future<void> subscribe(String topic) async => calls.add('+$topic');

  @override
  Future<void> unsubscribe(String topic) async => calls.add('-$topic');

  @override
  Stream<PushMessage> get onForeground => foreground.stream;

  @override
  Stream<PushMessage> get onOpened => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => initial;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('topics come from the API, never built by the app', () {
    final board = BarangayStatusRepository.parse({
      'city_push_topic': 'elikas-city',
      'barangays': [
        {
          'id': 54,
          'name': 'Tula-tula Pequeño',
          'status': 'normal',
          'label': 'Normal',
          'slug': 'tula-tula-pequeno',
          'push_topic': 'elikas-brgy-tula-tula-pequeno',
        },
      ],
    });
    expect(board.cityPushTopic, 'elikas-city');
    expect(board.barangays.single.pushTopic, 'elikas-brgy-tula-tula-pequeno');
  });

  test('every start: the city, the saved barangay, and test when on', () async {
    SharedPreferences.setMockInitialValues({
      PushService.barangayTopicKey: 'elikas-brgy-bay',
      PushService.testTopicKey: true,
    });
    final backend = _FakeBackend();
    await PushService(backend).start();
    expect(backend.calls, [
      'init',
      '+elikas-city',
      '+elikas-brgy-bay',
      '+elikas-test',
    ]);
  });

  test(
    'a new barangay: unsubscribe the old topic first, then subscribe',
    () async {
      final backend = _FakeBackend();
      final push = PushService(backend);
      await push.setBarangayTopic('elikas-brgy-bay');
      await push.setBarangayTopic('elikas-brgy-tomolin');
      await push.setBarangayTopic('elikas-brgy-tomolin');
      expect(backend.calls, [
        '+elikas-brgy-bay',
        '-elikas-brgy-bay',
        '+elikas-brgy-tomolin',
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(PushService.barangayTopicKey),
        'elikas-brgy-tomolin',
      );
    },
  );

  test(
    'the hidden test switch subscribes and unsubscribes elikas-test',
    () async {
      final backend = _FakeBackend();
      final push = PushService(backend);
      await push.setTestTopic(true);
      await push.setTestTopic(false);
      expect(backend.calls, ['+elikas-test', '-elikas-test']);
      expect(await PushService.testTopicOn(), isFalse);
    },
  );

  test(
    'a tapped push opens the matching screen; unknown types nothing',
    () async {
      expect(
        pushTargetOf({'type': 'alert', 'alert_id': '412'}),
        isA<AlertTarget>().having((t) => t.alertId, 'alertId', 412),
      );
      expect(
        pushTargetOf({
          'type': 'evacuation_order',
          'order': 'forced_evacuation',
        }),
        isA<EvacuationOrderTarget>(),
      );
      expect(pushTargetOf({'type': 'test'}), isA<HomeTarget>());
      expect(pushTargetOf({'type': 'something_new'}), isNull);

      final backend = _FakeBackend()
        ..initial = const PushMessage(data: {'type': 'test'});
      final opened = <PushTarget>[];
      final push = PushService(backend)..onOpen = opened.add;
      await push.start();
      backend.opened.add(
        const PushMessage(data: {'type': 'alert', 'alert_id': '7'}),
      );
      await Future<void>.delayed(Duration.zero);
      push.openPayload(jsonEncode({'type': 'evacuation_order'}));
      expect(opened.map((t) => t.runtimeType), [
        HomeTarget,
        AlertTarget,
        EvacuationOrderTarget,
      ]);
    },
  );
}
