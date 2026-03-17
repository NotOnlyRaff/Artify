import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/repositories/album_local_repository.dart';
import 'package:client/features/home/album/repositories/album_remote_repository.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_viewmodel.g.dart';

Future<String> _readStoredAlbumToken() async {
  final token = await AuthLocalRepository().getToken();
  if (token == null || token.isEmpty) {
    throw Exception('User not authenticated');
  }
  return token;
}

/// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
@riverpod
Future<List<AlbumModel>> getAllAlbums(
  GetAllAlbumsRef ref, {
  String? artistId,
}) async {
  final token = await _readStoredAlbumToken();
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
@riverpod
Future<AlbumModel> getAlbum(
  GetAlbumRef ref,
  String albumId,
) async {
  final token = await _readStoredAlbumToken();
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

  Future<Either<AppFailure, String>> uploadAlbumCover({
    required PickedMedia cover,
  }) async {
    try {
      final token = await _requireToken();

      return await _remote.uploadAlbumCover(
        cover: cover,
        token: token,
      );
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
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

    try {
      final token = await _requireToken();

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
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final album):
          ref.invalidate(getAllAlbumsProvider);
          ref.invalidate(getAlbumProvider(album.id));
          state = AsyncValue.data(album);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

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

    try {
      final token = await _requireToken();

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
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final album):
          ref.invalidate(getAllAlbumsProvider);
          ref.invalidate(getAlbumProvider(albumId));
          state = AsyncValue.data(album);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _remote.deleteAlbum(
        albumId: albumId,
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final success):
          if (success) {
            ref.invalidate(getAllAlbumsProvider);
            ref.invalidate(getAlbumProvider(albumId));
          }
          state = AsyncValue.data(success);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  /// ────────────── CACHE LOCALE (Hive) ──────────────

  List<AlbumModel> getRecentlyOpenedAlbums() {
    return _local.loadRecentlyOpened();
  }

  Future<void> markAlbumOpened(AlbumModel album) async {
    await _local.saveRecentlyOpened(album);
  }

  Future<void> clearRecentlyOpenedAlbums() async {
    await _local.clearAll();
  }
}