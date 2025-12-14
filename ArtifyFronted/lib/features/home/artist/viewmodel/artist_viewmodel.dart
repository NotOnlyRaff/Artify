import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/repositories/artist_local_repository.dart';
import 'package:client/features/home/artist/repositories/artist_remote_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_viewmodel.g.dart';

/// ───────────────── PROVIDER: LISTA ARTISTI ─────────────────
///
/// Uso:
///   ref.watch(getArtistsProvider(
///     search: 'drake',
///     songId: '...',
///   ));
@riverpod
Future<List<ArtistModel>> getArtists(
  GetArtistsRef ref, {
  String? search,
  String? songId,
  String? albumId,
}) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));

  final repo = ref.watch(artistRemoteRepositoryProvider);

  final res = await repo.listArtists(
    token: token,
    songId: songId,
    albumId: albumId,
  );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

/// ───────────────── PROVIDER: SINGOLO ARTISTA ────────────────
///
/// Uso:
///   ref.watch(getArtistProvider(artistId));
@riverpod
Future<ArtistModel> getArtist(
  GetArtistRef ref,
  String artistId,
) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));

  final repo = ref.watch(artistRemoteRepositoryProvider);

  final res = await repo.getArtist(
    artistId: artistId,
    token: token,
  );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

/// ───────────────── VIEWMODEL: OPERAZIONI MUTABILI ───────────
///
/// Per create / update / delete + gestione "recent artists".
///
/// Uso:
///   final vm = ref.read(artistViewModelProvider.notifier);
///   vm.createArtist(...);
///
///   ref.listen(artistViewModelProvider, (prev, next) { ... });
@riverpod
class ArtistViewModel extends _$ArtistViewModel {
  ArtistRemoteRepository get _remoteRepo =>
      ref.read(artistRemoteRepositoryProvider);
  ArtistLocalRepository get _localRepo =>
      ref.read(artistLocalRepositoryProvider);

  @override
  AsyncValue? build() {
    // stato iniziale: nessuna operazione in corso
    return null;
  }

  // ───────────────── CREATE ARTIST ─────────────────
  Future<void> createArtist({
    required String name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<String> songIds = const [],
    List<String> albumIds = const [],
  }) async {
    state = const AsyncValue.loading();

    final token = ref.read(currentUserNotifierProvider)!.token;

    final res = await _remoteRepo.createArtist(
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

    switch (res) {
      case Left(value: final failure):
        state = AsyncValue.error(failure.message, StackTrace.current);
      case Right(value: final artist):
        // invalida liste ecc.
        ref.invalidate(getArtistsProvider);
        try {
          await _localRepo.saveRecentlyOpened(artist);
        } catch (e, st) {
          state = AsyncValue.error('Error saving recent artist: $e', st);
          // debugPrint('Error saving recent artist: $e');
        }

        state = AsyncValue.data(artist);
    }
  }

  // ───────────────── UPDATE ARTIST ─────────────────
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
  }) async {
    state = const AsyncValue.loading();

    final token = ref.read(currentUserNotifierProvider)!.token;

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
      token: token,
    );

    switch (res) {
      case Left(value: final failure):
        state = AsyncValue.error(failure.message, StackTrace.current);

      case Right(value: final artist):
        // aggiorno anche in locale (se era tra i recenti)
        await _localRepo.saveRecentlyOpened(artist);

        // invalidiamo le liste dipendenti
        ref.invalidate(getArtistsProvider);
        ref.invalidate(getArtistProvider(artistId));

        state = AsyncValue.data(artist);
    }
  }

  // ───────────────── DELETE ARTIST ─────────────────
  Future<void> deleteArtist({
    required String artistId,
  }) async {
    state = const AsyncValue.loading();

    final token = ref.read(currentUserNotifierProvider)!.token;

    final res = await _remoteRepo.deleteArtist(
      artistId: artistId,
      token: token,
    );

    switch (res) {
      case Left(value: final failure):
        state = AsyncValue.error(failure.message, StackTrace.current);

      case Right(value: final ok):
        if (ok) {
          try {
            await _localRepo.removeFromRecentlyOpened(artistId);
          } catch (_) {
            // Se Hive non è inizializzato, non deve bloccare la delete lato UI.
          }

          ref.invalidate(getArtistsProvider);
          ref.invalidate(getArtistProvider(artistId));
        }
        state = AsyncValue.data(ok);
    }
  }

  // ───────────────── LOCAL HELPERS ─────────────────

  /// Lista di artisti aperti di recente (Hive).
  List<ArtistModel> getRecentlyOpenedArtists() {
    return _localRepo.loadRecentlyOpened();
  }

  /// Se in qualche schermata vuoi segnare manualmente che un artista è stato aperto.
  Future<void> markArtistOpened(ArtistModel artist) async {
    await _localRepo.saveRecentlyOpened(artist);
  }
}
