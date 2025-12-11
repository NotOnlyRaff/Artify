// lib/features/home/models/song_artist_model.dart

import '../../artist/model/artist_model.dart';

enum SongArtistRole {
  primary,
  featured,
  producer,
  mixer,
  writer,
}

SongArtistRole songArtistRoleFromString(String value) {
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

String songArtistRoleToString(SongArtistRole role) {
  switch (role) {
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

/// Link Song ⟷ Artist con ruolo (mappa 1:1 con SongArtist del backend)
class SongArtistLinkModel {
  final String id;
  final SongArtistRole role;
  final ArtistModel artist;

  const SongArtistLinkModel({
    required this.id,
    required this.role,
    required this.artist,
  });

  SongArtistLinkModel copyWith({
    String? id,
    SongArtistRole? role,
    ArtistModel? artist,
  }) {
    return SongArtistLinkModel(
      id: id ?? this.id,
      role: role ?? this.role,
      artist: artist ?? this.artist,
    );
  }

  factory SongArtistLinkModel.fromMap(Map<String, dynamic> map) {
    return SongArtistLinkModel(
      id: map['id'] as String,
      role: songArtistRoleFromString(map['role'] as String),
      artist: ArtistModel.fromMap(map['artist'] as Map<String, dynamic>),
    );
  }

  factory SongArtistLinkModel.fromJson(Map<String, dynamic> json) {
    return SongArtistLinkModel(
      id: json['id'] as String,
      role: songArtistRoleFromString(json['role'] as String),
      artist: ArtistModel.fromJson(json['artist'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': songArtistRoleToString(role),
      'artist': artist.toJson(),
    };
  }

  @override
  String toString() {
    return 'SongArtistLinkModel(id: $id, role: $role, artist: $artist)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SongArtistLinkModel &&
        other.id == id &&
        other.role == role &&
        other.artist == artist;
  }

  @override
  int get hashCode => id.hashCode ^ role.hashCode ^ artist.hashCode;
}
