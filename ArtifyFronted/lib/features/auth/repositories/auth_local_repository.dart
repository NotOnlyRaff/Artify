import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_local_repository.g.dart';

@Riverpod(keepAlive: true)
AuthLocalRepository authLocalRepository(AuthLocalRepositoryRef ref) {
  return AuthLocalRepository();
}

class AuthLocalRepository {
  SharedPreferences? _sharedPreferences;

  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  Future<void> setToken(String? token) async {
    await init();

    if (token == null) {
      await _sharedPreferences!.remove('x-auth-token');
      return;
    }

    await _sharedPreferences!.setString('x-auth-token', token);
  }

  Future<String?> getToken() async {
    await init();
    return _sharedPreferences!.getString('x-auth-token');
  }

  Future<void> removeToken() async {
    await init();
    await _sharedPreferences!.remove('x-auth-token');
  }
}
