import 'package:drift/native.dart';
import 'package:elikas_mobile/core/database/staff_database.dart';
import 'package:elikas_mobile/features/family_registration/data/services/staff_sync_service.dart';
import 'package:elikas_mobile/features/family_registration/presentation/providers/pending_queue_provider.dart';
import 'package:elikas_mobile/features/outbox/data/outbox_repository.dart';
import 'package:elikas_mobile/features/staff_auth/presentation/providers/staff_auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/connectivity/connectivity_service.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/error/result.dart';
import 'package:elikas_mobile/features/outbox/data/sent_family_api.dart';
import 'package:elikas_mobile/features/outbox/domain/pending_action.dart';
import 'package:elikas_mobile/features/outbox/domain/sent_family.dart';
import 'package:elikas_mobile/features/outbox/domain/sent_record.dart';
import 'package:elikas_mobile/features/outbox/presentation/outbox_providers.dart';
import 'package:elikas_mobile/features/outbox/presentation/sent_family_page.dart';
import 'package:elikas_mobile/features/outbox/presentation/sent_list.dart';
import 'package:elikas_mobile/features/outbox/presentation/sent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_staff_api.dart';
import '../../helpers/fake_staff_auth.dart';

ConnectivityService _connectivity(bool online) =>
    ConnectivityService.forTesting(
      hasInterface: () async => online,
      probe: () async => online,
      resultCacheTtl: Duration.zero,
    );

final _records = [
  SentRecord(
    localId: 'reg-1',
    kind: SentRecordKind.registration,
    summary: 'Juan Reyes',
    memberCount: 4,
    place: 'LWCES (B)',
    eventId: 49,
    serverFamilyId: 548,
    sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  SentRecord(
    localId: 'act-1',
    kind: SentRecordKind.action,
    actionKind: PendingActionKind.boxHandout,
    summary: 'Box for Reyes family',
    eventId: 49,
    sentAt: DateTime.now().subtract(const Duration(minutes: 9)),
  ),
];

/// Answers the edit page's PATCH with [answer].
class _EditApi extends SentFamilyApi {
  _EditApi(this.answer) : super(FakeStaffApi(), _connectivity(true));

  final Result<SentMember> answer;
  Map<String, dynamic>? body;

  @override
  Future<Result<SentMember>> updateMember(
    int evacueeId,
    Map<String, dynamic> body,
  ) async {
    this.body = body;
    return answer;
  }
}

void main() {
  Widget sentApp({
    required bool online,
    List<String>? opened,
    ConnectivityService? connectivity,
  }) => _routerApp(
    const Scaffold(body: SentList()),
    opened: opened,
    overrides: [
      sentRecordsProvider.overrideWith((ref) async => _records),
      connectivityServiceProvider.overrideWithValue(
        connectivity ?? _connectivity(online),
      ),
    ],
  );

  testWidgets(
    'Sent lists what this phone sent: summary, place, time; Edit only on '
    'a registration',
    (tester) async {
      await tester.pumpWidget(sentApp(online: true));
      await tester.pumpAndSettle();
      expect(find.text("Juan Reyes's family, 4 people"), findsOneWidget);
      expect(find.textContaining('LWCES (B) · Sent 5'), findsOneWidget);
      expect(find.text('Box for Reyes family'), findsOneWidget);
      // One Edit: the registration; the box handout is read-only.
      expect(find.text('Edit'), findsOneWidget);
    },
  );

  testWidgets('Edit opens the family on the server when online', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(sentApp(online: true, opened: opened));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(opened, ['/staff/more/sync/sent-family/548']);
    expect(find.text('edit page'), findsOneWidget);
  });

  testWidgets('Edit offline says an internet connection is needed', (
    tester,
  ) async {
    final opened = <String>[];
    final offline = _connectivity(false);
    await tester.pumpWidget(
      sentApp(online: false, opened: opened, connectivity: offline),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(
      find.text('Editing a sent record needs an internet connection.'),
      findsOneWidget,
    );
    // Let the snackbar time out; stop the offline retry timer.
    await tester.pump(const Duration(seconds: 10));
    offline.dispose();
  });

  testWidgets("a person's edit shows the server's 422 under the field", (
    tester,
  ) async {
    final editApi = _EditApi(
      const Failed(
        ValidationFailure({
          'first_name': ['The first name field must be a string.'],
        }, 'The given data was invalid.'),
      ),
    );
    await tester.pumpWidget(
      testApp(
        const MemberEditPage(
          familyId: 548,
          member: SentMember(
            id: 31,
            fullName: 'Ana Reyes',
            firstName: 'Ana',
            lastName: 'Reyes',
            sex: 'female',
          ),
        ),
        overrides: [sentFamilyApiProvider.overrideWithValue(editApi)],
      ),
    );
    await tester.pumpAndSettle();
    // Clear the first name: it is still sent, so the server says why.
    await tester.enterText(find.widgetWithText(TextField, 'Ana'), '');
    final list = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('Save'), 200, scrollable: list);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(editApi.body!.containsKey('first_name'), isTrue);
    expect(editApi.body!['first_name'], isNull);
    expect(editApi.body!['last_name'], 'Reyes');
    await tester.scrollUntilVisible(
      find.text('The given data was invalid.'),
      -200,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    expect(find.text('The given data was invalid.'), findsOneWidget);
    expect(find.text('The first name field must be a string.'), findsOneWidget);
  });

  testWidgets('an automatic send shows "3 records sent"; View opens Sent', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final opened = <String>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _routerApp(
          const Scaffold(body: _AutoSentProbe()),
          opened: opened,
          scoped: false,
        ),
      ),
    );
    container.read(autoSentProvider.notifier).announce(3);
    await tester.pumpAndSettle();
    expect(find.text('3 records sent'), findsOneWidget);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(opened, ['/staff/more/sync?tab=sent']);
  });

  group('the automatic-send announcement', () {
    Future<(ProviderContainer, OutboxRepository)> setUpSync() async {
      SharedPreferences.setMockInitialValues({});
      final db = StaffDatabase.forExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      final outbox = OutboxRepository(
        db,
        FakeStaffApi(),
        _connectivity(true),
        4,
      );
      final container = ProviderContainer(
        overrides: [
          ...signedInAs(official),
          outboxRepositoryProvider.overrideWithValue(outbox),
          staffSyncNowProvider.overrideWithValue(
            () async =>
                const StaffSyncRunResult(processed: 2, stoppedForAuth: false),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(staffAuthProvider.future);
      await outbox.enqueue(
        kind: PendingActionKind.checkOut,
        method: 'POST',
        path: '/evacuees/1/check-out',
        body: const {},
        summary: 'Check-out',
      );
      return (container, outbox);
    }

    test('an automatic send announces what it sent', () async {
      final (container, _) = await setUpSync();
      final result = await container.read(staffSyncAllProvider)();
      expect(result.sent, 3);
      expect(container.read(autoSentProvider)?.count, 3);
    });

    test('Sync now does not (it shows its own message)', () async {
      final (container, _) = await setUpSync();
      await container.read(staffSyncAllProvider)(automatic: false);
      expect(container.read(autoSentProvider), isNull);
    });
  });
}

/// [home] at `/`, and any other location recorded in [opened].
Widget _routerApp(
  Widget home, {
  List<String>? opened,
  List<Override> overrides = const [],
  bool scoped = true,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/staff/more/sync',
        builder: (_, state) {
          opened?.add(state.uri.toString());
          return const Scaffold(body: Text('sync page'));
        },
        routes: [
          GoRoute(
            path: 'sent-family/:id',
            builder: (_, state) {
              opened?.add(state.uri.toString());
              return const Scaffold(body: Text('edit page'));
            },
          ),
        ],
      ),
    ],
  );
  final app = MaterialApp.router(
    routerConfig: router,
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
  return scoped ? ProviderScope(overrides: overrides, child: app) : app;
}

/// Listens like StaffAutoSync does, without its sync side effects.
class _AutoSentProbe extends ConsumerWidget {
  const _AutoSentProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(autoSentProvider, (_, next) {
      if (next == null) return;
      showAutoSentSnackBar(context, next.count);
    });
    return const SizedBox();
  }
}
