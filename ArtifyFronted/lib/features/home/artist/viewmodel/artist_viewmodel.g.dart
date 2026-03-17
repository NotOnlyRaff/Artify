// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getArtistsHash() => r'8a830f2b47ca65c51a8bae9666c2fadb1de0f546';

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

/// See also [getArtists].
@ProviderFor(getArtists)
const getArtistsProvider = GetArtistsFamily();

/// See also [getArtists].
class GetArtistsFamily extends Family<AsyncValue<List<ArtistModel>>> {
  /// See also [getArtists].
  const GetArtistsFamily();

  /// See also [getArtists].
  GetArtistsProvider call({
    String? search,
    String? songId,
    String? albumId,
  }) {
    return GetArtistsProvider(
      search: search,
      songId: songId,
      albumId: albumId,
    );
  }

  @override
  GetArtistsProvider getProviderOverride(
    covariant GetArtistsProvider provider,
  ) {
    return call(
      search: provider.search,
      songId: provider.songId,
      albumId: provider.albumId,
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
  String? get name => r'getArtistsProvider';
}

/// See also [getArtists].
class GetArtistsProvider extends AutoDisposeFutureProvider<List<ArtistModel>> {
  /// See also [getArtists].
  GetArtistsProvider({
    String? search,
    String? songId,
    String? albumId,
  }) : this._internal(
          (ref) => getArtists(
            ref as GetArtistsRef,
            search: search,
            songId: songId,
            albumId: albumId,
          ),
          from: getArtistsProvider,
          name: r'getArtistsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getArtistsHash,
          dependencies: GetArtistsFamily._dependencies,
          allTransitiveDependencies:
              GetArtistsFamily._allTransitiveDependencies,
          search: search,
          songId: songId,
          albumId: albumId,
        );

  GetArtistsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.search,
    required this.songId,
    required this.albumId,
  }) : super.internal();

  final String? search;
  final String? songId;
  final String? albumId;

  @override
  Override overrideWith(
    FutureOr<List<ArtistModel>> Function(GetArtistsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetArtistsProvider._internal(
        (ref) => create(ref as GetArtistsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        search: search,
        songId: songId,
        albumId: albumId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ArtistModel>> createElement() {
    return _GetArtistsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetArtistsProvider &&
        other.search == search &&
        other.songId == songId &&
        other.albumId == albumId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);
    hash = _SystemHash.combine(hash, songId.hashCode);
    hash = _SystemHash.combine(hash, albumId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetArtistsRef on AutoDisposeFutureProviderRef<List<ArtistModel>> {
  /// The parameter `search` of this provider.
  String? get search;

  /// The parameter `songId` of this provider.
  String? get songId;

  /// The parameter `albumId` of this provider.
  String? get albumId;
}

class _GetArtistsProviderElement
    extends AutoDisposeFutureProviderElement<List<ArtistModel>>
    with GetArtistsRef {
  _GetArtistsProviderElement(super.provider);

  @override
  String? get search => (origin as GetArtistsProvider).search;
  @override
  String? get songId => (origin as GetArtistsProvider).songId;
  @override
  String? get albumId => (origin as GetArtistsProvider).albumId;
}

String _$getArtistHash() => r'335f1e7cb86f383395edddaa90f089812e0cfba6';

/// See also [getArtist].
@ProviderFor(getArtist)
const getArtistProvider = GetArtistFamily();

/// See also [getArtist].
class GetArtistFamily extends Family<AsyncValue<ArtistModel>> {
  /// See also [getArtist].
  const GetArtistFamily();

  /// See also [getArtist].
  GetArtistProvider call(
    String artistId,
  ) {
    return GetArtistProvider(
      artistId,
    );
  }

  @override
  GetArtistProvider getProviderOverride(
    covariant GetArtistProvider provider,
  ) {
    return call(
      provider.artistId,
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
  String? get name => r'getArtistProvider';
}

/// See also [getArtist].
class GetArtistProvider extends AutoDisposeFutureProvider<ArtistModel> {
  /// See also [getArtist].
  GetArtistProvider(
    String artistId,
  ) : this._internal(
          (ref) => getArtist(
            ref as GetArtistRef,
            artistId,
          ),
          from: getArtistProvider,
          name: r'getArtistProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getArtistHash,
          dependencies: GetArtistFamily._dependencies,
          allTransitiveDependencies: GetArtistFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  GetArtistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
  }) : super.internal();

  final String artistId;

  @override
  Override overrideWith(
    FutureOr<ArtistModel> Function(GetArtistRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetArtistProvider._internal(
        (ref) => create(ref as GetArtistRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        artistId: artistId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ArtistModel> createElement() {
    return _GetArtistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetArtistProvider && other.artistId == artistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetArtistRef on AutoDisposeFutureProviderRef<ArtistModel> {
  /// The parameter `artistId` of this provider.
  String get artistId;
}

class _GetArtistProviderElement
    extends AutoDisposeFutureProviderElement<ArtistModel> with GetArtistRef {
  _GetArtistProviderElement(super.provider);

  @override
  String get artistId => (origin as GetArtistProvider).artistId;
}

String _$artistViewModelHash() => r'1e9c81d135e420aa063c3aa453a5e2e47277d21b';

/// See also [ArtistViewModel].
@ProviderFor(ArtistViewModel)
final artistViewModelProvider =
    AutoDisposeNotifierProvider<ArtistViewModel, AsyncValue?>.internal(
  ArtistViewModel.new,
  name: r'artistViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$artistViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ArtistViewModel = AutoDisposeNotifier<AsyncValue?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
