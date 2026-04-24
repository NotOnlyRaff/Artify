import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/repositories/song_local_repository.dart';
import 'package:client/features/home/song/repositories/song_remote_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_viewmodel.g.dart';

/// ───────────────── PROVIDER LISTA SONG ─────────────────

@riverpod
Future<List<SongModel>> getAllSongs(GetAllSongsRef ref) async {
  // FIX: usa il provider Riverpod invece di AuthLocalRepository() diretto.
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

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
  // FIX: usa il provider Riverpod.
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

  final res = await ref.watch(songRemoteRepositoryProvider).getFavSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

/// FIX: aggiunto provider per fetch di una singola song by ID.
/// Usato da artist_actions_row per il fetch-and-play.
@riverpod
Future<SongModel> getSong(Ref ref, String songId) async {
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

  final res = await ref.watch(songRemoteRepositoryProvider).getSongById(
        songId: songId,
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

  // FIX: usa il provider Riverpod invece di AuthLocalRepository() diretto.
  AuthLocalRepository get _authLocalRepository =>
      ref.read(authLocalRepositoryProvider);

  @override
  AsyncValue? build() {
    return null;
  }

  Future<String> _requireToken() async {
    // FIX: legge dal provider, non da AuthLocalRepository() istanziato.
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
    String? composerId,
    String? composerName,
    String? producerId,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<String> artistIds = const [],
    List<SongArtistModel> artistLinks = const [],
  }) async {
    await uploadSongResult(
      selectedAudio: selectedAudio,
      selectedThumbnail: selectedThumbnail,
      songName: songName,
      releaseDate: releaseDate,
      composerId: composerId,
      composerName: composerName,
      producerId: producerId,
      producerName: producerName,
      genre: genre,
      lyrics: lyrics,
      mood: mood,
      artistIds: artistIds,
      artistLinks: artistLinks,
    );
  }

  Future<Either<AppFailure, SongModel>> uploadSongResult({
    required PickedMedia selectedAudio,
    required PickedMedia selectedThumbnail,
    required String songName,
    required DateTime releaseDate,
    String? composerId,
    String? composerName,
    String? producerId,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<String> artistIds = const [],
    List<SongArtistModel> artistLinks = const [],
  }) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _songRepository.uploadSong(
        selectedAudio: selectedAudio,
        selectedThumbnail: selectedThumbnail,
        songName: songName,
        releaseDate: releaseDate,
        composerId: composerId,
        composerName: composerName,
        producerId: producerId,
        producerName: producerName,
        genre: genre,
        lyrics: lyrics,
        mood: mood,
        artistIds: artistIds,
        artistLinks: artistLinks,
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
  Future<void> updateSong({
    required String songId,
    required String songName,
    required DateTime releaseDate,
    String? composerId,
    String? composerName,
    String? producerId,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<SongArtistModel> artistLinks = const [],
  }) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _songRepository.updateSong(
        songId: songId,
        songName: songName,
        releaseDate: releaseDate,
        composerId: composerId,
        composerName: composerName,
        producerId: producerId,
        producerName: producerName,
        genre: genre,
        lyrics: lyrics,
        mood: mood,
        artistLinks: artistLinks,
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final song):
          ref.invalidate(getSongProvider(songId));
          ref.invalidate(getAllSongsProvider);
          ref.invalidate(getFavSongsProvider);
          state = AsyncValue.data(song);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

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
          // FIX: _applyFavoriteLocally ora applica effettivamente l'aggiornamento.
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

    // FIX: era dead code — calcolava updatedFavs senza mai applicarlo.
    userNotifier.setUser(currentUser.copyWith(favoriteSongIds: updatedFavs));
  }
}
