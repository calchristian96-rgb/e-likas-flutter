import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's bundled fonts (and Material Icons from the Flutter
/// SDK) into the test engine, so golden screenshots show the real
/// typefaces instead of the test font's boxes.
Future<void> loadSheetFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await family('PublicSans', [
    'assets/fonts/PublicSans-Regular.ttf',
    'assets/fonts/PublicSans-Medium.ttf',
    'assets/fonts/PublicSans-SemiBold.ttf',
    'assets/fonts/PublicSans-Bold.ttf',
    'assets/fonts/PublicSans-ExtraBold.ttf',
  ]);
  await family('BarlowCondensed', [
    'assets/fonts/BarlowCondensed-SemiBold.ttf',
    'assets/fonts/BarlowCondensed-Bold.ttf',
    'assets/fonts/BarlowCondensed-ExtraBold.ttf',
  ]);
  await family('SourceSerif4', [
    'assets/fonts/SourceSerif4-Italic-Variable.ttf',
  ]);

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(ByteData.sublistView(icons.readAsBytesSync())),
        );
      await loader.load();
    }
  }
}
