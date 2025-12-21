// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getAllAlbumsHash() => r'49097120c0c231bb9b4bf4742d9a681cefbd220b';

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

/// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
///
/// Uso:
///   ref.watch(getAllAlbumsProvider());
///   ref.watch(getAllAlbumsProvider(artistId: '...'));
///
/// Copied from [getAllAlbums].
@ProviderFor(getAllAlbums)
const getAllAlbumsProvider = GetAllAlbumsFamily();

/// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
///
/// Uso:
///   ref.watch(getAllAlbumsProvider());
///   ref.watch(getAllAlbumsProvider(artistId: '...'));
///
/// Copied from [getAllAlbums].
class GetAllAlbumsFamily extends Family<AsyncValue<List<AlbumModel>>> {
  /// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
  ///
  /// Uso:
  ///   ref.watch(getAllAlbumsProvider());
  ///   ref.watch(getAllAlbumsProvider(artistId: '...'));
  ///
  /// Copied from [getAllAlbums].
  const GetAllAlbumsFamily();

  /// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
  ///
  /// Uso:
  ///   ref.watch(getAllAlbumsProvider());
  ///   ref.watch(getAllAlbumsProvider(artistId: '...'));
  ///
  /// Copied from [getAllAlbums].
  GetAllAlbumsProvider call({
    String? artistId,
  }) {
    return GetAllAlbumsProvider(
      artistId: artistId,
    );
  }

  @override
  GetAllAlbumsProvider getProviderOverride(
    covariant GetAllAlbumsProvider provider,
  ) {
    return call(
      artistId: provider.artistId,
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
  String? get name => r'getAllAlbumsProvider';
}

/// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
///
/// Uso:
///   ref.watch(getAllAlbumsProvider());
///   ref.watch(getAllAlbumsProvider(artistId: '...'));
///
/// Copied from [getAllAlbums].
class GetAllAlbumsProvider extends AutoDisposeFutureProvider<List<AlbumModel>> {
  /// ───────────────── PROVIDER: LISTA ALBUM ─────────────────
  ///
  /// Uso:
  ///   ref.watch(getAllAlbumsProvider());
  ///   ref.watch(getAllAlbumsProvider(artistId: '...'));
  ///
  /// Copied from [getAllAlbums].
  GetAllAlbumsProvider({
    String? artistId,
  }) : this._internal(
          (ref) => getAllAlbums(
            ref as GetAllAlbumsRef,
            artistId: artistId,
          ),
          from: getAllAlbumsProvider,
          name: r'getAllAlbumsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getAllAlbumsHash,
          dependencies: GetAllAlbumsFamily._dependencies,
          allTransitiveDependencies:
              GetAllAlbumsFamily._allTransitiveDependencies,
          artistId: artistId,
        );

  GetAllAlbumsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.artistId,
  }) : super.internal();

  final String? artistId;

  @override
  Override overrideWith(
    FutureOr<List<AlbumModel>> Function(GetAllAlbumsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetAllAlbumsProvider._internal(
        (ref) => create(ref as GetAllAlbumsRef),
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
  AutoDisposeFutureProviderElement<List<AlbumModel>> createElement() {
    return _GetAllAlbumsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetAllAlbumsProvider && other.artistId == artistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, artistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetAllAlbumsRef on AutoDisposeFutureProviderRef<List<AlbumModel>> {
  /// The parameter `artistId` of this provider.
  String? get artistId;
}

class _GetAllAlbumsProviderElement
    extends AutoDisposeFutureProviderElement<List<AlbumModel>>
    with GetAllAlbumsRef {
  _GetAllAlbumsProviderElement(super.provider);

  @override
  String? get artistId => (origin as GetAllAlbumsProvider).artistId;
}

String _$getAlbumHash() => r'794087249b1c48f2eaba740f40927fb591dadcf6';

/// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
///
/// Uso:
///   ref.watch(getAlbumProvider(albumId));
///
/// Copied from [getAlbum].
@ProviderFor(getAlbum)
const getAlbumProvider = GetAlbumFamily();

/// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
///
/// Uso:
///   ref.watch(getAlbumProvider(albumId));
///
/// Copied from [getAlbum].
class GetAlbumFamily extends Family<AsyncValue<AlbumModel>> {
  /// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
  ///
  /// Uso:
  ///   ref.watch(getAlbumProvider(albumId));
  ///
  /// Copied from [getAlbum].
  const GetAlbumFamily();

  /// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
  ///
  /// Uso:
  ///   ref.watch(getAlbumProvider(albumId));
  ///
  /// Copied from [getAlbum].
  GetAlbumProvider call(
    String albumId,
  ) {
    return GetAlbumProvider(
      albumId,
    );
  }

  @override
  GetAlbumProvider getProviderOverride(
    covariant GetAlbumProvider provider,
  ) {
    return call(
      provider.albumId,
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
  String? get name => r'getAlbumProvider';
}

/// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
///
/// Uso:
///   ref.watch(getAlbumProvider(albumId));
///
/// Copied from [getAlbum].
class GetAlbumProvider extends AutoDisposeFutureProvider<AlbumModel> {
  /// ───────────────── PROVIDER: SINGOLO ALBUM ───────────────
  ///
  /// Uso:
  ///   ref.watch(getAlbumProvider(albumId));
  ///
  /// Copied from [getAlbum].
  GetAlbumProvider(
    String albumId,
  ) : this._internal(
          (ref) => getAlbum(
            ref as GetAlbumRef,
            albumId,
          ),
          from: getAlbumProvider,
          name: r'getAlbumProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getAlbumHash,
          dependencies: GetAlbumFamily._dependencies,
          allTransitiveDependencies: GetAlbumFamily._allTransitiveDependencies,
          albumId: albumId,
        );

  GetAlbumProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.albumId,
  }) : super.internal();

  final String albumId;

  @override
  Override overrideWith(
    FutureOr<AlbumModel> Function(GetAlbumRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetAlbumProvider._internal(
        (ref) => create(ref as GetAlbumRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        albumId: albumId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AlbumModel> createElement() {
    return _GetAlbumProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetAlbumProvider && other.albumId == albumId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, albumId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GetAlbumRef on AutoDisposeFutureProviderRef<AlbumModel> {
  /// The parameter `albumId` of this provider.
  String get albumId;
}

class _GetAlbumProviderElement
    extends AutoDisposeFutureProviderElement<AlbumModel> with GetAlbumRef {
  _GetAlbumProviderElement(super.provider);

  @override
  String get albumId => (origin as GetAlbumProvider).albumId;
}

String _$albumViewModelHash() => r'db412ed9ee948490a2982b97300c74c8b706fe51';

/// ───────────────── VIEWMODEL MUTAZIONI ALBUM ─────────────
///
/// Copied from [AlbumViewModel].
@ProviderFor(AlbumViewModel)
final albumViewModelProvider =
    AutoDisposeNotifierProvider<AlbumViewModel, AsyncValue?>.internal(
  AlbumViewModel.new,
  name: r'albumViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$albumViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AlbumViewModel = AutoDisposeNotifier<AsyncValue?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
