import 'dart:typed_data';

import 'package:client/core/failure/failure.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/auth/repositories/auth_remote_repository.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
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
  Future<UserModel?> build() async {
    return _bootstrapSession();
  }

  // ------------------------------------------------------------------ //
  //  Helper privati                                                     //
  // ------------------------------------------------------------------ //

  Future<String?> _readStoredTokenOrNull() async {
    final token = await _authLocalRepository.getToken();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<String?> _currentSessionToken() async {
    final stored = await _readStoredTokenOrNull();
    if (stored != null) return stored;
    final memoryToken = ref.read(currentUserNotifierProvider)?.token;
    if (memoryToken == null || memoryToken.isEmpty) return null;
    return memoryToken;
  }

  /// FIX: token è String?, _withToken accetta String → null-safe con ?? ''.
  UserModel _withToken(UserModel user, String? token) {
    return user.copyWith(token: token ?? '');
  }

  Future<void> _clearAuthStateOnly() async {
    await _authLocalRepository.removeToken();
    _currentUserNotifier.clearUser();
  }

  Future<void> _clearSessionForExplicitLogout() async {
    // Nota architetturale: auth non dovrebbe dipendere dal dominio song.
    // Fix ideale: event bus o callback on-logout registrato dal song domain.
    // Per ora manteniamo il comportamento esistente.
    await ref.read(playbackQueueControllerProvider.notifier).clearQueue(
          stopPlayback: false,
        );
    await ref.read(currentSongNotifierProvider.notifier).stopAndClear();
    await _authLocalRepository.removeToken();
    _currentUserNotifier.clearUser();
    ref.invalidate(playbackQueueControllerProvider);
    ref.invalidate(currentSongNotifierProvider);
    ref.invalidate(songViewModelProvider);
    ref.invalidate(getAllSongsProvider);
    ref.invalidate(getFavSongsProvider);
  }

  Future<UserModel?> _bootstrapSession() async {
    final token = await _readStoredTokenOrNull();
    if (token == null) {
      _currentUserNotifier.clearUser();
      return null;
    }

    final res = await _authRemoteRepository.getCurrentUserData(token);

    switch (res) {
      case Left():
        await _authLocalRepository.removeToken();
        _currentUserNotifier.clearUser();
        return null;

      case Right(value: final user):
        // FIX: token già incluso in user da getCurrentUserData (.map + copyWith).
        _currentUserNotifier.setUser(user);
        return user;
    }
  }

  // ------------------------------------------------------------------ //
  //  Auth                                                               //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, UserModel>> signUpUser({
    required String name,
    required String email,
    required String password,
    required bool isArtist,
  }) async {
    return _authRemoteRepository.signup(
      name: name,
      email: email,
      password: password,
      isArtist: isArtist,
    );
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

      case Right(value: final user):
        // FIX: _withToken accetta String? — nessun crash se token è null.
        final safeUser = _withToken(user, user.token);
        await _authLocalRepository.setToken(safeUser.token);
        _currentUserNotifier.setUser(safeUser);
        state = AsyncValue.data(safeUser);
    }
  }

  /// Ritorna il token senza modificare lo stato globale.
  /// Usato per flussi di onboarding artista.
  ///
  /// FIX: Right(user.token ?? '') — user.token è String?, Right richiede String.
  Future<Either<AppFailure, String>> loginForArtistOnboarding({
    required String email,
    required String password,
  }) async {
    final res = await _authRemoteRepository.login(
      email: email,
      password: password,
    );

    switch (res) {
      case Left(value: final l):
        return Left(l);
      case Right(value: final user):
        // FIX: null-safe — token può essere String? ma Right<_, String> vuole String.
        return Right(user.token ?? '');
    }
  }

  Future<void> logout() async {
    await _clearSessionForExplicitLogout();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUserData() async {
    state = const AsyncValue.loading();
    final refreshedUser = await _bootstrapSession();
    state = AsyncValue.data(refreshedUser);
  }

  // ------------------------------------------------------------------ //
  //  Profilo                                                            //
  // ------------------------------------------------------------------ //

  Future<void> updateUserData(UserModel updatedUser) async {
    state = const AsyncValue.loading();
    final token = await _currentSessionToken();
    if (token == null) {
      await _clearAuthStateOnly();
      state = const AsyncValue.data(null);
      return;
    }
    final safeUser = _withToken(updatedUser, token);
    _currentUserNotifier.setUser(safeUser);
    state = AsyncValue.data(safeUser);
  }

  Future<void> updateUserName(String newName) async {
    state = const AsyncValue.loading();
    final currentToken = await _currentSessionToken();

    final res = await _authRemoteRepository.updateProfile(name: newName);

    switch (res) {
      case Left(value: final l):
        state = AsyncValue.error(l.message, StackTrace.current);
      case Right(value: final updatedUser):
        final safeUser = _withToken(updatedUser, currentToken);
        _currentUserNotifier.setUser(safeUser);
        state = AsyncValue.data(safeUser);
    }
  }

  /// FIX: uploadProfilePicture ora restituisce UserModel (non String).
  /// Il backend /auth/upload-profile-picture risponde con UserOut aggiornato.
  /// Parsarlo direttamente elimina la seconda chiamata a updateProfile.
  Future<void> uploadAndApplyProfilePicture({
    required Uint8List bytes,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();
    final currentToken = await _currentSessionToken();

    final res = await _authRemoteRepository.uploadProfilePicture(
      bytes: bytes,
      fileName: fileName,
    );

    switch (res) {
      case Left(value: final l):
        state = AsyncValue.error(l.message, StackTrace.current);
      case Right(value: final updatedUser):
        // FIX: un solo round-trip — niente secondo updateProfile call.
        final safeUser = _withToken(updatedUser, currentToken);
        _currentUserNotifier.setUser(safeUser);
        state = AsyncValue.data(safeUser);
    }
  }

  // ------------------------------------------------------------------ //
  //  Account                                                            //
  // ------------------------------------------------------------------ //

  /// Rollback atomico per il flusso di onboarding artista.
  ///
  /// Se la creazione del profilo artista fallisce dopo che l'utente è stato
  /// già registrato, questo metodo elimina l'utente usando il token ottenuto
  /// in loginForArtistOnboarding (non salvato nello storage).
  ///
  /// Non modifica lo stato del viewmodel perché l'onboarding non ha mai
  /// effettuato un login globale — nulla da ripristinare a livello di sessione.
  Future<void> rollbackUserCreation({
    required String userId,
    required String token,
  }) async {
    try {
      await _authRemoteRepository.deleteUserWithToken(
        userId: userId,
        token: token,
      );
    } catch (_) {
      // Best-effort: se il rollback fallisce l'utente orfano andrà rimosso
      // tramite cleanup manuale. Non rilanciamo per non oscurare l'errore originale.
    }
  }

  Future<void> deleteUserAccount() async {
    state = const AsyncValue.loading();
    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser == null) {
      await _clearSessionForExplicitLogout();
      state = const AsyncValue.data(null);
      return;
    }

    final res = await _authRemoteRepository.deleteUser(currentUser.id);

    switch (res) {
      case Left(value: final l):
        state = AsyncValue.error(l.message, StackTrace.current);
      case Right():
        await _clearSessionForExplicitLogout();
        state = const AsyncValue.data(null);
    }
  }

  Future<Either<AppFailure, String>> changePassword({
    required String userId,
    String? currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();

    final res = await _authRemoteRepository.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    switch (res) {
      case Left(value: final l):
        state = AsyncValue.error(l.message, StackTrace.current);
        return Left(l);
      case Right(value: final message):
        final currentUser = ref.read(currentUserNotifierProvider);
        state = AsyncValue.data(currentUser);
        return Right(message);
    }
  }
}
