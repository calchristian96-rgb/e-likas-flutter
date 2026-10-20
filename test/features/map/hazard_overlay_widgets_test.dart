import 'package:elikas_mobile/features/map/presentation/widgets/hazard_overlay_layer.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  const failedText =
      'Flood susceptibility could not be loaded from GeoRiskPH right now. '
      'Switch it off and on to retry.';

  testWidgets('section: switches, notes only when on, failure line', (
    tester,
  ) async {
    final failed = ValueNotifier<Set<String>>(const {});
    final toggled = <String>[];
    await tester.pumpWidget(
      _host(
        HazardOverlaySection(
          activeIds: const {'flood'},
          failedIds: failed,
          onChanged: (o, v) => toggled.add('${o.id}:$v'),
        ),
      ),
    );

    expect(find.text('Hazard susceptibility (MGB)'), findsOneWidget);
    expect(find.text('Flood susceptibility'), findsOneWidget);
    expect(find.text('Rain-induced landslide susceptibility'), findsOneWidget);
    expect(find.textContaining('not a flood forecast'), findsOneWidget);
    expect(find.textContaining('not a landslide forecast'), findsNothing);
    expect(find.textContaining('saved for offline use'), findsOneWidget);
    expect(find.text(failedText), findsNothing);

    failed.value = {'flood'};
    await tester.pump();
    expect(find.text(failedText), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    expect(toggled, ['landslide:true']);
  });

  testWidgets('legend: only active overlays, verbatim class labels', (
    tester,
  ) async {
    final failed = ValueNotifier<Set<String>>(const {});
    await tester.pumpWidget(
      _host(
        HazardOverlayLegendSections(
          activeIds: const {'landslide'},
          failedIds: failed,
        ),
      ),
    );
    expect(find.text('Rain-induced landslide susceptibility'), findsOneWidget);
    expect(find.text('Debris Flow/Possible Accumulation Zone'), findsOneWidget);
    expect(find.text('Very High Susceptibility'), findsOneWidget);
    expect(find.text('Flood susceptibility'), findsNothing);

    await tester.pumpWidget(
      _host(
        HazardOverlayLegendSections(activeIds: const {}, failedIds: failed),
      ),
    );
    expect(find.byType(Text), findsNothing);
  });
}
