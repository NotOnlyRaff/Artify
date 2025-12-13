// lib/features/home/models/song_model.dart

import 'song_artist_model.dart';

// lib/features/home/song/model/song_model.dart

class SongModel {
  final String id;
  final String songName;
  final String songUrl;
  final String? thumbnailUrl;
  final DateTime releaseDate;
  final String composerName;
  final String? producerName;
  final String? genre;
  final String? lyrics;
  final String? mood;
  final int? durationSeconds;

  // 👇 questo è quello che la search usa
  final List<SongArtistModel> artists;

  const SongModel({
    required this.id,
    required this.songName,
    required this.songUrl,
    this.thumbnailUrl,
    required this.releaseDate,
    required this.composerName,
    this.producerName,
    this.genre,
    this.lyrics,
    this.mood,
    this.durationSeconds,
    this.artists = const [],
  });

    SongModel copyWith({
    String? id,
    String? songName,
    String? songUrl,
    String? thumbnailUrl,
    DateTime? releaseDate,
    String? composerName,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    int? durationSeconds,
    List<SongArtistModel>? artists,
  }) {
    return SongModel(
      id: id ?? this.id,
      songName: songName ?? this.songName,
      songUrl: songUrl ?? this.songUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      composerName: composerName ?? this.composerName,
      producerName: producerName ?? this.producerName,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
      mood: mood ?? this.mood,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      artists: artists ?? this.artists,
    );
  }

factory SongModel.fromMap(Map<String, dynamic> map) {
    final rawLinks = map['artist_links'];

    final List<SongArtistModel> parsedLinks;
    if (rawLinks is List) {
      parsedLinks = rawLinks
          .whereType<Map>()
          .map(
            (e) => SongArtistModel.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } else {
      parsedLinks = const [];
    }

    return SongModel(
      id: map['id'] as String,
      songName: map['song_name'] as String,
      songUrl: map['song_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      releaseDate: DateTime.parse(map['release_date'] as String),
      composerName: map['composer_name'] as String,
      producerName: map['producer_name'] as String?,
      genre: map['genre'] as String?,
      lyrics: map['lyrics'] as String?,
      mood: map['mood'] as String?,
      durationSeconds: map['duration_seconds'] as int?,
      artists: parsedLinks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'song_name': songName,
      'song_url': songUrl,
      'thumbnail_url': thumbnailUrl,
      'release_date': releaseDate.toIso8601String(),
      'composer_name': composerName,
      'producer_name': producerName,
      'genre': genre,
      'lyrics': lyrics,
      'mood': mood,
      'duration_seconds': durationSeconds,
      // se ti serve salvarlo in locale, mappa artists anche qui
    };
  }
  
  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      songName: json['song_name'] as String,
      songUrl: json['song_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      releaseDate: DateTime.parse(json['release_date'] as String),
      composerName: json['composer_name'] as String,
      producerName: json['producer_name'] as String?,
      genre: json['genre'] as String?,
      lyrics: json['lyrics'] as String?,
      mood: json['mood'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      artists: (json['artist_links'] as List<dynamic>? ?? [])
          .map(
            (e) => SongArtistModel.fromMap(e as Map<String, dynamic>),
          )
          .toList(),
    );
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
        ')';
  }
}
