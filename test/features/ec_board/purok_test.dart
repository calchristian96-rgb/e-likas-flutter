import 'package:drift/native.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/ec_board_entry_draft.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/family_here.dart';
import 'package:elikas_mobile/features/puroks/puroks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_staff_api.dart';

EcBoardEntryDraft _newHousehold({int? purokId}) => EcBoardEntryDraft(
  evacuationCenterId: 71,
  evacuationEventId: 24,
  sex: 'female',
  ageBracket: AgeBracket.values.first,
  householdMode: HouseholdMode.new_,
  newHouseholdHeadName: 'Ana Reyes',
  newHouseholdBarangayId: 13,
  purokId: purokId,
);

void main() {
  test('quick add sends purok_id for a new household only when chosen', () {
    expect(_newHousehold(purokId: 7).toJson()['purok_id'], 7);
    expect(_newHousehold().toJson().containsKey('purok_id'), isFalse);
    // Changing the barangay clears the purok (it belongs to one barangay).
    final changed = _newHousehold(
      purokId: 7,
    ).copyWith(newHouseholdBarangayId: 14, purokId: (value: null));
    expect(changed.purokId, isNull);
  });

  test('families here read their purok', () {
    final f = FamilyHere.fromJson({
      'id': 548,
      'name': 'Fe Flor',
      'member_count': 2,
      'head_of_family': {'full_name': 'Fe Flor'},
      'barangay': {'id': 13, 'name': 'Binatagan'},
      'purok': {'id': 7, 'name': 'Purok 1'},
    });
    expect(f.purokName, 'Purok 1');
  });

  test('puroks are cached per barangay and read back offline', () async {
    final db = StaffDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);
    final api = FakeStaffApi()
      ..getBodies['GET /puroks'] = {
        'success': true,
        'data': [
          {'id': 7, 'barangay_id': 13, 'name': 'Purok 1', 'families_count': 3},
          {'id': 8, 'barangay_id': 13, 'name': 'Purok 2', 'families_count': 0},
        ],
      };
    var online = true;
    final repo = PuroksRepository(
      api,
      db,
      ConnectivityService.forTesting(
        hasInterface: () async => online,
        probe: () async => online,
        resultCacheTtl: Duration.zero,
      ),
    );
    expect((await repo.forBarangay(13)).map((p) => p.name), [
      'Purok 1',
      'Purok 2',
    ]);
    online = false;
    expect((await repo.forBarangay(13)).map((p) => p.id), [7, 8]);
    expect(await repo.forBarangay(14), isEmpty);
  });
}
