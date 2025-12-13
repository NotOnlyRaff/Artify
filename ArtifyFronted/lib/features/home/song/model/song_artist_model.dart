// lib/features/home/song/model/song_model.dart

import 'package:client/features/home/artist/model/artist_model.dart';

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
        // fallback sicuro
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

class SongArtistModel {
  final String id;
  final SongArtistRole role;
  final ArtistModel artist;

  const SongArtistModel({
    required this.id,
    required this.role,
    required this.artist,
  });

  factory SongArtistModel.fromMap(Map<String, dynamic> map) {
    final roleRaw = map['role'] as String? ?? 'primary';

    final artistRaw = map['artist'];

    ArtistModel artist;
    if (artistRaw is Map) {
      artist = ArtistModel.fromMap(
        Map<String, dynamic>.from(artistRaw),
      );
    } else {
      // 👇 fallback super safe, NESSUNA eccezione
      artist = ArtistModel(
        id: (map['artist_id']?.toString() ?? ''),
        name: 'Unknown artist',
        displayName: null,
        slug: null,
        imageUrl: null,
        bio: null,
        country: null,
        songs: const [],
        albums: const [],
      );
    }
    return SongArtistModel(
      id: map['id'] as String,
      role: SongArtistRoleX.fromString(roleRaw),
      artist: artist,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.value,
      'artist': artist.toJson(),
    };
  }
}
