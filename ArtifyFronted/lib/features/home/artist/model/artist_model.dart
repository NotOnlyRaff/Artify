// lib/features/home/artist/model/artist_model.dart

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

  // 🔹 ora usiamo SongArtistModel, non più FavSongModel
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
      displayName:
          map['display_name'] is String ? map['display_name'] as String : null,
      slug: map['slug'] is String ? map['slug'] as String : null,
      imageUrl: map['image_url'] == null ? null : map['image_url'].toString(),
      bio: map['bio'] is String ? map['bio'] as String : null,
      country: map['country'] is String ? map['country'] as String : null,
      songs: (map['songs'] as List<dynamic>? ?? [])
          .map(
            (e) => SongModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      albums: (map['albums'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumModel.fromMap(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['display_name'] as String?,
      slug: json['slug'] as String?,
      imageUrl: json['image_url'] == null
          ? null
          : json['image_url'].toString(), // 👈 idem qui
      bio: json['bio'] as String?,
      country: json['country'] as String?,
      songs: (json['songs'] as List<dynamic>? ?? [])
          .map(
            (e) => SongModel.fromMap(e as Map<String, dynamic>),
          )
          .toList(),
      albums: (json['albums'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumModel.fromMap(e as Map<String, dynamic>),
          )
          .toList(),
    );
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
      'songs': songs.map((s) => s.toJson()).toList(),
      'albums': albums.map((a) => a.toJson()).toList(),
    };
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
    return id.hashCode ^
        name.hashCode ^
        displayName.hashCode ^
        slug.hashCode ^
        imageUrl.hashCode ^
        bio.hashCode ^
        country.hashCode ^
        songs.hashCode ^
        albums.hashCode;
  }
}
