import 'package:client/features/home/album/model/album_model.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_local_repository.g.dart';

@riverpod
AlbumLocalRepository albumLocalRepository(AlbumLocalRepositoryRef ref) {
  return AlbumLocalRepository();
}

class AlbumLocalRepository {
  static const String _boxName = 'recent_albums';

  // FIX: non accede direttamente a Hive.box() — crasha se la box non è aperta.
  // Usa isBoxOpen come guard difensivo, speculare a ArtistLocalRepository.
  bool get _isOpen => Hive.isBoxOpen(_boxName);

  Box get _box {
    if (!_isOpen)
      throw HiveError('Box $_boxName is not open. Call Hive.openBox first.');
    return Hive.box(_boxName);
  }

  Future<void> saveRecentlyOpened(AlbumModel album) async {
    if (!_isOpen) return;
    await _box.put(album.id, album.toJson());
  }

  List<AlbumModel> loadRecentlyOpened() {
    if (!_isOpen) return [];

    final albums = <AlbumModel>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null) {
        try {
          albums
              .add(AlbumModel.fromJson(Map<String, dynamic>.from(raw as Map)));
        } catch (_) {
          // Entry corrotta — la saltiamo silenziosamente.
        }
      }
    }
    // Ordine inverso = più recente prima (speculare a ArtistLocalRepository).
    return albums.reversed.toList();
  }

  Future<void> clearAll() async {
    if (!_isOpen) return;
    await _box.clear();
  }
}
