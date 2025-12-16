// lib/features/home/models/album_model.dart

import 'package:client/features/home/models/album_artist_model.dart';

class AlbumModel {
  final String id;
  final String title;
  final String? coverUrl;
  final DateTime? releaseDate;
  final String? label;
  final int? totalTracks;
  final String? albumType; // 'album', 'single', 'ep', ecc.
  final String? genre;

  final List<AlbumArtistModel> artists;

  const AlbumModel({
    required this.id,
    required this.title,
    this.coverUrl,
    this.releaseDate,
    this.label,
    this.totalTracks,
    this.albumType,
    this.genre,
    this.artists = const [],
  });

  AlbumModel copyWith({
    String? id,
    String? title,
    String? coverUrl,
    DateTime? releaseDate,
    String? label,
    int? totalTracks,
    String? albumType,
    String? genre,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      label: label ?? this.label,
      totalTracks: totalTracks ?? this.totalTracks,
      albumType: albumType ?? this.albumType,
      genre: genre ?? this.genre,
      artists: artists,
    );
  }

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      coverUrl: map['cover_url'] == null ? null : map['cover_url'].toString(),
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'].toString())
          : null,
      label: map['label'] == null ? null : map['label'].toString(),
      totalTracks: (() {
        final raw = map['total_tracks'];
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
        return null;
      })(),
      albumType:
          map['album_type'] == null ? null : map['album_type'].toString(),
      genre: 
          map['genre'] == null ? null : map['genre'].toString(),
      artists: (map['artists'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumArtistModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverUrl: json['cover_url'] == null ? null : json['cover_url'].toString(),
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'].toString())
          : null,
      label: json['label'] == null ? null : json['label'].toString(),
      totalTracks: (() {
        final raw = json['total_tracks'];
        if (raw is int) return raw;
        if (raw is String) return int.tryParse(raw);
        return null;
      })(),
      albumType:
          json['album_type'] == null ? null : json['album_type'].toString(),
      genre:
          json['genre'] == null ? null : json['genre'].toString(),
      artists: (json['artists'] as List<dynamic>? ?? [])
          .map(
            (e) => AlbumArtistModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'release_date': releaseDate?.toIso8601String(),
      'label': label,
      'total_tracks': totalTracks,
      'album_type': albumType,
      'genre': genre,
      'artists': artists.map((a) => a.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'AlbumModel(id: $id, title: $title, coverUrl: $coverUrl, releaseDate: $releaseDate, label: $label, totalTracks: $totalTracks, albumType: $albumType, genre: $genre, artists: $artists)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AlbumModel &&
        other.id == id &&
        other.title == title &&
        other.coverUrl == coverUrl &&
        other.releaseDate == releaseDate &&
        other.label == label &&
        other.totalTracks == totalTracks &&
        other.albumType == albumType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        coverUrl.hashCode ^
        releaseDate.hashCode ^
        label.hashCode ^
        totalTracks.hashCode ^
        albumType.hashCode;
  }
}
