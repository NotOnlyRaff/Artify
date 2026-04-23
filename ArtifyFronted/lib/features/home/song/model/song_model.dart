import 'package:client/features/home/album/model/album_model.dart';
import '../../models/song_artist_model.dart';

class SongModel {
  final String id;
  final String songName;
  final String songUrl;
  final String? thumbnailUrl;
  final DateTime? releaseDate;

  final String? composerId;
  final String? composerName;

  final String? producerId;
  final String? producerName;

  final String? genre;
  final String? lyrics;
  final String? mood;
  final int? durationSeconds;

  // Mantengo questi nomi per compatibilità con il frontend esistente
  final List<SongArtistModel> artists;
  final List<AlbumModel> albums;

  const SongModel({
    required this.id,
    required this.songName,
    required this.songUrl,
    this.thumbnailUrl,
    this.releaseDate,
    this.composerId,
    this.composerName,
    this.producerId,
    this.producerName,
    this.genre,
    this.lyrics,
    this.mood,
    this.durationSeconds,
    this.artists = const [],
    this.albums = const [],
  });

  bool get hasComposerArtist => composerId?.isNotEmpty == true;
  bool get hasProducerArtist => producerId?.isNotEmpty == true;

  SongModel copyWith({
    String? id,
    String? songName,
    String? songUrl,
    String? thumbnailUrl,
    DateTime? releaseDate,
    String? composerId,
    String? composerName,
    String? producerId,
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
      composerId: composerId ?? this.composerId,
      composerName: composerName ?? this.composerName,
      producerId: producerId ?? this.producerId,
      producerName: producerName ?? this.producerName,
      genre: genre ?? this.genre,
      lyrics: lyrics ?? this.lyrics,
      mood: mood ?? this.mood,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static int? _parseInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static List<SongArtistModel> _parseArtists(Map<String, dynamic> map) {
    final rawArtistLinks =
        map['artist_links'] ?? map['song_artist_links'] ?? map['artists'];

    if (rawArtistLinks is! List) return const [];

    return rawArtistLinks
        .map(
          (e) => SongArtistModel.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  static List<AlbumModel> _parseAlbums(Map<String, dynamic> map) {
    final rawAlbums =
        map['album_links'] ?? map['album_song_links'] ?? map['albums'];

    if (rawAlbums is! List) return const [];

    return rawAlbums.map((e) {
      final item = Map<String, dynamic>.from(e as Map);

      // Nuovo formato: { album_id, track_number, album: {...} }
      if (item['album'] is Map) {
        return AlbumModel.fromMap(
          Map<String, dynamic>.from(item['album'] as Map),
        );
      }

      // Vecchio formato diretto: {...album fields...}
      return AlbumModel.fromMap(item);
    }).toList();
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id']?.toString() ?? '',
      songName: map['song_name']?.toString() ?? '',
      songUrl: map['song_url']?.toString() ?? '',
      thumbnailUrl: map['thumbnail_url']?.toString(),
      releaseDate: _parseDate(map['release_date']),
      composerId: map['composer_id']?.toString(),
      composerName: map['composer_name']?.toString(),
      producerId: map['producer_id']?.toString(),
      producerName: map['producer_name']?.toString(),
      genre: map['genre']?.toString(),
      lyrics: map['lyrics']?.toString(),
      mood: map['mood']?.toString(),
      durationSeconds: _parseInt(map['duration_seconds']),
      artists: _parseArtists(map),
      albums: _parseAlbums(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'song_name': songName,
      'song_url': songUrl,
      'thumbnail_url': thumbnailUrl,
      'release_date': releaseDate?.toIso8601String(),
      'composer_id': composerId,
      'composer_name': composerName,
      'producer_id': producerId,
      'producer_name': producerName,
      'genre': genre,
      'lyrics': lyrics,
      'mood': mood,
      'duration_seconds': durationSeconds,
      'artist_links': artists.map((a) => a.toMap()).toList(),

      // Qui mantengo "albums" per compatibilità locale/frontend.
      // fromMap supporta sia "albums" che "album_links"/"album_song_links".
      'albums': albums.map((a) => a.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel.fromMap(json);
  }

  @override
  String toString() {
    return 'SongModel('
        'id: $id, '
        'songName: $songName, '
        'songUrl: $songUrl, '
        'thumbnailUrl: $thumbnailUrl, '
        'releaseDate: $releaseDate, '
        'composerId: $composerId, '
        'composerName: $composerName, '
        'producerId: $producerId, '
        'producerName: $producerName, '
        'genre: $genre, '
        'lyrics: $lyrics, '
        'mood: $mood, '
        'durationSeconds: $durationSeconds, '
        'artists: $artists, '
        'albums: $albums'
        ')';
  }
}
