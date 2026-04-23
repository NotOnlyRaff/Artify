// lib/features/home/song/model/song_artist_model.dart

enum SongArtistRole {
  primary,
  featured,
  producer,
  mixer,
  writer;

  static SongArtistRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'featured':
        return SongArtistRole.featured;
      case 'producer':
        return SongArtistRole.producer;
      case 'mixer':
        return SongArtistRole.mixer;
      case 'writer':
        return SongArtistRole.writer;
      case 'primary':
      default:
        return SongArtistRole.primary;
    }
  }

  String get value => name;
}

/// Modello per una riga song–artist con ruolo.
/// Corrisponde a SongArtistOut del backend.
///
/// MODIFICHE rispetto alla versione precedente:
/// - Aggiunto [linkId]: l'id della riga song_artists, necessario per
///   UPDATE e DELETE tramite /song-artists/{link_id}.
/// - [artistId] non usa più ! (null assertion) — gestisce il caso null in modo sicuro.
class SongArtistModel {
  /// Id della riga song_artists — necessario per update/delete del link.
  final String? linkId;

  final SongArtistRole role;

  // Info SONG
  final String? songId;
  final String? songName;
  final String? thumbnailUrl;

  // Info ARTIST
  final String? artistId;
  final String? artistName;
  final String? artistImageUrl;

  const SongArtistModel({
    this.linkId,
    required this.role,
    this.songId,
    this.songName,
    this.thumbnailUrl,
    this.artistId,
    this.artistName,
    this.artistImageUrl,
  });

  factory SongArtistModel.fromMap(Map<String, dynamic> map) {
    final role = SongArtistRole.fromString(map['role']?.toString());

    // Song data (da nested 'song' o campi flat)
    String? songId = map['song_id']?.toString();
    String? songName = map['song_name']?.toString();
    String? thumbnailUrl = map['thumbnail_url']?.toString();

    final rawSong = map['song'];
    if (rawSong is Map) {
      final s = Map<String, dynamic>.from(rawSong);
      songId = s['id']?.toString() ?? songId;
      songName = s['song_name']?.toString() ?? songName;
      thumbnailUrl = s['thumbnail_url']?.toString() ?? thumbnailUrl;
    }

    // Artist data (da nested 'artist' o campi flat)
    String? artistId = map['artist_id']?.toString();
    String? artistName = map['artist_name']?.toString();
    String? artistImageUrl = map['artist_image_url']?.toString();

    final rawArtist = map['artist'];
    if (rawArtist is Map) {
      final a = Map<String, dynamic>.from(rawArtist);
      artistId = a['id']?.toString() ?? artistId;
      artistName = a['name']?.toString() ?? artistName;
      artistImageUrl = a['image_url']?.toString() ?? artistImageUrl;
    }

    return SongArtistModel(
      linkId: map['id']?.toString(),
      role: role,
      songId: songId,
      songName: songName,
      thumbnailUrl: thumbnailUrl,
      artistId: artistId,
      artistName: artistName,
      artistImageUrl: artistImageUrl,
    );
  }

  SongArtistModel copyWith({
    String? linkId,
    SongArtistRole? role,
    String? songId,
    String? songName,
    String? thumbnailUrl,
    String? artistId,
    String? artistName,
    String? artistImageUrl,
  }) {
    return SongArtistModel(
      linkId: linkId ?? this.linkId,
      role: role ?? this.role,
      songId: songId ?? this.songId,
      songName: songName ?? this.songName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      artistImageUrl: artistImageUrl ?? this.artistImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (linkId != null) 'id': linkId,
      'role': role.value,
      if (songId != null) 'song_id': songId,
      if (songName != null) 'song_name': songName,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (artistId != null) 'artist_id': artistId,
      if (artistName != null) 'artist_name': artistName,
      if (artistImageUrl != null) 'artist_image_url': artistImageUrl,
    };
  }

  @override
  String toString() =>
      'SongArtistModel(linkId: $linkId, role: ${role.value}, artistId: $artistId, artistName: $artistName)';
}
