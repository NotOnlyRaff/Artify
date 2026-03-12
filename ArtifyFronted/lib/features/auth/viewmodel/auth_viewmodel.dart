import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/auth/repositories/auth_remote_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_viewmodel.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  AuthRemoteRepository get _authRemoteRepository =>
      ref.read(authRemoteRepositoryProvider);

  AuthLocalRepository get _authLocalRepository =>
      ref.read(authLocalRepositoryProvider);

  CurrentUserNotifier get _currentUserNotifier =>
      ref.read(currentUserNotifierProvider.notifier);

  @override
  FutureOr<UserModel?> build() {
    return null;
  }

  Future<void> signUpUser({
    required String name,
    required String email,
    required String password,
    required bool isArtist,
  }) async {
    state = const AsyncValue.loading();

    final res = await _authRemoteRepository.signup(
      name: name,
      email: email,
      password: password,
      isArtist: isArtist,
    );

    state = switch (res) {
      Left(value: final l) => AsyncValue.error(
          l.message,
          StackTrace.current,
        ),
      Right(value: final r) => AsyncValue.data(r),
    };
  }

  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final res = await _authRemoteRepository.login(
      email: email,
      password: password,
    );

    switch (res) {
      case Left(value: final l):
        state = AsyncValue.error(l.message, StackTrace.current);
        break;

      case Right(value: final r):
        await _authLocalRepository.setToken(r.token);
        _currentUserNotifier.setUser(r);
        state = AsyncValue.data(r);
        break;
    }
  }

  Future<UserModel?> getData() async {
    state = const AsyncValue.loading();

    final token = await _authLocalRepository.getToken();

    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(null);
      return null;
    }

    final res = await _authRemoteRepository.getCurrentUserData(token);

    switch (res) {
      case Left(value: final l):
        await _authLocalRepository.removeToken();
        _currentUserNotifier.clearUser();
        state = AsyncValue.error(l.message, StackTrace.current);
        return null;

      case Right(value: final r):
        _currentUserNotifier.setUser(r);
        state = AsyncValue.data(r);
        return r;
    }
  }

  Future<void> logout() async {
    await _authLocalRepository.removeToken();
    _currentUserNotifier.clearUser();
    state = const AsyncValue.data(null);
  }
}
