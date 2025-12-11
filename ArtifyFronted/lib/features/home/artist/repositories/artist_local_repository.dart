import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'artist_local_repository.g.dart';

@riverpod
ArtistLocalRepository artistLocalRepository(ArtistLocalRepositoryRef ref) {
  return ArtistLocalRepository();
}

/// Responsabile SOLO della persistenza locale degli artisti
/// (ad es. “recently opened artists”, cache, ecc.)
class ArtistLocalRepository {
  static const String _boxName = 'recent_artists';

  /// Box Hive per gli artisti recenti.
  /// NB: va aperta nel main prima di usare questo repo.
  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  Box _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      throw HiveError('Box $_boxName is not open. Call Hive.openBox first.');
    }
    return Hive.box(_boxName);
  }

  /// Rimuove un singolo artista dai “recently opened”.
  Future<void> removeFromRecentlyOpened(String artistId) async {
    await _box.delete(artistId);
  }

  List<ArtistModel> loadRecentlyOpened() {
    if (!Hive.isBoxOpen(_boxName)) return [];

    final box = Hive.box(_boxName);
    return box.values
        .whereType<Map>()
        .map((e) => ArtistModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveRecentlyOpened(ArtistModel artist) async {
    if (!Hive.isBoxOpen(_boxName)) return; // fallback: niente crash

    final box = _getBox();
    await box.put(
      artist.id,
      artist.toJson(), // se hai toJson(), altrimenti adatta
    );
  }

  Future<void> clearAll() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = _getBox();
    await box.clear();
  }
}
