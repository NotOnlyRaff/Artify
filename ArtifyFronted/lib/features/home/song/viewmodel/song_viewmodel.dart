import 'package:client/core/failure/failure.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/repositories/song_local_repository.dart';
import 'package:client/features/home/song/repositories/song_remote_repository.dart';
import 'package:client/core/utils.dart'; // PickedMedia
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_viewmodel.g.dart';

/// ───────────────── PROVIDER LISTA SONG ─────────────────

@riverpod
Future<List<SongModel>> getAllSongs(GetAllSongsRef ref) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));
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
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));
  final res = await ref.watch(songRemoteRepositoryProvider).getFavSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

/// ───────────────── VIEWMODEL CANZONI ─────────────────
/// Gestisce:
/// - upload song
/// - delete song
/// - toggle favorite
/// - recently played (via SongLocalRepository)
@riverpod
class SongViewModel extends _$SongViewModel {
  SongRemoteRepository get _songRepository =>
      ref.read(songRemoteRepositoryProvider);
  SongLocalRepository get _songLocalRepository =>
      ref.read(songLocalRepositoryProvider);

  @override
  AsyncValue? build() {
    // stato iniziale: nessuna operazione in corso
    return null;
  }

  // ────────────── UPLOAD SONG (V2) ──────────────
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
    List<String> artistIds = const [], // 👈 nuovo
  }) async {
    state = const AsyncValue.loading();

    final token = ref.read(currentUserNotifierProvider)!.token;
    final repo = ref.read(songRemoteRepositoryProvider);

    final res = await repo.uploadSong(
      selectedAudio: selectedAudio,
      selectedThumbnail: selectedThumbnail,
      songName: songName,
      releaseDate: releaseDate,
      composerName: composerName,
      producerName: producerName,
      genre: genre,
      lyrics: lyrics,
      mood: mood,
      artistIds: artistIds, // 👈 passiamo giù
      token: token,
    );

    switch (res) {
      case Left(value: final AppFailure failure):
        state = AsyncValue.error(failure.message, StackTrace.current);

      case Right(value: final SongModel song):
        // se vuoi, potresti salvare subito nei "recently played"
        // _songLocalRepository.saveRecentlyPlayed(song);

        // aggiorna la lista canzoni globale
        ref.invalidate(getAllSongsProvider);

        state = AsyncValue.data(song);
    }
  }

  // ────────────── DELETE SONG ──────────────
  Future<void> deleteSong({required String songId}) async {
    state = const AsyncValue.loading();

    final res = await _songRepository.deleteSong(
      songId: songId,
      token: ref.read(currentUserNotifierProvider)!.token,
    );

    switch (res) {
      case Left(:final value):
        state = AsyncValue.error(value.message, StackTrace.current);
      case Right(:final value):
        if (value) {
          // ricarica lista generale
          ref.invalidate(getAllSongsProvider);
        }
        state = AsyncValue.data(value);
    }
  }

  // ────────────── RECENTLY PLAYED ──────────────
  List<SongModel> getRecentlyPlayedSongs() {
    return _songLocalRepository.loadRecentlyPlayed();
  }

  // ────────────── FAVORITE TOGGLE ──────────────
  Future<void> favSong({required String songId}) async {
    state = const AsyncValue.loading();

    final res = await _songRepository.favSong(
      songId: songId,
      token: ref.read(currentUserNotifierProvider)!.token,
    );

    final val = switch (res) {
      Left(value: final l) => state =
          AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _favSongSuccess(r, songId),
    };
    // debug se ti serve
    print(val);
  }

  AsyncValue _favSongSuccess(bool isFavorited, String songId) {
    final userNotifier = ref.read(currentUserNotifierProvider.notifier);
    final currentUser = ref.read(currentUserNotifierProvider)!;

    // favorites ora è List<String> (lista di songId)
    final List<String> currentFavs = currentUser.favorites;

    if (isFavorited) {
      // aggiungo l'id se non già presente
      final updatedFavs = <String>{
        ...currentFavs,
        songId,
      }.toList();

      userNotifier.setUser(
        currentUser.copyWith(
          favorites: updatedFavs,
        ),
      );
    } else {
      // rimuovo l'id
      final updatedFavs = currentFavs.where((id) => id != songId).toList();

      userNotifier.setUser(
        currentUser.copyWith(
          favorites: updatedFavs,
        ),
      );
    }

    // ricarica provider dei preferiti remoti
    ref.invalidate(getFavSongsProvider);

    return state = AsyncValue.data(isFavorited);
  }
}
