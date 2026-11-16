import 'dart:io';

import 'package:elikas_mobile/features/barangay_status/data/barangay_outlines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled outline file has the 55 barangays, keyed by psgc', () {
    final outlines = parseBarangayOutlines(
      File(barangayOutlinesAsset).readAsStringSync(),
    );
    expect(outlines.map((o) => o.psgcCode).toSet(), hasLength(55));
    final abella = outlines.firstWhere((o) => o.psgcCode == '050508001');
    expect(abella.name, 'Abella');
    // [lng, lat] in GeoJSON: Ligao is near 13.2 N, 123.5 E.
    final p = abella.rings.first.first;
    expect(p.latitude, inInclusiveRange(12.9, 13.4));
    expect(p.longitude, inInclusiveRange(123.3, 123.7));
  });
}
