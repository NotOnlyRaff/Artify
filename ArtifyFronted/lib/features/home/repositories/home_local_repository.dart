import 'package:client/features/home/models/song_model.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_local_repository.g.dart';

@riverpod
HomeLocalRepository homeLocalRepository(HomeLocalRepositoryRef ref) {
  return HomeLocalRepository();
}

class HomeLocalRepository {
  static const String _boxName = 'recent_songs';

  Box<dynamic> get _box => Hive.box(_boxName);

  void uploadLocalSong(SongModel song) {
    // salva il JSON della song, chiave = id del brano
    _box.put(song.id, song.toJson());
  }

  List<SongModel> loadSongs() {
    final songs = <SongModel>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null) {
        songs.add(SongModel.fromJson(raw));
      }
    }

    return songs;
  }
}
