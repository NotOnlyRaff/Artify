import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/repositories/song_local_repository.dart';
import 'package:client/features/home/song/repositories/song_remote_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_viewmodel.g.dart';

Future<String> _readStoredToken() async {
  final token = await AuthLocalRepository().getToken();
  if (token == null || token.isEmpty) {
    throw Exception('User not authenticated');
  }
  return token;
}

/// ───────────────── PROVIDER LISTA SONG ─────────────────

@riverpod
Future<List<SongModel>> getAllSongs(GetAllSongsRef ref) async {
  final token = await _readStoredToken();
  final res = await ref.watch(songRemoteRepositoryProvider).getAllSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

@riverpod
Future<List<SongModel>> getFavSongs(GetFavSongsRef ref) async {
  final token = await _readStoredToken();
  final res = await ref.watch(songRemoteRepositoryProvider).getFavSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

/// ───────────────── VIEWMODEL CANZONI ─────────────────
@riverpod
class SongViewModel extends _$SongViewModel {
  SongRemoteRepository get _songRepository =>
      ref.read(songRemoteRepositoryProvider);

  SongLocalRepository get _songLocalRepository =>
      ref.read(songLocalRepositoryProvider);

  AuthLocalRepository get _authLocalRepository => AuthLocalRepository();

  @override
  AsyncValue? build() {
    return null;
  }

  Future<String> _requireToken() async {
    final token = await _authLocalRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
    return token;
  }

  /// ────────────── UPLOAD SONG ──────────────
  Future<void> uploadSong({
    required PickedMedia selectedAudio,
    required PickedMedia selectedThumbnail,
    required String songName,
    required DateTime releaseDate,
    required String composerName,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<String> artistIds = const [],
  }) async {
    await uploadSongResult(
      selectedAudio: selectedAudio,
      selectedThumbnail: selectedThumbnail,
      songName: songName,
      releaseDate: releaseDate,
      composerName: composerName,
      producerName: producerName,
      genre: genre,
      lyrics: lyrics,
      mood: mood,
      artistIds: artistIds,
    );
  }

  Future<Either<AppFailure, SongModel>> uploadSongResult({
    required PickedMedia selectedAudio,
    required PickedMedia selectedThumbnail,
    required String songName,
    required DateTime releaseDate,
    required String composerName,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<String> artistIds = const [],
  }) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _songRepository.uploadSong(
        selectedAudio: selectedAudio,
        selectedThumbnail: selectedThumbnail,
        songName: songName,
        releaseDate: releaseDate,
        composerName: composerName,
        producerName: producerName,
        genre: genre,
        lyrics: lyrics,
        mood: mood,
        artistIds: artistIds,
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);
          return Left(failure);

        case Right(value: final song):
          ref.invalidate(getAllSongsProvider);
          state = AsyncValue.data(song);
          return Right(song);
      }
    } catch (e) {
      final failure = AppFailure(e.toString());
      state = AsyncValue.error(failure.message, StackTrace.current);
      return Left(failure);
    }
  }

  /// ────────────── DELETE SONG ──────────────
  Future<void> deleteSong({required String songId}) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _songRepository.deleteSong(
        songId: songId,
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final success):
          if (success) {
            ref.invalidate(getAllSongsProvider);
            ref.invalidate(getFavSongsProvider);
          }
          state = AsyncValue.data(success);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  /// ────────────── RECENTLY PLAYED ──────────────
  List<SongModel> getRecentlyPlayedSongs() {
    return _songLocalRepository.loadRecentlyPlayed();
  }

  /// ────────────── FAVORITE TOGGLE ──────────────
  Future<void> favSong({required String songId}) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _songRepository.favSong(
        songId: songId,
        token: token,
      );

      switch (res) {
        case Left(value: final l):
          state = AsyncValue.error(l.message, StackTrace.current);

        case Right(value: final isFavorited):
          _applyFavoriteLocally(isFavorited, songId);
          ref.invalidate(getFavSongsProvider);
          ref.invalidate(getAllSongsProvider);
          state = AsyncValue.data(isFavorited);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  void _applyFavoriteLocally(bool isFavorited, String songId) {
    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser == null) return;

    final userNotifier = ref.read(currentUserNotifierProvider.notifier);
    final currentFavs = currentUser.favorites;

    final updatedFavs = isFavorited
        ? <String>{...currentFavs, songId}.toList()
        : currentFavs.where((id) => id != songId).toList();

    userNotifier.setUser(
      currentUser.copyWith(
        favorites: updatedFavs,
      ),
    );
  }
}
