// lib/features/home/models/song_model.dart

import '../../album/model/album_model.dart';
import 'song_artist_model.dart'; // 👈 nuovo import

class SongModel {
  final String id;
  final String songName;
  final String songUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;

  final DateTime? releaseDate;
  final String composerName;
  final String? beatProducerName;
  final String? genre;
  final String? lyrics;
  final String? mood;

  final List<SongArtistLinkModel> artists; // dal file separato
  final List<AlbumModel> albums;

  const SongModel({
    required this.id,
    required this.songName,
    required this.songUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.releaseDate,
    required this.composerName,
    this.beatProducerName,
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
    String? beatProducerName,
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
      beatProducerName: beatProducerName ?? this.beatProducerName,
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
      beatProducerName: map['beat_producer_name'] as String?,
      genre: map['genre'] as String?,
      lyrics: map['lyrics'] as String?,
      mood: map['mood'] as String?,
      artists: (map['artists'] as List<dynamic>? ?? [])
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
      beatProducerName: json['beat_producer_name'] as String?,
      genre: json['genre'] as String?,
      lyrics: json['lyrics'] as String?,
      mood: json['mood'] as String?,
      artists: (json['artists'] as List<dynamic>? ?? [])
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
      'beat_producer_name': beatProducerName,
      'genre': genre,
      'lyrics': lyrics,
      'mood': mood,
      'artists': artists.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'SongModel(id: $id, songName: $songName, songUrl: $songUrl, thumbnailUrl: $thumbnailUrl, durationSeconds: $durationSeconds, releaseDate: $releaseDate, composerName: $composerName, beatProducerName: $beatProducerName, genre: $genre, lyrics: $lyrics, mood: $mood, artists: $artists, albums: $albums)';
  }
}
