import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/ec_board/data/datasources/ec_board_local_datasource.dart';
import 'package:elikas_mobile/features/ec_board/data/models/pending_ec_board_entry_model.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/age_bracket.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/ec_board_entry_draft.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/pending_ec_board_entry.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/per_person_sectoral_flag.dart';
import 'package:elikas_mobile/features/ec_board/domain/entities/sectoral_group.dart';
import 'package:elikas_mobile/features/family_registration/domain/entities/pending_registration_status.dart';

const _newHousehold = EcBoardEntryDraft(
  evacuationCenterId: 27,
  evacuationEventId: 7,
  sex: 'female',
  ageBracket: AgeBracket.adult,
  householdMode: HouseholdMode.new_,
  newHouseholdHeadName: 'Maria Santos',
  newHouseholdBarangayId: 13,
  headIsSelf: true,
);

const _existing = EcBoardEntryDraft(
  evacuationCenterId: 27,
  evacuationEventId: 7,
  sex: 'male',
  ageBracket: AgeBracket.teenage,
  householdMode: HouseholdMode.existing,
  existingFamilyRemoteId: 454,
);

PendingEcBoardEntrySummary _summary(EcBoardEntryDraft d) =>
    PendingEcBoardEntrySummary(
      localId: 'x',
      evacuationCenterId: 27,
      evacuationEventId: 7,
      status: PendingRegistrationStatus.pending,
      sex: d.sex!,
      ageBracket: d.ageBracket,
      householdLabel: 'h',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      sectoralFlags: d.sectoralFlags,
      headIsSelf: d.headIsSelf,
      createsChildHeadedHousehold: d.createsChildHeadedHousehold,
      createsSingleHeadedHousehold: d.createsSingleHeadedHousehold,
      newHouseholdHeadSex: d.newHouseholdHeadSex,
    );

void main() {
  // Every body below is exactly what the web dashboard's Add evacuee
  // sends for the same answers (confirmed against addEvacuee()'s
  // validation on the local backend).
  group('toJson — household head answers', () {
    test('new household, this person is the head: head_is_self, single-'
        'headed answer, and no head_sex/head_is_minor at all', () {
      final json = _newHousehold
          .copyWith(isSingleHeaded: (value: true))
          .toJson();
      expect(json['household_mode'], 'new');
      expect(json['head_is_self'], isTrue);
      expect(json['is_single_headed'], isTrue);
      expect(json.containsKey('head_sex'), isFalse);
      expect(json.containsKey('head_is_minor'), isFalse);
    });

    test('new household, someone else heads it: their sex and minor '
        'answers, each null when not yet known', () {
      final json = _newHousehold
          .copyWith(
            headIsSelf: false,
            headSex: (value: 'male'),
            headIsMinor: (value: null),
          )
          .toJson();
      expect(json['head_is_self'], isFalse);
      expect(json['head_sex'], 'male');
      expect(json.containsKey('head_is_minor'), isTrue);
      expect(json['head_is_minor'], isNull);
      // "Not yet known" is sent as null, never a guessed false.
      expect(json.containsKey('is_single_headed'), isTrue);
      expect(json['is_single_headed'], isNull);
    });

    test('already here: head_is_self only when linking the late head, and '
        'never any new-household answers', () {
      final linking = _existing.copyWith(headIsSelf: true).toJson();
      expect(linking['family_id'], 454);
      expect(linking['head_is_self'], isTrue);
      for (final key in ['is_single_headed', 'head_sex', 'head_is_minor']) {
        expect(linking.containsKey(key), isFalse, reason: key);
      }
      expect(_existing.toJson().containsKey('head_is_self'), isFalse);
    });
  });

  group("the server's household rule (Family::isChildHeaded etc.)", () {
    test('this person as head: their own sex and age group answer it', () {
      final child = _newHousehold.copyWith(
        sex: 'male',
        ageBracket: AgeBracket.teenage,
      );
      expect(child.createsChildHeadedHousehold, isTrue);
      expect(child.newHouseholdHeadSex, 'male');
      expect(_newHousehold.createsChildHeadedHousehold, isFalse);
    });

    test('someone else as head: only a known "yes" counts', () {
      final other = _newHousehold.copyWith(headIsSelf: false);
      expect(other.createsChildHeadedHousehold, isFalse);
      expect(other.newHouseholdHeadSex, isNull);
      final minor = other.copyWith(
        headIsMinor: (value: true),
        headSex: (value: 'female'),
      );
      expect(minor.createsChildHeadedHousehold, isTrue);
      expect(minor.newHouseholdHeadSex, 'female');
    });

    test('an existing household never counts — its answers were given when '
        'it was created', () {
      final e = _existing.copyWith(headIsSelf: true);
      expect(e.createsChildHeadedHousehold, isFalse);
      expect(e.createsSingleHeadedHousehold, isFalse);
      expect(e.newHouseholdHeadSex, isNull);
    });
  });

  group('countPendingSectoral', () {
    test('flags per person by their sex; child-/single-headed once per new '
        'household by the head\'s sex; all 8 rows zero-filled', () {
      final counts = countPendingSectoral([
        _summary(
          _newHousehold.copyWith(
            isSingleHeaded: (value: true),
            sectoralFlags: {PerPersonSectoralFlag.soloParent},
          ),
        ),
        _summary(
          _newHousehold.copyWith(
            headIsSelf: false,
            headSex: (value: 'male'),
            headIsMinor: (value: true),
            isSingleHeaded: (value: true),
          ),
        ),
        // Head's sex unknown: counted in neither column, like the server.
        _summary(
          _newHousehold.copyWith(
            headIsSelf: false,
            isSingleHeaded: (value: true),
          ),
        ),
        _summary(
          _existing.copyWith(
            headIsSelf: true,
            sectoralFlags: {PerPersonSectoralFlag.pwd},
          ),
        ),
      ]);

      expect(counts, hasLength(SectoralGroup.values.length));
      expect(counts[SectoralGroup.soloParent], (male: 0, female: 1));
      expect(counts[SectoralGroup.pwd], (male: 1, female: 0));
      expect(counts[SectoralGroup.singleHeadedFamily], (male: 1, female: 1));
      expect(counts[SectoralGroup.childHeadedFamily], (male: 1, female: 0));
      expect(counts[SectoralGroup.indigenousPeoples], (male: 0, female: 0));
    });
  });

  group('offline queue storage (Drift)', () {
    PendingEcBoardEntryModel model(String id, HeadAnswers head) =>
        PendingEcBoardEntryModel(
          localId: id,
          evacuationCenterId: 27,
          evacuationEventId: 7,
          sex: 'female',
          ageBracket: 'adult',
          householdMode: 'new',
          newHouseholdHeadName: 'Maria Santos',
          newHouseholdBarangayId: 13,
          householdLabel: 'Maria Santos',
          syncStatus: 'pending',
          createdAtEpochMs: 1,
          updatedAtEpochMs: 1,
          ownerStaffId: 1,
          head: head,
        );

    test('head answers round-trip, and "not yet known" stays NULL', () async {
      final db = StaffDatabase.forExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      final local = EcBoardLocalDataSource(db);

      const head = (
        headIsSelf: false,
        isSingleHeaded: null,
        headIsMinor: true,
        headSex: 'male',
      );
      await local.put(model('a', head));
      expect((await local.getByLocalId('a'))!.head, head);

      final raw = await db
          .customSelect(
            'SELECT is_single_headed FROM pending_ec_board_entries '
            "WHERE local_id = 'a'",
          )
          .getSingle();
      expect(raw.data['is_single_headed'], isNull);
    });

    test('upgrading the in-development schema 5 adds the head columns, '
        'keeps queued entries, and drops the typed-figures queue', () async {
      final db = StaffDatabase.forExecutor(
        NativeDatabase.memory(
          setup: (raw) {
            // Schema 5 as the in-development build created it: the six
            // flag columns, no head columns, and the retired queue.
            raw.execute('''
              CREATE TABLE pending_ec_board_entries (
                local_id TEXT NOT NULL, evacuation_center_id INTEGER NOT NULL,
                evacuation_event_id INTEGER NOT NULL, sex TEXT NOT NULL,
                age_bracket TEXT NOT NULL,
                is_pwd INTEGER NULL, is_pregnant INTEGER NULL,
                is_lactating INTEGER NULL, is_solo_parent INTEGER NULL,
                is_indigenous_person INTEGER NULL,
                is_four_ps_beneficiary INTEGER NULL,
                household_mode TEXT NOT NULL,
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
                evacuation_event_id, sex, age_bracket, is_pwd, household_mode,
                new_household_head_name, new_household_barangay_id,
                household_label, sync_status, created_at_epoch_ms, updated_at_epoch_ms, owner_staff_id)
              VALUES ('old', 27, 7, 'female', 'adult', 1, 'new', 'Cruz', 13,
                'Cruz', 'pending', 1, 1, 1)
            ''');
            raw.execute(
              'CREATE TABLE pending_quick_count_edits (x INTEGER NOT NULL)',
            );
            raw.execute('PRAGMA user_version = 5');
          },
        ),
      );
      addTearDown(db.close);
      final local = EcBoardLocalDataSource(db);

      final old = await local.getByLocalId('old');
      expect(old!.sectoralFlags, {'is_pwd'});
      expect(old.head, noHeadAnswers);

      await local.put(
        model('new', (
          headIsSelf: true,
          isSingleHeaded: true,
          headIsMinor: null,
          headSex: null,
        )),
      );
      expect((await local.getByLocalId('new'))!.head.isSingleHeaded, isTrue);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'pending_quick_count_edits'",
          )
          .get();
      expect(tables, isEmpty);
      expect(
        await db
            .customSelect('PRAGMA user_version')
            .getSingle()
            .then((r) => r.data['user_version']),
        6,
      );
    });
  });
}
