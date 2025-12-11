// lib/features/home/models/song_model.dart

import '../../album/model/album_model.dart';
import 'song_artist_model.dart';

class SongModel {
  final String id;
  final String songName;
  final String songUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;

  final DateTime? releaseDate;
  final String composerName;
  final String? producerName;     // 👈 allineato a producer_name
  final String? genre;
  final String? lyrics;
  final String? mood;

  /// Lista dei link Song–Artist (SongArtistLinkModel), come da backend (SongArtistOut)
  final List<SongArtistLinkModel> artists;
  final List<AlbumModel> albums;

  const SongModel({
    required this.id,
    required this.songName,
    required this.songUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.releaseDate,
    required this.composerName,
    this.producerName,
    this.genre,
    this.lyrics,
    this.mood,
    this.artists = const [],
    this.albums = const [],
  });

  SongModel copyWith({
    String? id,
    String? songName,
    String? songUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    DateTime? releaseDate,
    String? composerName,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<SongArtistLinkModel>? artists,
    List<AlbumModel>? albums,
  }) {
    return SongModel(
      id: id ?? this.id,
      songName: songName ?? this.songName,
      songUrl: songUrl ?? this.songUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      releaseDate: releaseDate ?? this.releaseDate,
      composerName: composerName ?? this.composerName,
      producerName: producerName ?? this.producerName,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
      mood: mood ?? this.mood,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
    );
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      songName: map['song_name'] as String,
      songUrl: map['song_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      durationSeconds: map['duration_seconds'] as int?,
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'] as String)
          : null,
      composerName: map['composer_name'] as String,
      producerName: map['producer_name'] as String?,   // 👈 chiave corretta
      genre: map['genre'] as String?,
      lyrics: map['lyrics'] as String?,
      mood: map['mood'] as String?,
      // 👇 backend: SongOut.artist_links
      artists: (map['artist_links'] as List<dynamic>? ?? [])
          .map(
            (e) => SongArtistLinkModel.fromMap(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      albums: (map['albums'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumModel.fromMap(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      songName: json['song_name'] as String,
      songUrl: json['song_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
      composerName: json['composer_name'] as String,
      producerName: json['producer_name'] as String?,  // 👈 chiave corretta
      genre: json['genre'] as String?,
      lyrics: json['lyrics'] as String?,
      mood: json['mood'] as String?,
      // 👇 qui leggiamo artist_links, non artists
      artists: (json['artist_links'] as List<dynamic>? ?? [])
          .map(
            (e) => SongArtistLinkModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      albums: (json['albums'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'song_name': songName,
      'song_url': songUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'release_date': releaseDate?.toIso8601String(),
      'composer_name': composerName,
      'producer_name': producerName,                 // 👈 allineato al backend
      'genre': genre,
      'lyrics': lyrics,
      'mood': mood,
      'artist_links': artists.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'SongModel('
        'id: $id, '
        'songName: $songName, '
        'songUrl: $songUrl, '
        'thumbnailUrl: $thumbnailUrl, '
        'durationSeconds: $durationSeconds, '
        'releaseDate: $releaseDate, '
        'composerName: $composerName, '
        'producerName: $producerName, '
        'genre: $genre, '
        'lyrics: $lyrics, '
        'mood: $mood, '
        'artists: $artists, '
        'albums: $albums'
        ')';
  }
}
