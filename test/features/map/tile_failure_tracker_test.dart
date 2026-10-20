import 'package:elikas_mobile/features/map/presentation/widgets/hazard_overlay_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late TileFailureTracker tracker;

  setUp(() {
    now = DateTime(2026, 1, 1);
    tracker = TileFailureTracker(clock: () => now);
  });

  void errorAfter(int seconds) {
    now = now.add(Duration(seconds: seconds));
    tracker.recordError();
  }

  test('3 errors within 10 s is not failed', () {
    errorAfter(0);
    errorAfter(3);
    errorAfter(3);
    expect(tracker.failed, isFalse);
  });

  test('4 errors within 10 s is failed, reported once on the transition', () {
    errorAfter(0);
    errorAfter(3);
    errorAfter(3);
    now = now.add(const Duration(seconds: 3));
    expect(tracker.recordError(), isTrue);
    expect(tracker.failed, isTrue);
    expect(tracker.recordError(), isFalse);
  });

  test('errors spread so that no 10 s window holds 4 is not failed', () {
    for (var i = 0; i < 8; i++) {
      errorAfter(4);
    }
    expect(tracker.failed, isFalse);
  });

  test('reset clears failure and the error count', () {
    for (var i = 0; i < 4; i++) {
      errorAfter(1);
    }
    expect(tracker.failed, isTrue);
    tracker.reset();
    expect(tracker.failed, isFalse);
    errorAfter(1);
    errorAfter(1);
    errorAfter(1);
    expect(tracker.failed, isFalse);
  });
}
