import 'package:dio/dio.dart';
import 'package:elikas_mobile/core/error/failure.dart';
import 'package:elikas_mobile/core/network/staff_api_error_mapper.dart';
import 'package:elikas_mobile/core/utils/formatters.dart';
import 'package:elikas_mobile/core/widgets/lock_note.dart';
import 'package:elikas_mobile/core/widgets/stat_strip.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/widgets/capacity_text.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/widgets/center_status_display.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:elikas_mobile/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DioException refused(String message, {Map<String, dynamic>? errors}) =>
    DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 422,
        data: {'message': message, 'errors': ?errors},
      ),
    );

void main() {
  final l10n = AppLocalizationsEn();

  group('422 lock answers', () {
    test(
      'monitored, closed and no-event are locks, with the message as it comes',
      () {
        final monitored = mapStaffDioError(
          refused(
            '"Incoming Typhoon" is being monitored. Relief rounds opens when CSWD starts the evacuation.',
            errors: {
              'evacuation_event_id': ['…'],
            },
          ),
        );
        expect(monitored, isA<EventLockFailure>());
        expect((monitored as EventLockFailure).kind, EventLockKind.monitored);
        expect(monitored.message, startsWith('"Incoming Typhoon" is being'));

        final closed = mapStaffDioError(
          refused('"Uwan" is closed. A closed event is read-only.'),
        );
        expect((closed as EventLockFailure).kind, EventLockKind.closed);

        final none = mapStaffDioError(
          refused(
            'No open event yet. CSWDO opens an event when a threat is announced.',
          ),
        );
        expect((none as EventLockFailure).kind, EventLockKind.noEvent);
      },
    );

    test('an ordinary 422 stays a validation failure', () {
      final f = mapStaffDioError(
        refused(
          'Say why.',
          errors: {
            'reason': ['Say why.'],
          },
        ),
      );
      expect(f, isA<ValidationFailure>());
      expect(f, isNot(isA<EventLockFailure>()));
    });

    testWidgets('the lock snack bar carries the lock icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  failureSnackBar(
                    const EventLockFailure({}, 'X is being monitored.'),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('X is being monitored.'), findsOneWidget);
    });
  });

  group('formats', () {
    test('thousands separators', () {
      expect(formatCount(1669), '1,669');
      expect(formatCount(null), '–');
      expect(formatStatValue('12345'), '12,345');
      expect(formatStatValue('–'), '–');
      expect(l10n.countPersons(1669), '1,669 persons');
      expect(l10n.countFamilies(1), '1 family');
    });

    test('durations in the largest whole unit, singular and plural', () {
      expect(formatDuration(l10n, const Duration(days: 3, hours: 5)), '3 days');
      expect(formatDuration(l10n, const Duration(hours: 1)), '1 hour');
      expect(formatDuration(l10n, const Duration(minutes: 2)), '2 minutes');
      expect(
        formatDuration(l10n, const Duration(seconds: 20)),
        'less than a minute',
      );
    });

    test('dates as "Nov 19, 1:44 AM" in Manila time', () {
      expect(
        formatShortDateTime(DateTime.utc(2026, 11, 18, 17, 44)),
        'Nov 19, 1:44 AM',
      );
    });

    test('capacity figures use separators', () {
      expect(
        capacityFigure(
          l10n,
          capacity: 1200,
          source: 'official',
          occupancy: 1050,
        ),
        '1,050 / 1,200',
      );
    });
  });

  testWidgets('nearly_full has its own label and colour', (tester) async {
    late String label;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            label = localizedCenterStatus(context, 'nearly_full');
            return const SizedBox();
          },
        ),
      ),
    );
    expect(label, 'Nearly full');
    expect(
      centerStatusColorOf('nearly_full'),
      isNot(centerStatusColorOf('full')),
    );
  });
}
