import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/repositories/artist_local_repository.dart';
import 'package:client/features/home/artist/repositories/artist_remote_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_viewmodel.g.dart';

// ------------------------------------------------------------------ //
//  Provider di lettura (FutureProvider)                              //
// ------------------------------------------------------------------ //

@riverpod
Future<List<ArtistModel>> getArtists(
  GetArtistsRef ref, {
  String? search,
  String? songId,
  String? albumId,
}) async {
  // FIX: usa il provider Riverpod invece di AuthLocalRepository() diretto.
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

  final repo = ref.watch(artistRemoteRepositoryProvider);
  final res = await repo.listArtists(
    token: token,
    query: search,
    songId: songId,
    albumId: albumId,
  );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

@riverpod
Future<ArtistModel> getArtist(GetArtistRef ref, String artistId) async {
  // FIX: usa il provider Riverpod.
  final token = await ref.watch(authLocalRepositoryProvider).getToken();
  if (token == null || token.isEmpty) throw Exception('User not authenticated');

  final repo = ref.watch(artistRemoteRepositoryProvider);
  final res = await repo.getArtist(artistId: artistId, token: token);

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

// ------------------------------------------------------------------ //
//  ViewModel con stato                                               //
// ------------------------------------------------------------------ //

@riverpod
class ArtistViewModel extends _$ArtistViewModel {
  ArtistRemoteRepository get _remoteRepo =>
      ref.read(artistRemoteRepositoryProvider);

  ArtistLocalRepository get _localRepo =>
      ref.read(artistLocalRepositoryProvider);

  // FIX: usa il provider invece di AuthLocalRepository() diretto.
  // Il vecchio codice creava una nuova istanza ad ogni chiamata, bypassando
  // flutter_secure_storage configurato nel provider.
  AuthLocalRepository get _authLocalRepo =>
      ref.read(authLocalRepositoryProvider);

  @override
  AsyncValue? build() => null;

  Future<String> _requireToken({String? overrideToken}) async {
    if (overrideToken != null && overrideToken.trim().isNotEmpty) {
      return overrideToken.trim();
    }
    // FIX: legge dal provider, non da AuthLocalRepository() istanziato.
    final token = await _authLocalRepo.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
    return token;
  }

  // ------------------------------------------------------------------ //
  //  Upload immagine                                                    //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, String>> uploadArtistImage({
    required PickedMedia image,
    String? token,
  }) async {
    try {
      final resolvedToken = await _requireToken(overrideToken: token);
      return await _remoteRepo.uploadArtistImage(
          image: image, token: resolvedToken);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, String>> uploadArtistImageWithToken({
    required PickedMedia image,
    required String token,
  }) =>
      uploadArtistImage(image: image, token: token);

  // ------------------------------------------------------------------ //
  //  Creazione artista                                                  //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, ArtistModel>> createArtistResult({
    required String name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<String> songIds = const [],
    List<String> albumIds = const [],
    String? token,
  }) async {
    state = const AsyncValue.loading();

    try {
      final resolvedToken = await _requireToken(overrideToken: token);
      final res = await _remoteRepo.createArtist(
        name: name,
        displayName: displayName,
        slug: slug,
        imageUrl: imageUrl,
        bio: bio,
        country: country,
        songIds: songIds,
        albumIds: albumIds,
        token: resolvedToken,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);
          return Left(failure);

        case Right(value: final artist):
          ref.invalidate(getArtistsProvider);
          ref.invalidate(getArtistProvider(artist.id));
          try {
            await _localRepo.saveRecentlyOpened(artist);
          } catch (_) {}
          state = AsyncValue.data(artist);
          return Right(artist);
      }
    } catch (e) {
      final failure = AppFailure(e.toString());
      state = AsyncValue.error(failure.message, StackTrace.current);
      return Left(failure);
    }
  }

  // createArtist senza return — delegato a createArtistResult.
  Future<void> createArtist({
    required String name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<String> songIds = const [],
    List<String> albumIds = const [],
    String? token,
  }) =>
      createArtistResult(
        name: name,
        displayName: displayName,
        slug: slug,
        imageUrl: imageUrl,
        bio: bio,
        country: country,
        songIds: songIds,
        albumIds: albumIds,
        token: token,
      );

  // ------------------------------------------------------------------ //
  //  Aggiornamento artista                                              //
  // ------------------------------------------------------------------ //

  Future<void> updateArtist({
    required String artistId,
    String? name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<String>? songIds,
    List<String>? albumIds,
    String? token,
  }) async {
    state = const AsyncValue.loading();

    try {
      final resolvedToken = await _requireToken(overrideToken: token);
      final res = await _remoteRepo.updateArtist(
        artistId: artistId,
        name: name,
        displayName: displayName,
        slug: slug,
        imageUrl: imageUrl,
        bio: bio,
        country: country,
        songIds: songIds,
        albumIds: albumIds,
        token: resolvedToken,
      );

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final artist):
          try {
            await _localRepo.saveRecentlyOpened(artist);
          } catch (_) {}
          ref.invalidate(getArtistsProvider);
          ref.invalidate(getArtistProvider(artistId));
          state = AsyncValue.data(artist);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // ------------------------------------------------------------------ //
  //  Eliminazione artista                                               //
  // ------------------------------------------------------------------ //

  Future<void> deleteArtist({required String artistId, String? token}) async {
    state = const AsyncValue.loading();

    try {
      final resolvedToken = await _requireToken(overrideToken: token);
      final res = await _remoteRepo.deleteArtist(
          artistId: artistId, token: resolvedToken);

      switch (res) {
        case Left(value: final failure):
          state = AsyncValue.error(failure.message, StackTrace.current);

        case Right(value: final ok):
          if (ok) {
            try {
              await _localRepo.removeFromRecentlyOpened(artistId);
            } catch (_) {}
            ref.invalidate(getArtistsProvider);
            ref.invalidate(getArtistProvider(artistId));
          }
          state = AsyncValue.data(ok);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // ------------------------------------------------------------------ //
  //  Recenti locali                                                     //
  // ------------------------------------------------------------------ //

  List<ArtistModel> getRecentlyOpenedArtists() =>
      _localRepo.loadRecentlyOpened();

  Future<void> markArtistOpened(ArtistModel artist) =>
      _localRepo.saveRecentlyOpened(artist);
}
