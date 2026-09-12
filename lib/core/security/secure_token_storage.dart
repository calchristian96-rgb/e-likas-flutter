import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_token_storage.g.dart';

/// The only place in the app that touches `flutter_secure_storage`.
///
/// Holds three secrets/PII values, all scoped to the staff workflow
/// and never touched by anything resident-facing:
/// - the staff Sanctum bearer token (`_tokenKey`)
/// - the random key that encrypts the staff-only Drift database
///   (`_driftEncryptionKeyKey`, see `core/database/staff_database.dart`)
/// - a small cached copy of the last successful `/auth/me` response
///   (`_cachedSessionKey`), used only so an already-signed-in staff
///   member can keep working (offline queueing, viewing their own
///   pending registrations) when `/auth/me` can't be reached to
///   re-validate the token — never used to fabricate a first-time
///   sign-in without connectivity.
///
/// Never logs any of these — callers must not either. None of them is
/// ever written to SharedPreferences or an unencrypted database. Uses
/// flutter_secure_storage's default Android cipher (AES-GCM via
/// Android Keystore, v10+) rather than the removed/deprecated
/// EncryptedSharedPreferences option.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'elikas.staff.sanctum_token';
  static const _driftEncryptionKeyKey = 'elikas.staff.drift_encryption_key';
  static const _cachedSessionKey = 'elikas.staff.cached_session';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, dynamic>?> readCachedSession() async {
    final raw = await _storage.read(key: _cachedSessionKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeCachedSession(Map<String, dynamic> json) =>
      _storage.write(key: _cachedSessionKey, value: jsonEncode(json));

  Future<void> clearCachedSession() => _storage.delete(key: _cachedSessionKey);

  /// Clears everything: token, cached session, and (deliberately not
  /// the Drift encryption key — that's independent of any one login
  /// session and losing it would strand the pending queue unreadable).
  Future<void> clearSession() async {
    await deleteToken();
    await clearCachedSession();
  }

  /// Returns the persisted staff-Drift (SQLCipher) encryption key,
  /// generating and storing a fresh one on first call. The key never
  /// leaves this device and is never derived from anything guessable
  /// (login credentials, device id, etc).
  Future<String> readOrCreateDriftEncryptionKey() async {
    final existing = await _storage.read(key: _driftEncryptionKeyKey);
    if (existing != null) return existing;

    final generated = _generateRandomKey();
    await _storage.write(key: _driftEncryptionKeyKey, value: generated);
    return generated;
  }

  static String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

@riverpod
SecureTokenStorage secureTokenStorage(Ref ref) => SecureTokenStorage();
