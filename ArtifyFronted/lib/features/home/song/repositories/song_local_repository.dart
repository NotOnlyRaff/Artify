import 'package:client/features/home/song/model/song_model.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_local_repository.g.dart';

/// Provider Riverpod per il repository locale dei brani.
/// Lo userai così:
///   final repo = ref.read(songLocalRepositoryProvider);
@riverpod
SongLocalRepository songLocalRepository(SongLocalRepositoryRef ref) {
  return SongLocalRepository();
}

/// Responsabile SOLO della persistenza locale dei brani (recently played, cache, ecc.)
class SongLocalRepository {
  static const String _boxName = 'recent_songs';

  /// Riferimento alla box Hive dove salviamo i brani recenti.
  /// ATTENZIONE: la box deve essere aperta nel main prima di usare questo repo.
  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  /// Salva / aggiorna un brano nella lista dei "recently played".
  ///
  /// 🔹 Chiave = id della song
  /// 🔹 Valore = Map<String, dynamic> generata da SongModel.toJson()
  Future<void> saveRecentlyPlayed(SongModel song) async {
    await _box.put(song.id, song.toJson());
  }

  /// Ritorna la lista dei brani ascoltati di recente.
  ///
  /// Se domani cambiamo il modello (aggiungiamo campi, ecc.),
  /// questa funzione resta valida perché demandiamo tutto a SongModel.fromJson().
  List<SongModel> loadRecentlyPlayed() {
    final songs = <SongModel>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map<String, dynamic>) {
        songs.add(SongModel.fromJson(raw));
      } else if (raw is Map) {
        // fallback nel caso Hive ti restituisca Map<dynamic, dynamic>
        songs.add(
          SongModel.fromJson(
            Map<String, dynamic>.from(raw),
          ),
        );
      }
    }

    return songs;
  }

  /// Rimuove un singolo brano dai "recently played".
  Future<void> removeFromRecentlyPlayed(String songId) async {
    await _box.delete(songId);
  }

  /// Pulisce completamente la lista dei "recently played".
  Future<void> clearRecentlyPlayed() async {
    await _box.clear();
  }
}
