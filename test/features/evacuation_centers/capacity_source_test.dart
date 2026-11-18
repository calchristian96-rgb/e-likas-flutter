import 'package:elikas_mobile/features/evacuation_centers/data/models/evacuation_center_model.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/widgets/capacity_text.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(int? capacity, String source, {int occ = 48}) => {
  'id': 71,
  'name': 'LWCES (B)',
  'type': 'school',
  'capacity_persons': capacity,
  'current_occupancy': occ,
  'occupancy_percent': capacity == null ? null : occ * 100 / capacity,
  'status': 'active',
  'capacity_source': source,
};

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('official, estimated, unknown (docs 3.2)', () {
    expect(
      capacityFigure(l10n, capacity: 112, source: 'official', occupancy: 48),
      '48 / 112',
    );
    expect(
      capacityFigure(l10n, capacity: 112, source: 'estimated', occupancy: 48),
      '48 / 112 est.',
    );
    expect(
      capacityFigure(l10n, capacity: null, source: 'unknown', occupancy: 48),
      '48 / – (capacity unknown)',
    );
    // Never 0 or a blank.
    expect(
      capacityFigure(l10n, capacity: 0, occupancy: 3),
      '3 / – (capacity unknown)',
    );
    // The resident wording.
    expect(
      capacityFigure(l10n, capacity: 150, source: 'estimated', resident: true),
      '150 (estimated)',
    );
    expect(
      capacityBasisTooltip(l10n, 'peak_2025'),
      'Estimated from the 2025 peak',
    );
  });

  test('an unknown capacity has no percentage, no free places, never full', () {
    final unknown = EvacuationCenterModel.fromJson(
      _row(null, 'unknown'),
    ).toEntity();
    expect(unknown.capacitySource, 'unknown');
    expect(unknown.isCapacityUnknown, isTrue);
    expect(unknown.hasOccupancyData, isFalse);
    expect(unknown.availableSlots, isNull);
    expect(showsOccupancyPercent(unknown), isFalse);

    final estimated = EvacuationCenterModel.fromJson(
      _row(120, 'estimated'),
    ).toEntity();
    expect(estimated.isCapacityEstimated, isTrue);
    expect(estimated.hasOccupancyData, isTrue);
    expect(estimated.availableSlots, 72);
  });

  test('a later read without the field keeps the saved source', () {
    final saved = EvacuationCenterModel.fromJson(_row(120, 'estimated'));
    final nearest = EvacuationCenterModel.fromJson(
      {..._row(120, 'estimated')}..remove('capacity_source'),
    );
    expect(nearest.mergeOverExisting(saved).capacitySource, 'estimated');
  });
}
