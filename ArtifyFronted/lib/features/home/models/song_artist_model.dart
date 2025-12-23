// lib/features/home/song/model/song_model.dart

// ❌ RIMUOVI questo import se c'è
// import 'package:client/features/home/artist/model/artist_model.dart';

enum SongArtistRole {
  primary,
  featured,
  producer,
  mixer,
  writer,
}

extension SongArtistRoleX on SongArtistRole {
  static SongArtistRole fromString(String value) {
    switch (value) {
      case 'primary':
        return SongArtistRole.primary;
      case 'featured':
        return SongArtistRole.featured;
      case 'producer':
        return SongArtistRole.producer;
      case 'mixer':
        return SongArtistRole.mixer;
      case 'writer':
        return SongArtistRole.writer;
      default:
        return SongArtistRole.primary;
    }
  }

  String get value {
    switch (this) {
      case SongArtistRole.primary:
        return 'primary';
      case SongArtistRole.featured:
        return 'featured';
      case SongArtistRole.producer:
        return 'producer';
      case SongArtistRole.mixer:
        return 'mixer';
      case SongArtistRole.writer:
        return 'writer';
    }
  }
}

/// Modello "join" song–artist.
/// Può essere creato sia da:
/// - SongArtistOut (con nested song / artist)
/// - SongRef semplice (id, song_name, thumbnail_url) usato in ArtistOut.songs
class SongArtistModel {

  /// ruolo (primary, featured, ecc.)
  final SongArtistRole role;

  /// Info SONG (possono arrivare da `song` nested o direttamente)
  final String? songId;
  final String? songName;
  final String? thumbnailUrl;

  /// Info ARTIST (se presenti nella risposta)
  final String artistId;
  final String? artistName;
  final String? artistImageUrl;

  const SongArtistModel({
    required this.role,
    this.songId,
    this.songName,
    this.thumbnailUrl,
    required this.artistId,
    this.artistName,
    this.artistImageUrl,
  });

  factory SongArtistModel.fromMap(Map<String, dynamic> map) {
    // ruolo
    final roleRaw = map['role']?.toString() ?? 'primary';
    final role = SongArtistRoleX.fromString(roleRaw);

    // ------ SONG DATA ------
    String? songId =
        map['song_id']?.toString() ?? map['id']?.toString(); // fallback id
    String? songName = map['song_name']?.toString();
    String? thumb = map['thumbnail_url']?.toString();

    // se esiste nested "song"
    final songRaw = map['song'];
    if (songRaw is Map) {
      final s = Map<String, dynamic>.from(songRaw);
      songId = s['id']?.toString() ?? songId;
      songName = s['song_name']?.toString() ?? songName;
      thumb = s['thumbnail_url']?.toString() ?? thumb;
    }

    // ------ ARTIST DATA ------
    String? artistId = map['artist_id']?.toString();
    String? artistName = map['artist_name']?.toString();
    String? artistImageUrl;

    final artistRaw = map['artist'];
    if (artistRaw is Map) {
      final a = Map<String, dynamic>.from(artistRaw);
      artistId = a['id']?.toString() ?? artistId;
      artistName = a['name']?.toString() ?? artistName;
      artistImageUrl = a['image_url']?.toString();
    }


    return SongArtistModel(
      role: role,
      songId: songId,
      songName: songName,
      thumbnailUrl: thumb,
      artistId: artistId!,
      artistName: artistName,
      artistImageUrl: artistImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.value,
      'song_id': songId,
      'song_name': songName,
      'thumbnail_url': thumbnailUrl,
      'artist_id': artistId,
      'artist_name': artistName,
      'artist_image_url': artistImageUrl,
    };
  }
}
