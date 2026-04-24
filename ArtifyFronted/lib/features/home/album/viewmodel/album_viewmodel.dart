import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/repositories/album_local_repository.dart';
import 'package:client/features/home/album/repositories/album_remote_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_viewmodel.g.dart';

/// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
@riverpod
Future<List<AlbumModel>> getAllAlbums(
  GetAllAlbumsRef ref, {
  String? artistId,
}) async {
  // FIX: usa il provider Riverpod invece di AuthLocalRepository() diretto.
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

  final repo = ref.watch(albumRemoteRepositoryProvider);
  final res = await repo.listAlbums(token: token, artistId: artistId);

  return switch (res) {
    Left(value: final failure) => throw failure.message,
    Right(value: final albums) => albums,
  };
}

/// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
@riverpod
Future<AlbumModel> getAlbum(GetAlbumRef ref, String albumId) async {
  // FIX: usa il provider Riverpod.
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

  final repo = ref.watch(albumRemoteRepositoryProvider);
  final res = await repo.getAlbum(albumId: albumId, token: token);

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

  // FIX: usa il provider invece di AuthLocalRepository() diretto.
  AuthLocalRepository get _authLocalRepository =>
      ref.read(authLocalRepositoryProvider);

  @override
  AsyncValue? build() => null;

  void _debugAlbumUpdate(String debugId, String message) {
    debugPrint('[AlbumViewModel][$debugId] $message');
  }

  Future<String> _requireToken() async {
    // FIX: legge da flutter_secure_storage tramite provider.
    final token = await _authLocalRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
    return token;
  }

  // ────────────── UPLOAD COVER ──────────────

  Future<Either<AppFailure, String>> uploadAlbumCover({
    required PickedMedia cover,
  }) async {
    try {
      final token = await _requireToken();
      return await _remote.uploadAlbumCover(cover: cover, token: token);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ────────────── CREAZIONE ──────────────

  Future<void> createAlbum({
    required String title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    List<String> artistIds = const [],
    List<String> songIds = const [],
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
        token: token,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final album):
          ref.invalidate(getAllAlbumsProvider);
          ref.invalidate(getAlbumProvider(album.id));
          try {
            await _local.saveRecentlyOpened(album);
          } catch (_) {}
          state = AsyncValue.data(album);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // ────────────── AGGIORNAMENTO ──────────────

  Future<Either<AppFailure, AlbumModel>> updateAlbum({
    required String albumId,
    String? title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    List<String>? artistIds,
    List<String>? songIds,
    String? debugId,
  }) async {
    state = const AsyncValue.loading();
    final debugLabel = debugId ?? 'no-debug-id';

    try {
      final token = await _requireToken();
      _debugAlbumUpdate(
        debugLabel,
        'START albumId=$albumId artistIds=$artistIds songIds=$songIds',
      );

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
        debugId: debugId,
      );

      switch (res) {
        case Left(value: final failure):
          _debugAlbumUpdate(debugLabel, 'FAILURE ${failure.message}');
          state = AsyncValue.error(failure.message, StackTrace.current);
          return Left(failure);

        case Right(value: final album):
          _debugAlbumUpdate(
            debugLabel,
            'SUCCESS responseOrder=${album.tracks.asMap().entries.map((entry) => '${entry.key + 1}:${entry.value.songId}:${entry.value.trackNumber}').toList()}',
          );
          ref.invalidate(getAllAlbumsProvider);
          ref.invalidate(getAlbumProvider(albumId));
          try {
            await _local.saveRecentlyOpened(album);
          } catch (_) {}
          state = AsyncValue.data(album);
          return Right(album);
      }
    } catch (e) {
      _debugAlbumUpdate(debugLabel, 'EXCEPTION $e');
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return Left(AppFailure(e.toString()));
    }
  }

  // ────────────── ELIMINAZIONE ──────────────

  Future<void> deleteAlbum(String albumId) async {
    state = const AsyncValue.loading();

    try {
      final token = await _requireToken();

      final res = await _remote.deleteAlbum(albumId: albumId, token: token);

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

  // ────────────── CACHE LOCALE ──────────────

  List<AlbumModel> getRecentlyOpenedAlbums() => _local.loadRecentlyOpened();

  Future<void> markAlbumOpened(AlbumModel album) =>
      _local.saveRecentlyOpened(album);

  Future<void> clearRecentlyOpenedAlbums() => _local.clearAll();
}
