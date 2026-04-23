// lib/features/home/artist/model/artist_model.dart

import 'package:flutter/foundation.dart';

/// Rappresentazione leggera di una song nel contesto di un artista.
/// Estratta da ArtistSongLinkOut: { id, song_id, role, song: SongRef }
class ArtistSongRef {
  final String songId;
  final String? songName;
  final String? thumbnailUrl;
  final String role;

  const ArtistSongRef({
    required this.songId,
    this.songName,
    this.thumbnailUrl,
    this.role = 'primary',
  });

  factory ArtistSongRef.fromMap(Map<String, dynamic> map) {
    String songId = map['song_id']?.toString() ?? '';
    String? songName;
    String? thumbnailUrl;

    // Estrae da nested SongRef: { id, song_name, thumbnail_url }
    final rawSong = map['song'];
    if (rawSong is Map) {
      final s = Map<String, dynamic>.from(rawSong);
      songId = s['id']?.toString() ?? songId;
      songName = s['song_name']?.toString();
      thumbnailUrl = s['thumbnail_url']?.toString();
    }

    return ArtistSongRef(
      songId: songId,
      songName: songName,
      thumbnailUrl: thumbnailUrl,
      role: map['role']?.toString() ?? 'primary',
    );
  }
}

/// Rappresentazione leggera di un album nel contesto di un artista.
/// Estratta da ArtistAlbumLinkOut: { id, album_id, role, album: AlbumRef }
class ArtistAlbumRef {
  final String albumId;
  final String? title;
  final String? coverUrl;
  final String? role;

  const ArtistAlbumRef({
    required this.albumId,
    this.title,
    this.coverUrl,
    this.role,
  });

  factory ArtistAlbumRef.fromMap(Map<String, dynamic> map) {
    String albumId = map['album_id']?.toString() ?? '';
    String? title;
    String? coverUrl;

    // Estrae da nested AlbumRef: { id, title, cover_url }
    final rawAlbum = map['album'];
    if (rawAlbum is Map) {
      final a = Map<String, dynamic>.from(rawAlbum);
      albumId = a['id']?.toString() ?? albumId;
      title = a['title']?.toString();
      coverUrl = a['cover_url']?.toString();
    }

    return ArtistAlbumRef(
      albumId: albumId,
      title: title,
      coverUrl: coverUrl,
      role: map['role']?.toString(),
    );
  }
}

/// Modello artista — corrisponde ad ArtistOut del backend.
///
/// MODIFICHE rispetto alla versione precedente:
/// - songs: ora List<ArtistSongRef>, parsata da song_artist_links
///   (il backend non invia più una lista piatta di song, ma ArtistSongLinkOut)
/// - albums: ora List<ArtistAlbumRef>, parsata da album_artist_links
///   (il backend non invia più una lista piatta di album, ma ArtistAlbumLinkOut)
class ArtistModel {
  final String id;
  final String name;
  final String? displayName;
  final String? slug;
  final String? imageUrl;
  final String? bio;
  final String? country;

  /// Song refs estratti da song_artist_links.
  final List<ArtistSongRef> songs;

  /// Album refs estratti da album_artist_links.
  final List<ArtistAlbumRef> albums;

  const ArtistModel({
    required this.id,
    required this.name,
    this.displayName,
    this.slug,
    this.imageUrl,
    this.bio,
    this.country,
    this.songs = const [],
    this.albums = const [],
  });

  ArtistModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
    List<ArtistSongRef>? songs,
    List<ArtistAlbumRef>? albums,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      slug: slug ?? this.slug,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
    );
  }

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      displayName: map['display_name']?.toString(),
      slug: map['slug']?.toString(),
      imageUrl: map['image_url']?.toString(),
      bio: map['bio']?.toString(),
      country: map['country']?.toString(),
      songs: _parseSongRefs(map),
      albums: _parseAlbumRefs(map),
    );
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) =>
      ArtistModel.fromMap(json);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'slug': slug,
      'image_url': imageUrl,
      'bio': bio,
      'country': country,
      'song_artist_links': songs.map((s) => {
            'song_id': s.songId,
            'role': s.role,
            'song': {
              'id': s.songId,
              'song_name': s.songName,
              'thumbnail_url': s.thumbnailUrl,
            },
          }).toList(),
      'album_artist_links': albums.map((a) => {
            'album_id': a.albumId,
            'role': a.role,
            'album': {
              'id': a.albumId,
              'title': a.title,
              'cover_url': a.coverUrl,
            },
          }).toList(),
    };
  }

  /// FIX: legge song_artist_links invece di 'songs'.
  static List<ArtistSongRef> _parseSongRefs(Map<String, dynamic> map) {
    final raw = map['song_artist_links'] ?? map['songs'] ?? const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ArtistSongRef.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  /// FIX: legge album_artist_links invece di 'albums'.
  static List<ArtistAlbumRef> _parseAlbumRefs(Map<String, dynamic> map) {
    final raw = map['album_artist_links'] ?? map['albums'] ?? const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ArtistAlbumRef.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  @override
  String toString() =>
      'ArtistModel(id: $id, name: $name, songs: ${songs.length}, albums: ${albums.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtistModel &&
        other.id == id &&
        other.name == name &&
        other.displayName == displayName &&
        other.slug == slug &&
        other.imageUrl == imageUrl &&
        other.bio == bio &&
        other.country == country &&
        listEquals(other.songs, songs) &&
        listEquals(other.albums, albums);
  }

  @override
  int get hashCode => Object.hash(
        id, name, displayName, slug, imageUrl, bio, country,
        Object.hashAll(songs), Object.hashAll(albums),
      );
}