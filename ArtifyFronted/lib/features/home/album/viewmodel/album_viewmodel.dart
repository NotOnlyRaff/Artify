import 'package:client/core/failure/failure.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/repositories/album_local_repository.dart';
import 'package:client/features/home/album/repositories/album_remote_repository.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:fpdart/fpdart.dart'; // Either, Left, Right
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_viewmodel.g.dart';

/// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
///
/// Uso:
///   ref.watch(getAllAlbumsProvider());
///   ref.watch(getAllAlbumsProvider(artistId: '...'));
@riverpod
Future<List<AlbumModel>> getAllAlbums(
  GetAllAlbumsRef ref, {
  String? artistId,
}) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));
  final repo = ref.watch(albumRemoteRepositoryProvider);

  final res = await repo.listAlbums(
    token: token,
    artistId: artistId,
  );

  return switch (res) {
    Left(value: final failure) => throw failure.message,
    Right(value: final albums) => albums,
  };
}

/// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
///
/// Uso:
///   ref.watch(getAlbumProvider(albumId));
@riverpod
Future<AlbumModel> getAlbum(
  GetAlbumRef ref,
  String albumId,
) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));
  final repo = ref.watch(albumRemoteRepositoryProvider);

  final res = await repo.getAlbum(
    albumId: albumId,
    token: token,
  );

  return switch (res) {
    Left(value: final failure) => throw failure.message,
    Right(value: final album) => album,
  };
}

/// ───────────────── VIEWMODEL MUTAZIONI ALBUM ─────────────
@riverpod
class AlbumViewModel extends _$AlbumViewModel {
  AlbumRemoteRepository get _remote => ref.read(albumRemoteRepositoryProvider);
  AlbumLocalRepository get _local => ref.read(albumLocalRepositoryProvider);

  String get _token => ref.read(currentUserNotifierProvider)!.token;

  @override
  AsyncValue? build() {
    // stato iniziale: nessuna operazione in corso
    return null;
  }

  Future<Either<AppFailure, String>> uploadAlbumCover({
    required PickedMedia cover,
  }) async {
    return _remote.uploadAlbumCover(
      cover: cover,
      token: _token,
    );
  }

  Future<void> createAlbum({
    required String title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    List<String> artistIds = const [],
    List<String> songIds = const [],
    List<SongModel> newSongs = const [],
  }) async {
    state = const AsyncValue.loading();

    final res = await _remote.createAlbum(
      title: title,
      releaseDate: releaseDate,
      label: label,
      albumType: albumType,
      genre: genre,
      coverUrl: coverUrl,
      artistIds: artistIds,
      songIds: songIds,
      newSongs: newSongs,
      token: _token,
    );

    switch (res) {
      case Left(value: final failure):
        state = AsyncValue.error(failure.message, StackTrace.current);
      case Right(value: final album):
        // invalida le liste album
        ref.invalidate(getAllAlbumsProvider);
        state = AsyncValue.data(album);
    }
  }

  /// UPDATE ALBUM (PATCH)
  Future<void> updateAlbum({
    required String albumId,
    String? title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    List<String>? artistIds,
    List<String>? songIds,
  }) async {
    state = const AsyncValue.loading();

    final res = await _remote.updateAlbum(
      albumId: albumId,
      title: title,
      releaseDate: releaseDate,
      label: label,
      albumType: albumType,
      genre: genre,
      coverUrl: coverUrl,
      artistIds: artistIds,
      songIds: songIds,
      token: _token,
    );

    switch (res) {
      case Left(value: final failure):
        state = AsyncValue.error(failure.message, StackTrace.current);
      case Right(value: final album):
        // refresh lista + dettaglio
        ref.invalidate(getAllAlbumsProvider);
        ref.invalidate(getAlbumProvider(albumId));
        state = AsyncValue.data(album);
    }
  }

  /// DELETE ALBUM
  Future<void> deleteAlbum(String albumId) async {
    state = const AsyncValue.loading();

    final res = await _remote.deleteAlbum(
      albumId: albumId,
      token: _token,
    );

    switch (res) {
      case Left(value: final failure):
        state = AsyncValue.error(failure.message, StackTrace.current);
      case Right(value: final success):
        if (success) {
          ref.invalidate(getAllAlbumsProvider);
        }
        state = AsyncValue.data(success);
    }
  }

  /// ────────────── CACHE LOCALE (Hive) ──────────────

  /// Album aperti di recente
  List<AlbumModel> getRecentlyOpenedAlbums() {
    return _local.loadRecentlyOpened();
  }

  /// Marca un album come "aperto di recente"
  Future<void> markAlbumOpened(AlbumModel album) async {
    await _local.saveRecentlyOpened(album);
  }

  /// Svuota la lista "recently opened"
  Future<void> clearRecentlyOpenedAlbums() async {
    await _local.clearAll();
  }
}
