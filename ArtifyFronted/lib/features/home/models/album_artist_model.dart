// lib/features/home/album/model/album_artist_model.dart

import 'package:client/features/home/artist/model/artist_model.dart';

class AlbumArtistModel {
  final String id; // id della join album_artists
  final String albumId; // album_id
  final String artistId; // artist_id
  final String? role; // 'primary', 'guest', ecc. (opzionale)
  final ArtistModel artist;

  const AlbumArtistModel({
    required this.id,
    required this.albumId,
    required this.artistId,
    required this.artist,
    this.role,
  });

  AlbumArtistModel copyWith({
    String? id,
    String? albumId,
    String? artistId,
    String? role,
    ArtistModel? artist,
  }) {
    return AlbumArtistModel(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      role: role ?? this.role,
      artist: artist ?? this.artist,
    );
  }

  factory AlbumArtistModel.fromMap(Map<String, dynamic> map) {
    final rawArtist = map['artist'];

    // fallback super safe se il backend non manda l'oggetto completo
    ArtistModel parsedArtist;
    if (rawArtist is Map) {
      parsedArtist = ArtistModel.fromMap(
        Map<String, dynamic>.from(rawArtist),
      );
    } else {
      parsedArtist = ArtistModel(
        id: (map['artist_id']?.toString() ?? ''),
        name: 'Unknown artist',
        displayName: null,
        slug: null,
        imageUrl: null,
        bio: null,
        country: null,
        // se hai i campi songs/albums metti pure [] come default
        songs: const [],
        albums: const [],
      );
    }

    return AlbumArtistModel(
      id: map['id']?.toString() ?? '',
      albumId: map['album_id']?.toString() ?? '',
      artistId: map['artist_id']?.toString() ?? '',
      role: map['role'] is String ? map['role'] as String : null,
      artist: parsedArtist,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'album_id': albumId,
      'artist_id': artistId,
      'role': role,
      'artist': artist.toJson(), // o toMap() a seconda del tuo ArtistModel
    };
  }

  String toJson() => toMap().toString();
}
