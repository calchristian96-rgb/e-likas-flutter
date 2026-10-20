import 'dart:io';

import 'package:crypto/crypto.dart';

/// Lower-case hex SHA-256 of [file], streamed — the APK is never held
/// in memory.
Future<String> sha256OfFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

bool sha256Matches(String actual, String expected) =>
    actual.toLowerCase() == expected.trim().toLowerCase();
