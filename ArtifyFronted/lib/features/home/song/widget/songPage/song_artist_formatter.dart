// lib/features/home/song/view/utils/song_artist_formatter.dart

import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';

extension SongArtistFormatter on SongModel {
  String get formattedArtists {
    if (artists.isEmpty) {
      return 'Unknown artist';
    }

    final primaryLinks =
        artists.where((link) => link.role == SongArtistRole.primary).toList();

    final linksToUse = primaryLinks.isNotEmpty ? primaryLinks : artists;

    final names = linksToUse
        .map((link) => (link.artistName ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) return 'Unknown artist';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} & ${names[1]}';
    if (names.length == 3) {
      return '${names[0]}, ${names[1]} & ${names[2]}';
    }

    final othersCount = names.length - 2;
    return '${names[0]}, ${names[1]} +$othersCount';
  }
}
