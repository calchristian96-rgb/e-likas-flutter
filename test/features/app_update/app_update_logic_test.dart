import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:elikas_mobile/features/app_update/data/apk_downloader.dart';
import 'package:elikas_mobile/features/app_update/data/apk_update_service.dart';
import 'package:elikas_mobile/features/app_update/data/app_update_repository.dart';
import 'package:elikas_mobile/features/app_update/data/update_manifest_source.dart';
import 'package:elikas_mobile/features/app_update/data/update_snooze_store.dart';
import 'package:elikas_mobile/features/app_update/domain/apk_hash.dart';
import 'package:elikas_mobile/features/app_update/domain/app_update_manifest.dart';
import 'package:elikas_mobile/features/app_update/domain/update_decision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _manifestUri = Uri.parse(
  'https://e-likasligao.online/downloads/version.json',
);
const _apk = 'https://e-likasligao.online/downloads/E-LIKAS-Mobile.apk';
final _sha = 'a' * 64;

AppUpdateManifest? _parse(Object? json) =>
    AppUpdateManifest.tryParse(json, manifestUri: _manifestUri);

AppUpdateManifest _manifest({int latest = 3, int? min}) => AppUpdateManifest(
  latestBuild: latest,
  minBuild: min,
  apkUrl: Uri.parse(_apk),
);

void main() {
  group('manifest parsing', () {
    test('full valid manifest', () {
      final m = _parse({
        'latest_build': 3,
        'latest_version': '0.2.0',
        'min_build': 1,
        'apk_url': _apk,
        'sha256': _sha.toUpperCase(),
        'size_bytes': 50000000,
        'notes': {'en': 'English', 'fil': 'Filipino', 'bcl': 'Bikol'},
        'something_new': true,
      })!;
      expect(m.latestBuild, 3);
      expect(m.latestVersion, '0.2.0');
      expect(m.minBuild, 1);
      expect(m.sha256, _sha);
      expect(m.sizeBytes, 50000000);
      expect(m.notesFor('fil'), 'Filipino');
    });

    test('only the mandatory fields are enough', () {
      final m = _parse({'latest_build': 2, 'apk_url': _apk})!;
      expect(m.latestVersion, isNull);
      expect(m.minBuild, isNull);
      expect(m.sha256, isNull);
      expect(m.sizeBytes, isNull);
      expect(m.notesFor('en'), isNull);
    });

    test('junk means no update and never throws', () {
      expect(_parse(null), isNull);
      expect(_parse('not a map'), isNull);
      expect(_parse([1, 2]), isNull);
      expect(_parse(<String, Object>{}), isNull);
      expect(_parse({'latest_build': 'x', 'apk_url': _apk}), isNull);
      expect(_parse({'latest_build': 0, 'apk_url': _apk}), isNull);
      expect(_parse({'latest_build': 2}), isNull);
      expect(_parse({'latest_build': 2, 'apk_url': 42}), isNull);
    });

    test('apk_url must be https and on the manifest host', () {
      expect(
        _parse({
          'latest_build': 2,
          'apk_url': 'http://e-likasligao.online/a.apk',
        }),
        isNull,
      );
      expect(
        _parse({'latest_build': 2, 'apk_url': 'https://evil.example/a.apk'}),
        isNull,
      );
      expect(
        _parse({'latest_build': 2, 'apk_url': '/downloads/a.apk'}),
        isNull,
      );
    });

    test(
      'a malformed sha256 invalidates the manifest, bad cosmetics do not',
      () {
        expect(
          _parse({'latest_build': 2, 'apk_url': _apk, 'sha256': 'abc'}),
          isNull,
        );
        final m = _parse({
          'latest_build': 2,
          'apk_url': _apk,
          'size_bytes': 'big',
          'min_build': -4,
          'latest_version': 7,
        })!;
        expect(m.sizeBytes, isNull);
        expect(m.minBuild, isNull);
        expect(m.latestVersion, isNull);
      },
    );

    test('notes as a plain string, and the locale fallback', () {
      final plain = _parse({
        'latest_build': 2,
        'apk_url': _apk,
        'notes': 'Bug fixes',
      })!;
      expect(plain.notesFor('fil'), 'Bug fixes');

      final map = _parse({
        'latest_build': 2,
        'apk_url': _apk,
        'notes': {'en': 'English', 'fil': 'Filipino', 'bcl': 5},
      })!;
      expect(map.notesFor('fil'), 'Filipino');
      expect(map.notesFor('bcl'), 'English');
    });
  });

  group('build comparison', () {
    test('up to date, optional, required', () {
      expect(decideUpdate(_manifest(latest: 3), 3), UpdateKind.none);
      expect(decideUpdate(_manifest(latest: 3), 4), UpdateKind.none);
      expect(
        decideUpdate(_manifest(latest: 3, min: 1), 2),
        UpdateKind.optional,
      );
      expect(decideUpdate(_manifest(latest: 3), 2), UpdateKind.optional);
      expect(
        decideUpdate(_manifest(latest: 3, min: 2), 1),
        UpdateKind.required,
      );
      expect(decideUpdate(_manifest(latest: 3, min: 3), 3), UpdateKind.none);
    });
  });

  group('snooze logic', () {
    final t0 = DateTime(2026, 10, 20, 8);

    test('same build is hidden for 24 h, then prompts again', () {
      bool snoozed(Duration after, {int build = 3}) => isUpdateSnoozed(
        latestBuild: build,
        snoozedBuild: 3,
        snoozedAt: t0,
        now: t0.add(after),
      );
      expect(snoozed(const Duration(hours: 23, minutes: 59)), isTrue);
      expect(snoozed(const Duration(hours: 24)), isFalse);
      expect(snoozed(const Duration(minutes: 1), build: 4), isFalse);
      expect(snoozed(const Duration(hours: -2)), isFalse);
    });

    test('nothing stored means not snoozed', () {
      expect(
        isUpdateSnoozed(
          latestBuild: 3,
          snoozedBuild: null,
          snoozedAt: null,
          now: t0,
        ),
        isFalse,
      );
    });

    test('store round-trips through shared_preferences', () async {
      SharedPreferences.setMockInitialValues({});
      var now = t0;
      final store = UpdateSnoozeStore(clock: () => now);
      expect(await store.isSnoozed(3), isFalse);
      await store.snooze(3);
      expect(await store.isSnoozed(3), isTrue);
      expect(await store.isSnoozed(4), isFalse);
      now = t0.add(const Duration(hours: 25));
      expect(await store.isSnoozed(3), isFalse);
    });
  });

  group('sha256 helper', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('sha_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('known vector and mismatch', () async {
      final file = File('${dir.path}/abc.bin')..writeAsStringSync('abc');
      const abc =
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
      final actual = await sha256OfFile(file);
      expect(actual, abc);
      expect(sha256Matches(actual, abc.toUpperCase()), isTrue);
      expect(sha256Matches(actual, 'f' * 64), isFalse);
    });
  });

  group('download retry', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('apk_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    ApkUpdateService service(_FakeDownloader d) => ApkUpdateService(
      downloader: d,
      workDirectory: () async => dir,
      retryDelay: Duration.zero,
    );

    AppUpdateManifest manifestFor(String body, {bool sha = true, int? size}) =>
        AppUpdateManifest(
          latestBuild: 3,
          apkUrl: Uri.parse(_apk),
          sha256: sha ? sha256Hex(body) : null,
          sizeBytes: size,
        );

    Future<File> run(
      ApkUpdateService s,
      AppUpdateManifest m, [
      DownloadCancellation? c,
    ]) => s.downloadVerified(
      m,
      onProgress: (_, _) {},
      onVerifying: () {},
      cancellation: c ?? DownloadCancellation(),
    );

    test('first attempt succeeds', () async {
      final d = _FakeDownloader(['good']);
      final file = await run(service(d), manifestFor('good', size: 4));
      expect(file.readAsStringSync(), 'good');
      expect(d.calls, 1);
    });

    test('a corrupted first download is deleted and retried once', () async {
      final d = _FakeDownloader(['go\u0000\u0000', 'good']);
      final file = await run(service(d), manifestFor('good'));
      expect(file.readAsStringSync(), 'good');
      expect(d.calls, 2);
    });

    test('a network error then success', () async {
      final d = _FakeDownloader([const SocketException('reset'), 'good']);
      await run(service(d), manifestFor('good'));
      expect(d.calls, 2);
    });

    test('two failures: throws, leaves no partial file', () async {
      final d = _FakeDownloader(['bad1', const SocketException('reset')]);
      await expectLater(
        run(service(d), manifestFor('good')),
        throwsA(isA<UpdateDownloadException>()),
      );
      expect(d.calls, 2);
      expect(Directory('${dir.path}/app_update').listSync(), isEmpty);
    });

    test('size mismatch fails verification', () async {
      final d = _FakeDownloader(['good', 'good']);
      await expectLater(
        run(service(d), manifestFor('good', size: 99)),
        throwsA(isA<UpdateDownloadException>()),
      );
    });

    test('no sha256 in the manifest skips only the hash check', () async {
      final d = _FakeDownloader(['anything']);
      final file = await run(service(d), manifestFor('x', sha: false));
      expect(file.existsSync(), isTrue);
    });

    test('cancel stops without retrying and deletes the file', () async {
      final cancel = DownloadCancellation();
      final d = _FakeDownloader(['good'], onDownload: cancel.cancel);
      await expectLater(
        run(service(d), manifestFor('good'), cancel),
        throwsA(isA<DownloadCancelledException>()),
      );
      expect(d.calls, 1);
      expect(Directory('${dir.path}/app_update').listSync(), isEmpty);
    });

    test('leftover APKs are deleted on the next start', () async {
      final d = _FakeDownloader(['good']);
      final s = service(d);
      final file = await run(s, manifestFor('good'));
      expect(file.existsSync(), isTrue);
      await s.deleteLeftovers();
      expect(file.existsSync(), isFalse);
    });
  });

  group('update repository', () {
    late Directory dir;
    late DateTime now;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('repo_test');
      now = DateTime(2026, 10, 20, 8);
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() => dir.deleteSync(recursive: true));

    AppUpdateRepository repo(
      AppUpdateManifest? manifest, {
      int build = 1,
      bool supported = true,
      _CountingSource? source,
    }) => AppUpdateRepository(
      source: source ?? _CountingSource(manifest),
      snoozeStore: UpdateSnoozeStore(clock: () => now),
      service: ApkUpdateService(
        downloader: _FakeDownloader([]),
        workDirectory: () async => dir,
      ),
      installedInfo: () async =>
          InstalledAppInfo(version: '0.1.0', build: build),
      isSupported: supported,
      clock: () => now,
    );

    test('not Android: no network call, no offer', () async {
      final source = _CountingSource(_manifest());
      final r = repo(null, supported: false, source: source);
      expect(await r.checkAutomatically(coldStart: true), isNull);
      expect((await r.checkManually()).outcome, ManualCheckOutcome.upToDate);
      expect(source.fetches, 0);
    });

    test('offers an optional update, then Later snoozes it', () async {
      final r = repo(_manifest());
      final offer = await r.checkAutomatically(coldStart: true);
      expect(offer!.kind, UpdateKind.optional);
      await r.snooze(3);
      expect(await r.checkAutomatically(coldStart: true), isNull);
      // A higher build prompts again immediately.
      final r2 = repo(_manifest(latest: 4));
      expect(
        (await r2.checkAutomatically(coldStart: true))!.manifest.latestBuild,
        4,
      );
    });

    test('a required update ignores the snooze', () async {
      final r = repo(_manifest(min: 2));
      await r.snooze(3);
      final offer = await r.checkAutomatically(coldStart: true);
      expect(offer!.kind, UpdateKind.required);
    });

    test('resume checks are throttled to once per 6 h', () async {
      final source = _CountingSource(_manifest());
      final r = repo(null, source: source);
      await r.checkAutomatically(coldStart: true);
      now = now.add(const Duration(hours: 5));
      await r.checkAutomatically(coldStart: false);
      expect(source.fetches, 1);
      now = now.add(const Duration(hours: 2));
      await r.checkAutomatically(coldStart: false);
      expect(source.fetches, 2);
    });

    test('a failed fetch is silent for auto, "failed" for manual', () async {
      final r = repo(null);
      expect(await r.checkAutomatically(coldStart: true), isNull);
      expect((await r.checkManually()).outcome, ManualCheckOutcome.failed);
    });

    test('manual check ignores the snooze; up to date is reported', () async {
      final r = repo(_manifest());
      await r.snooze(3);
      expect((await r.checkManually()).outcome, ManualCheckOutcome.offer);
      final current = repo(_manifest(), build: 3);
      expect(
        (await current.checkManually()).outcome,
        ManualCheckOutcome.upToDate,
      );
    });
  });

  group('manifest source', () {
    test('default URL is the API origin + /downloads/version.json', () {
      expect(
        resolveManifestUri(
          override: '',
          apiBaseUrl: 'https://e-likasligao.online/api/v1/',
        ).toString(),
        'https://e-likasligao.online/downloads/version.json',
      );
      expect(
        resolveManifestUri(
          override: 'https://e-likasligao.online/downloads/test.json',
        ).path,
        '/downloads/test.json',
      );
    });

    test('plain request: cache-buster, no-cache, no auth header', () async {
      final adapter = _RecordingAdapter(
        jsonEncode({'latest_build': 3, 'apk_url': _apk}),
      );
      final source = UpdateManifestSource(
        dio: Dio()..httpClientAdapter = adapter,
        manifestUri: _manifestUri,
        clock: () => DateTime.fromMillisecondsSinceEpoch(1234),
      );
      final m = await source.fetch();
      expect(m!.latestBuild, 3);
      expect(adapter.last.uri.queryParameters['t'], '1234');
      expect(adapter.last.headers['Cache-Control'], 'no-cache');
      expect(adapter.last.headers.containsKey('Authorization'), isFalse);
    });

    test('404 and bad JSON resolve to null', () async {
      for (final adapter in [
        _RecordingAdapter('nope', status: 404),
        _RecordingAdapter('<html>not json</html>'),
      ]) {
        final source = UpdateManifestSource(
          dio: Dio()..httpClientAdapter = adapter,
          manifestUri: _manifestUri,
        );
        expect(await source.fetch(), isNull);
      }
    });
  });
}

String sha256Hex(String body) => sha256.convert(utf8.encode(body)).toString();

/// Each entry is the file body to "download", or an exception to throw.
class _FakeDownloader implements ApkDownloader {
  _FakeDownloader(this.script, {this.onDownload});

  final List<Object> script;
  final void Function()? onDownload;
  int calls = 0;

  @override
  Future<void> download(
    Uri url,
    File destination, {
    required void Function(int received, int total) onProgress,
    required DownloadCancellation cancellation,
  }) async {
    final step = script[calls++];
    onDownload?.call();
    if (cancellation.isCancelled) throw const DownloadCancelledException();
    if (step is String) {
      destination.writeAsStringSync(step);
      onProgress(step.length, step.length);
    } else {
      throw step;
    }
  }
}

class _CountingSource extends UpdateManifestSource {
  _CountingSource(this.manifest) : super(manifestUri: _manifestUri);

  final AppUpdateManifest? manifest;
  int fetches = 0;

  @override
  Future<AppUpdateManifest?> fetch() async {
    fetches++;
    return manifest;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body, {this.status = 200});

  final String body;
  final int status;
  late RequestOptions last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(body, status);
  }

  @override
  void close({bool force = false}) {}
}
