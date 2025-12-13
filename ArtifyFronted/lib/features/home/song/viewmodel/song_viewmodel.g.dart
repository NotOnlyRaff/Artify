// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getAllSongsHash() => r'ebb70a5121ed26026cc0b97463e348e024256a06';

/// ───────────────── PROVIDER LISTA SONG ─────────────────
///
/// Copied from [getAllSongs].
@ProviderFor(getAllSongs)
final getAllSongsProvider = AutoDisposeFutureProvider<List<SongModel>>.internal(
  getAllSongs,
  name: r'getAllSongsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$getAllSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GetAllSongsRef = AutoDisposeFutureProviderRef<List<SongModel>>;
String _$getFavSongsHash() => r'1a1a2e2639697f44ecb45b503938ca1d168e4c18';

/// See also [getFavSongs].
@ProviderFor(getFavSongs)
final getFavSongsProvider = AutoDisposeFutureProvider<List<SongModel>>.internal(
  getFavSongs,
  name: r'getFavSongsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$getFavSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GetFavSongsRef = AutoDisposeFutureProviderRef<List<SongModel>>;
String _$songViewModelHash() => r'55ee2f3f8c28ed79911f716c5752d89133bd6a0f';

/// ───────────────── VIEWMODEL CANZONI ─────────────────
/// Gestisce:
/// - upload song
/// - delete song
/// - toggle favorite
/// - recently played (via SongLocalRepository)
///
/// Copied from [SongViewModel].
@ProviderFor(SongViewModel)
final songViewModelProvider =
    AutoDisposeNotifierProvider<SongViewModel, AsyncValue?>.internal(
  SongViewModel.new,
  name: r'songViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$songViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SongViewModel = AutoDisposeNotifier<AsyncValue?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
