// lib/features/home/models/song_model.dart

import 'package:client/features/home/album/model/album_model.dart';

import '../../models/song_artist_model.dart';

// lib/features/home/song/model/song_model.dart

class SongModel {
  final String id;
  final String songName;
  final String songUrl;
  final String? thumbnailUrl;
  final DateTime? releaseDate;
  final String composerName;
  final String? producerName;
  final String? genre;
  final String? lyrics;
  final String? mood;
  final int? durationSeconds;

  // 👇 questo è quello che la search usa
  final List<SongArtistModel> artists;
  final List<AlbumModel> albums;

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
    this.albums = const [],
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
    List<AlbumModel>? albums,
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
      albums: albums ?? this.albums,
    );
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    final rawArtistLinks =
        map['artist_links'] ?? map['song_artist_links'] ?? map['artists'];

    final List<SongArtistModel> artists =
        (rawArtistLinks as List<dynamic>? ?? [])
            .map(
              (e) => SongArtistModel.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
    return SongModel(
      id: map['id']?.toString() ?? '',
      songUrl: map['song_url']?.toString() ?? '',

      // thumbnail_url può essere null o mancante
      thumbnailUrl:
          map['thumbnail_url'] == null ? null : map['thumbnail_url'].toString(),

      songName: map['song_name']?.toString() ?? '',

      // release_date potrebbe mancare nel JSON "compatto" dentro ArtistOut
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'].toString())
          : DateTime.fromMillisecondsSinceEpoch(0), // fallback safe

      composerName: map['composer_name']?.toString() ?? '',
      producerName:
          map['producer_name'] == null ? null : map['producer_name'].toString(),
      genre: map['genre'] == null ? null : map['genre'].toString(),
      lyrics: map['lyrics'] == null ? null : map['lyrics'].toString(),
      mood: map['mood'] == null ? null : map['mood'].toString(),

      durationSeconds: (() {
        final raw = map['duration_seconds'];
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
        return null;
      })(),

      // Se in questa risposta il backend NON include gli artisti annidati,
      // 'artists' sarà [] e va benissimo.
      artists: artists,

      albums: (map['albums'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumModel.fromMap(
              Map<String, dynamic>.from(e as Map),
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
      'release_date': releaseDate?.toIso8601String(),
      'composer_name': composerName,
      'producer_name': producerName,
      'genre': genre,
      'lyrics': lyrics,
      'mood': mood,
      'duration_seconds': durationSeconds,
      'artist_links': artists.map((a) => a.toMap()).toList(),
      'albums': albums.map((a) => a.toJson()).toList(),
      // se ti serve salvarlo in locale, mappa artists anche qui
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final rawArtistLinks =
        json['artist_links'] ?? json['song_artist_links'] ?? json['artists'];

    final List<SongArtistModel> artists =
        (rawArtistLinks as List<dynamic>? ?? [])
            .map(
              (e) => SongArtistModel.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
    return SongModel(
      id: json['id']?.toString() ?? '',
      songName: json['song_name']?.toString() ?? '',
      songUrl: json['song_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url'] == null
          ? null
          : json['thumbnail_url'].toString(),
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'].toString())
          : DateTime.fromMillisecondsSinceEpoch(0),
      composerName: json['composer_name']?.toString() ?? '',
      producerName: json['producer_name'] == null
          ? null
          : json['producer_name'].toString(),
      genre: json['genre'] == null ? null : json['genre'].toString(),
      lyrics: json['lyrics'] == null ? null : json['lyrics'].toString(),
      mood: json['mood'] == null ? null : json['mood'].toString(),
      durationSeconds: (() {
        final raw = json['duration_seconds'];
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
        return null;
      })(),
      // qui usi la chiave che hai deciso per il salvataggio locale
      artists: artists,
      albums: (json['albums'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
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
        'albums: $albums'
        ')';
  }
}
