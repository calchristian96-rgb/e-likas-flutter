import 'dart:async';
import 'dart:io';

import 'package:elikas_mobile/features/app_update/data/apk_downloader.dart';
import 'package:elikas_mobile/features/app_update/data/apk_installer.dart';
import 'package:elikas_mobile/features/app_update/data/apk_update_service.dart';
import 'package:elikas_mobile/features/app_update/domain/app_update_manifest.dart';
import 'package:elikas_mobile/features/app_update/domain/update_decision.dart';
import 'package:elikas_mobile/features/app_update/presentation/providers/app_update_providers.dart';
import 'package:elikas_mobile/features/app_update/presentation/widgets/update_download_dialog.dart';
import 'package:elikas_mobile/features/app_update/presentation/widgets/update_offer_dialog.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

final _manifest = AppUpdateManifest(
  latestBuild: 3,
  latestVersion: '0.2.0',
  apkUrl: Uri.parse('https://e-likasligao.online/downloads/E-LIKAS-Mobile.apk'),
  sizeBytes: 50 * 1024 * 1024,
  notes: const {'en': 'Bug fixes', 'fil': 'Mga ayos'},
);

Widget _host(Widget child, {Locale locale = const Locale('en')}) =>
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

var _overrides = <Override>[];

Widget _offer(
  UpdateKind kind, {
  String languageCode = 'en',
  VoidCallback? onLater,
  VoidCallback? onUpdateNow,
}) => UpdateOfferDialog(
  manifest: _manifest,
  kind: kind,
  languageCode: languageCode,
  onLater: onLater ?? () {},
  onUpdateNow: onUpdateNow ?? () {},
);

void main() {
  setUp(() => _overrides = []);

  group('offer dialog', () {
    testWidgets('optional: version, size, Wi-Fi hint, notes, both buttons', (
      tester,
    ) async {
      var later = 0;
      var update = 0;
      await tester.pumpWidget(
        _host(
          _offer(
            UpdateKind.optional,
            onLater: () => later++,
            onUpdateNow: () => update++,
          ),
        ),
      );
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Version 0.2.0 is ready'), findsOneWidget);
      expect(find.text('50 MB · Wi-Fi recommended'), findsOneWidget);
      expect(find.text('Bug fixes'), findsOneWidget);
      expect(find.textContaining('out of date'), findsNothing);

      await tester.tap(find.text('Later'));
      await tester.tap(find.text('Update now'));
      expect([later, update], [1, 1]);
    });

    testWidgets('required: required wording, Later still available', (
      tester,
    ) async {
      var later = 0;
      await tester.pumpWidget(
        _host(_offer(UpdateKind.required, onLater: () => later++)),
      );
      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('Update available'), findsNothing);
      expect(find.textContaining('out of date'), findsOneWidget);
      expect(find.text('Update now'), findsOneWidget);

      await tester.tap(find.text('Later'));
      expect(later, 1);
    });

    testWidgets('notes follow the locale, falling back to English', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_offer(UpdateKind.optional, languageCode: 'fil')),
      );
      expect(find.text('Mga ayos'), findsOneWidget);
      expect(find.text('Bug fixes'), findsNothing);

      await tester.pumpWidget(
        _host(_offer(UpdateKind.optional, languageCode: 'bcl')),
      );
      await tester.pump();
      expect(find.text('Bug fixes'), findsOneWidget);
    });

    testWidgets('no size in the manifest: Wi-Fi hint only', (tester) async {
      await tester.pumpWidget(
        _host(
          UpdateOfferDialog(
            manifest: AppUpdateManifest(
              latestBuild: 3,
              apkUrl: _manifest.apkUrl,
            ),
            kind: UpdateKind.optional,
            languageCode: 'en',
            onLater: () {},
            onUpdateNow: () {},
          ),
        ),
      );
      expect(find.text('Version 3 is ready'), findsOneWidget);
      expect(find.text('Wi-Fi recommended'), findsOneWidget);
    });
  });

  group('download dialog', () {
    testWidgets('failure offers Try again and Open in browser', (tester) async {
      final opened = <Uri>[];
      final service = _FakeService(failures: 1000);
      _overrides = [
        apkUpdateServiceProvider.overrideWithValue(service),
        apkInstallerProvider.overrideWithValue(_FakeInstaller()),
        externalUrlOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ];
      await tester.pumpWidget(_host(UpdateDownloadDialog(manifest: _manifest)));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(UpdateDownloadDialog)),
      );
      await container
          .read(updateDownloadControllerProvider.notifier)
          .start(_manifest);
      await tester.pump();

      expect(find.text('Update failed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Open in browser'), findsOneWidget);

      await tester.tap(find.text('Open in browser'));
      expect(opened, [_manifest.apkUrl]);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(service.calls, 2);
    });

    testWidgets('success hands the verified file to the installer', (
      tester,
    ) async {
      final installer = _FakeInstaller();
      _overrides = [
        apkUpdateServiceProvider.overrideWithValue(_FakeService(failures: 0)),
        apkInstallerProvider.overrideWithValue(installer),
      ];
      await tester.pumpWidget(_host(UpdateDownloadDialog(manifest: _manifest)));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(UpdateDownloadDialog)),
      );
      await container
          .read(updateDownloadControllerProvider.notifier)
          .start(_manifest);
      await tester.pump();

      expect(installer.installs, 1);
      expect(find.textContaining('Opening the installer'), findsOneWidget);
      await tester.tap(find.text('Install'));
      await tester.pump();
      expect(installer.installs, 2);
    });

    testWidgets('while downloading: determinate bar and Cancel', (
      tester,
    ) async {
      _overrides = [
        apkUpdateServiceProvider.overrideWithValue(_FakeService(hang: true)),
        apkInstallerProvider.overrideWithValue(_FakeInstaller()),
      ];
      await tester.pumpWidget(_host(UpdateDownloadDialog(manifest: _manifest)));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(UpdateDownloadDialog)),
      );
      container
          .read(updateDownloadControllerProvider.notifier)
          .start(_manifest);
      await tester.pump();

      expect(find.text('Downloading update…'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.4, 0.001));
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

class _FakeService extends ApkUpdateService {
  _FakeService({this.failures = 0, this.hang = false})
    : super(
        downloader: _NoDownloader(),
        workDirectory: () async => Directory.systemTemp,
      );

  final int failures;
  final bool hang;
  int calls = 0;

  @override
  Future<File> downloadVerified(
    AppUpdateManifest manifest, {
    required void Function(int received, int total) onProgress,
    required void Function() onVerifying,
    required DownloadCancellation cancellation,
  }) async {
    calls++;
    if (hang) {
      onProgress(40, 100);
      return Completer<File>().future;
    }
    if (calls <= failures) {
      throw const UpdateDownloadException('boom');
    }
    return File('fake.apk');
  }
}

class _NoDownloader implements ApkDownloader {
  @override
  Future<void> download(
    Uri url,
    File destination, {
    required void Function(int received, int total) onProgress,
    required DownloadCancellation cancellation,
  }) async {}
}

class _FakeInstaller implements ApkInstaller {
  int installs = 0;

  @override
  Future<bool> install(File apk) async {
    installs++;
    return true;
  }
}
