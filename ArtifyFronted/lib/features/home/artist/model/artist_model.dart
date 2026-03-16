import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/foundation.dart';

class ArtistModel {
  final String id;
  final String name;
  final String? displayName;
  final String? slug;
  final String? imageUrl;
  final String? bio;
  final String? country;
  final List<SongModel> songs;
  final List<AlbumModel> albums;

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
    List<SongModel>? songs,
    List<AlbumModel>? albums,
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
      songs: _parseSongs(map['songs']),
      albums: _parseAlbums(map['albums']),
    );
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'slug': slug,
      'image_url': imageUrl,
      'bio': bio,
      'country': country,
      'songs': songs.map((song) => song.toJson()).toList(),
      'albums': albums.map((album) => album.toJson()).toList(),
    };
  }

  static List<SongModel> _parseSongs(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => SongModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static List<AlbumModel> _parseAlbums(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => AlbumModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  String toString() {
    return 'ArtistModel('
        'id: $id, '
        'name: $name, '
        'displayName: $displayName, '
        'slug: $slug, '
        'imageUrl: $imageUrl, '
        'bio: $bio, '
        'country: $country, '
        'songs: $songs, '
        'albums: $albums'
        ')';
  }

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
  int get hashCode {
    return Object.hash(
      id,
      name,
      displayName,
      slug,
      imageUrl,
      bio,
      country,
      Object.hashAll(songs),
      Object.hashAll(albums),
    );
  }
}
