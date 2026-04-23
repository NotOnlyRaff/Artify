// lib/features/home/album/model/album_model.dart

import 'package:client/features/home/models/album_artist_model.dart';

/// Traccia di un album — corrisponde ad AlbumSongLinkOut del backend.
/// { "song_id": "...", "track_number": 1, "song": { "id": "...", "song_name": "...", "thumbnail_url": "..." } }
class AlbumTrack {
  final String songId;
  final int? trackNumber;
  final String? songName;
  final String? thumbnailUrl;

  const AlbumTrack({
    required this.songId,
    this.trackNumber,
    this.songName,
    this.thumbnailUrl,
  });

  factory AlbumTrack.fromMap(Map<String, dynamic> map) {
    String songId = map['song_id']?.toString() ?? '';
    String? songName;
    String? thumbnailUrl;

    final rawSong = map['song'];
    if (rawSong is Map) {
      final s = Map<String, dynamic>.from(rawSong);
      songId = s['id']?.toString() ?? songId;
      songName = s['song_name']?.toString();
      thumbnailUrl = s['thumbnail_url']?.toString();
    }

    int? trackNumber;
    final raw = map['track_number'];
    if (raw is int) trackNumber = raw;
    if (raw is String) trackNumber = int.tryParse(raw);

    return AlbumTrack(
      songId: songId,
      trackNumber: trackNumber,
      songName: songName,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'song_id': songId,
        'track_number': trackNumber,
        'song': {
          'id': songId,
          'song_name': songName,
          'thumbnail_url': thumbnailUrl,
        },
      };
}

/// Modello album — corrisponde ad AlbumOut del backend.
///
/// MODIFICHE rispetto alla versione precedente:
/// - Rimosso totalTracks: il campo è stato eliminato dal model backend.
///   Per il conteggio tracce usa tracks.length.
/// - artists ora parsato da album_artist_links (non più da 'artists').
/// - Aggiunto tracks (List<AlbumTrack>) da album_song_links.
/// - fromJson e fromMap unificati.
class AlbumModel {
  final String id;
  final String title;
  final String? coverUrl;
  final DateTime? releaseDate;
  final String? label;
  final String? albumType;
  final String? genre;

  /// Artisti dell'album, da album_artist_links.
  final List<AlbumArtistModel> artists;

  /// Tracce dell'album in ordine, da album_song_links.
  final List<AlbumTrack> tracks;

  /// Calcolato a runtime — non più un campo DB.
  int get totalTracks => tracks.length;

  const AlbumModel({
    required this.id,
    required this.title,
    this.coverUrl,
    this.releaseDate,
    this.label,
    this.albumType,
    this.genre,
    this.artists = const [],
    this.tracks = const [],
  });

  AlbumModel copyWith({
    String? id,
    String? title,
    String? coverUrl,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    List<AlbumArtistModel>? artists,
    List<AlbumTrack>? tracks,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      label: label ?? this.label,
      albumType: albumType ?? this.albumType,
      genre: genre ?? this.genre,
      artists: artists ?? this.artists,
      tracks: tracks ?? this.tracks,
    );
  }

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    // FIX: legge album_artist_links invece di 'artists'
    final rawArtists = map['album_artist_links'] ?? map['artists'] ?? const [];
    final artists = (rawArtists as List)
        .map((e) =>
            AlbumArtistModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    // FIX: legge album_song_links invece di campo non presente
    final rawTracks = map['album_song_links'] ?? map['tracks'] ?? const [];
    final tracks = (rawTracks as List)
        .map((e) => AlbumTrack.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    return AlbumModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      coverUrl: map['cover_url']?.toString(),
      releaseDate: map['release_date'] != null
          ? DateTime.tryParse(map['release_date'].toString())
          : null,
      label: map['label']?.toString(),
      albumType: map['album_type']?.toString(),
      genre: map['genre']?.toString(),
      artists: artists,
      tracks: tracks,
    );
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) =>
      AlbumModel.fromMap(json);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'release_date': releaseDate?.toIso8601String(),
      'label': label,
      'album_type': albumType,
      'genre': genre,
      'album_artist_links': artists.map((a) => a.toMap()).toList(),
      'album_song_links': tracks.map((t) => t.toMap()).toList(),
    };
  }

  @override
  String toString() =>
      'AlbumModel(id: $id, title: $title, tracks: ${tracks.length}, artists: ${artists.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumModel &&
          other.id == id &&
          other.title == title &&
          other.coverUrl == coverUrl &&
          other.releaseDate == releaseDate &&
          other.label == label &&
          other.albumType == albumType;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      coverUrl.hashCode ^
      releaseDate.hashCode ^
      label.hashCode ^
      albumType.hashCode;
}
