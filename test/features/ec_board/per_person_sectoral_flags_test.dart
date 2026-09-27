import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/ec_board/data/datasources/ec_board_local_datasource.dart';
import 'package:elikas_mobile/features/ec_board/data/models/pending_ec_board_entry_model.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/ec_board_entry_draft.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/per_person_sectoral_flag.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/sectoral_group.dart';

PendingEcBoardEntryModel _model(
  String localId, {
  Set<String> flags = const {},
}) => PendingEcBoardEntryModel(
  localId: localId,
  evacuationCenterId: 1,
  evacuationEventId: 7,
  sex: 'female',
  ageBracket: 'adult',
  householdMode: 'existing',
  existingFamilyRemoteId: 42,
  householdLabel: 'Santos household',
  syncStatus: 'pending',
  createdAtEpochMs: 1,
  updatedAtEpochMs: 1,
  ownerStaffId: 1,
  sectoralFlags: flags,
);

void main() {
  group('PerPersonSectoralFlag', () {
    test('wire values are exactly the backend evacuees columns', () {
      expect(PerPersonSectoralFlag.values.map((f) => f.wireValue).toList(), [
        'is_pwd',
        'is_pregnant',
        'is_lactating',
        'is_solo_parent',
        'is_indigenous_person',
        'is_4ps_beneficiary',
      ]);
    });

    test(
      'each maps to its EC Board sectoral group; the two family-level groups have none',
      () {
        final mapped = PerPersonSectoralFlag.values
            .map((f) => f.sectoralGroup)
            .toSet();
        expect(mapped, hasLength(6));
        expect(mapped, isNot(contains(SectoralGroup.childHeadedFamily)));
        expect(mapped, isNot(contains(SectoralGroup.singleHeadedFamily)));
      },
    );

    test('only pregnant and lactating are female-only', () {
      expect(PerPersonSectoralFlag.values.where((f) => f.femaleOnly).toSet(), {
        PerPersonSectoralFlag.pregnant,
        PerPersonSectoralFlag.lactating,
      });
    });
  });

  group('EcBoardEntryDraft.toJson', () {
    const base = EcBoardEntryDraft(
      evacuationCenterId: 1,
      evacuationEventId: 7,
      sex: 'female',
      ageBracket: AgeBracket.adult,
      householdMode: HouseholdMode.existing,
      existingFamilyRemoteId: 42,
    );

    test(
      'sends only ticked flags, as true; unticked ones are left out entirely',
      () {
        final json = base
            .copyWith(
              sectoralFlags: {
                PerPersonSectoralFlag.pregnant,
                PerPersonSectoralFlag.fourPsBeneficiary,
              },
            )
            .toJson();

        expect(json['is_pregnant'], isTrue);
        expect(json['is_4ps_beneficiary'], isTrue);
        for (final key in [
          'is_pwd',
          'is_lactating',
          'is_solo_parent',
          'is_indigenous_person',
        ]) {
          expect(
            json.containsKey(key),
            isFalse,
            reason: '$key was never ticked',
          );
        }
        // The rest of the payload is unchanged.
        expect(json['household_mode'], 'existing');
        expect(json['family_id'], 42);
      },
    );

    test('no flags ticked sends no flag keys at all', () {
      final json = base.toJson();
      for (final flag in PerPersonSectoralFlag.values) {
        expect(json.containsKey(flag.wireValue), isFalse);
      }
    });
  });

  group('offline queue storage (Drift)', () {
    test(
      'ticked flags round-trip; unticked ones are stored as NULL, never false',
      () async {
        final db = StaffDatabase.forExecutor(NativeDatabase.memory());
        addTearDown(db.close);
        final local = EcBoardLocalDataSource(db);

        await local.put(_model('a', flags: {'is_pwd', 'is_lactating'}));
        final back = await local.getByLocalId('a');
        expect(back!.sectoralFlags, {'is_pwd', 'is_lactating'});

        final raw = await db
            .customSelect(
              'SELECT is_pwd, is_pregnant, is_lactating, is_solo_parent, '
              'is_indigenous_person, is_four_ps_beneficiary '
              "FROM pending_ec_board_entries WHERE local_id = 'a'",
            )
            .getSingle();
        expect(raw.data['is_pwd'], 1);
        expect(raw.data['is_lactating'], 1);
        for (final column in [
          'is_pregnant',
          'is_solo_parent',
          'is_indigenous_person',
          'is_four_ps_beneficiary',
        ]) {
          expect(raw.data[column], isNull, reason: '$column was never ticked');
        }
      },
    );

    test(
      'upgrading a schema-4 device keeps its already-queued entries, with no flags or head answers recorded',
      () async {
        final db = StaffDatabase.forExecutor(
          NativeDatabase.memory(
            setup: (raw) {
              // pending_ec_board_entries exactly as schema 4 created it
              // (before the six flag columns), with one entry already queued.
              raw.execute('''
              CREATE TABLE pending_ec_board_entries (
                local_id TEXT NOT NULL, evacuation_center_id INTEGER NOT NULL,
                evacuation_event_id INTEGER NOT NULL, sex TEXT NOT NULL,
                age_bracket TEXT NOT NULL, household_mode TEXT NOT NULL,
                existing_family_remote_id INTEGER NULL, existing_family_local_id TEXT NULL,
                new_household_head_name TEXT NULL, new_household_barangay_id INTEGER NULL,
                household_label TEXT NOT NULL, sync_status TEXT NOT NULL,
                attempt_count INTEGER NOT NULL DEFAULT 0, last_attempt_at_epoch_ms INTEGER NULL,
                last_error_category TEXT NULL, last_error_message TEXT NULL,
                created_at_epoch_ms INTEGER NOT NULL, updated_at_epoch_ms INTEGER NOT NULL,
                owner_staff_id INTEGER NULL, PRIMARY KEY (local_id))
            ''');
              raw.execute('''
              INSERT INTO pending_ec_board_entries (local_id, evacuation_center_id,
                evacuation_event_id, sex, age_bracket, household_mode, existing_family_remote_id,
                household_label, sync_status, created_at_epoch_ms, updated_at_epoch_ms, owner_staff_id)
              VALUES ('old', 1, 7, 'male', 'adult', 'existing', 42, 'Cruz household', 'pending', 1, 1, 1)
            ''');
              raw.execute('PRAGMA user_version = 4');
            },
          ),
        );
        addTearDown(db.close);
        final local = EcBoardLocalDataSource(db);

        final old = await local.getByLocalId('old');
        expect(
          old,
          isNotNull,
          reason: 'the already-queued entry survived the upgrade',
        );
        expect(old!.householdLabel, 'Cruz household');
        expect(old.sectoralFlags, isEmpty);
        expect(old.head, noHeadAnswers);

        // And the upgraded table accepts flags from now on.
        await local.put(_model('new', flags: {'is_pregnant'}));
        expect((await local.getByLocalId('new'))!.sectoralFlags, {
          'is_pregnant',
        });
        expect(
          await db
              .customSelect('PRAGMA user_version')
              .getSingle()
              .then((r) => r.data['user_version']),
          6,
        );
      },
    );
  });
}
