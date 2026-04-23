// lib/features/home/song/widget/songPage/song_artist_formatter.dart

import 'package:client/features/home/song/model/song_model.dart';

/// Extension su SongModel per formattare i nomi artista.
/// Usato in latest_today_section, recently_played_section, music_slab, ecc.
///
/// Dopo la migrazione, song.artists è List<SongArtistModel> dove ogni
/// elemento ha artistName (da nested 'artist') e role.
extension SongArtistFormatter on SongModel {
  /// Restituisce i nomi degli artisti formattati come stringa.
  /// Es: "Drake, Rihanna feat. Lil Wayne"
  ///
  /// Se non ci sono artisti, restituisce composerName come fallback,
  /// oppure 'Unknown artist'.
  String get formattedArtists {
    if (artists.isEmpty) {
      return composerName ?? 'Unknown artist';
    }

    // Separa primary/featured
    final primary = artists
        .where((a) => a.artistName != null && a.role.value == 'primary')
        .map((a) => a.artistName!)
        .toList();

    final featured = artists
        .where((a) => a.artistName != null && a.role.value != 'primary')
        .map((a) => a.artistName!)
        .toList();

    // Se nessuno è primary, mostra tutti come elenco piatto
    if (primary.isEmpty) {
      final all = artists
          .where((a) => a.artistName != null)
          .map((a) => a.artistName!)
          .toList();
      return all.isEmpty ? (composerName ?? 'Unknown artist') : all.join(', ');
    }

    final buffer = StringBuffer(primary.join(', '));
    if (featured.isNotEmpty) {
      buffer.write(' feat. ${featured.join(', ')}');
    }
    return buffer.toString();
  }
}
