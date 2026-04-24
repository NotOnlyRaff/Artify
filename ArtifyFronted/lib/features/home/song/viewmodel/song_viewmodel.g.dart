// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getAllSongsHash() => r'374b5223eeaa8ef4a390ee47a49ae2976144f610';

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
String _$getFavSongsHash() => r'2d3482748e2322fde870927b2d4ac58112a8b666';

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
String _$getSongHash() => r'bb43f6a03621765a1578d5ec6e37f564c5e23b6a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// FIX: aggiunto provider per fetch di una singola song by ID.
/// Usato da artist_actions_row per il fetch-and-play.
///
/// Copied from [getSong].
@ProviderFor(getSong)
const getSongProvider = GetSongFamily();

/// FIX: aggiunto provider per fetch di una singola song by ID.
/// Usato da artist_actions_row per il fetch-and-play.
///
/// Copied from [getSong].
class GetSongFamily extends Family<AsyncValue<SongModel>> {
  /// FIX: aggiunto provider per fetch di una singola song by ID.
  /// Usato da artist_actions_row per il fetch-and-play.
  ///
  /// Copied from [getSong].
  const GetSongFamily();

  /// FIX: aggiunto provider per fetch di una singola song by ID.
  /// Usato da artist_actions_row per il fetch-and-play.
  ///
  /// Copied from [getSong].
  GetSongProvider call(
    String songId,
  ) {
    return GetSongProvider(
      songId,
    );
  }

  @override
  GetSongProvider getProviderOverride(
    covariant GetSongProvider provider,
  ) {
    return call(
      provider.songId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getSongProvider';
}

/// FIX: aggiunto provider per fetch di una singola song by ID.
/// Usato da artist_actions_row per il fetch-and-play.
///
/// Copied from [getSong].
class GetSongProvider extends AutoDisposeFutureProvider<SongModel> {
  /// FIX: aggiunto provider per fetch di una singola song by ID.
  /// Usato da artist_actions_row per il fetch-and-play.
  ///
  /// Copied from [getSong].
  GetSongProvider(
    String songId,
  ) : this._internal(
          (ref) => getSong(
            ref as GetSongRef,
            songId,
          ),
          from: getSongProvider,
          name: r'getSongProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getSongHash,
          dependencies: GetSongFamily._dependencies,
          allTransitiveDependencies: GetSongFamily._allTransitiveDependencies,
          songId: songId,
        );

  GetSongProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.songId,
  }) : super.internal();

  final String songId;

  @override
  Override overrideWith(
    FutureOr<SongModel> Function(GetSongRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetSongProvider._internal(
        (ref) => create(ref as GetSongRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        songId: songId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SongModel> createElement() {
    return _GetSongProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetSongProvider && other.songId == songId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, songId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetSongRef on AutoDisposeFutureProviderRef<SongModel> {
  /// The parameter `songId` of this provider.
  String get songId;
}

class _GetSongProviderElement
    extends AutoDisposeFutureProviderElement<SongModel> with GetSongRef {
  _GetSongProviderElement(super.provider);

  @override
  String get songId => (origin as GetSongProvider).songId;
}

String _$songViewModelHash() => r'14f5cf85f1da5daef5c90a61709b13aeade4d9cd';

/// ───────────────── VIEWMODEL CANZONI ─────────────────
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
