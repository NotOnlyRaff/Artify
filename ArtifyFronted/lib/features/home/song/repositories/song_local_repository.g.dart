// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_local_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$songLocalRepositoryHash() =>
    r'75c1f54411482862ee9ddd0c52c24c83206f3b7e';

/// Provider Riverpod per il repository locale dei brani.
/// Lo userai così:
///   final repo = ref.read(songLocalRepositoryProvider);
///
/// Copied from [songLocalRepository].
@ProviderFor(songLocalRepository)
final songLocalRepositoryProvider =
    AutoDisposeProvider<SongLocalRepository>.internal(
  songLocalRepository,
  name: r'songLocalRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$songLocalRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SongLocalRepositoryRef = AutoDisposeProviderRef<SongLocalRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
