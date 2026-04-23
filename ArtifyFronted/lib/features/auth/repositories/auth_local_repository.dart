import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_local_repository.g.dart';

@Riverpod(keepAlive: true)
AuthLocalRepository authLocalRepository(AuthLocalRepositoryRef ref) {
  return AuthLocalRepository();
}

/// Repository per la persistenza locale delle credenziali di sessione.
///
/// FIX (Sicurezza): migrato da SharedPreferences a flutter_secure_storage.
/// SharedPreferences salva in plain text — leggibile su device rooted/jailbroken.
/// flutter_secure_storage usa Keychain (iOS) e EncryptedSharedPreferences (Android).
///
/// Aggiungi al pubspec.yaml:
///   flutter_secure_storage: ^9.0.0
///
/// Android: minSdkVersion >= 18 in android/app/build.gradle.
/// iOS: nessuna configurazione extra necessaria.
class AuthLocalRepository {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _tokenKey = 'x-auth-token';

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: _tokenKey);
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }
}