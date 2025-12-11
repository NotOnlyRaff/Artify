import 'package:client/features/home/album/model/album_model.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_local_repository.g.dart';

@riverpod
AlbumLocalRepository albumLocalRepository(AlbumLocalRepositoryRef ref) {
  return AlbumLocalRepository();
}

class AlbumLocalRepository {
  // Nome del box su Hive per gli album (simmetrico a 'recent_songs')
  static const String _boxName = 'recent_albums';

  Box<dynamic> get _box => Hive.box(_boxName);

  /// Salva/aggiorna un album tra i "recenti"
  /// chiave = id dell'album
  Future<void> saveRecentlyOpened(AlbumModel album) async {
    await _box.put(album.id, album.toJson());
  }

  /// Carica tutti gli album recenti salvati in locale.
  /// L'ordine attuale è quello con cui Hive restituisce le chiavi:
  /// se in futuro vuoi ordinarli per data, puoi farlo qui.
  List<AlbumModel> loadRecentlyOpened() {
    final albums = <AlbumModel>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null) {
        albums.add(AlbumModel.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ));
      }
    }

    return albums;
  }

  /// (Opzionale ma utile) – pulisce il box degli album recenti.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
