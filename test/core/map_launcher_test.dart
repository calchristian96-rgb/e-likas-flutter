import 'package:elikas_mobile/core/utils/map_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a center with no location is searched by name, barangay and city', () {
    expect(
      centerPlaceQuery('LWCES (B)', 'Binatagan'),
      'LWCES (B), Binatagan, Ligao City, Albay',
    );
    expect(centerPlaceQuery('Gym', null), 'Gym, Ligao City, Albay');
  });
}
