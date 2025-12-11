// lib/features/home/models/album_model.dart

class AlbumModel {
  final String id;
  final String title;
  final String? coverUrl;
  final DateTime? releaseDate;
  final String? label;
  final int? totalTracks;
  final String? albumType; // 'album', 'single', 'ep', ecc.

  const AlbumModel({
    required this.id,
    required this.title,
    this.coverUrl,
    this.releaseDate,
    this.label,
    this.totalTracks,
    this.albumType,
  });

  AlbumModel copyWith({
    String? id,
    String? title,
    String? coverUrl,
    DateTime? releaseDate,
    String? label,
    int? totalTracks,
    String? albumType,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      label: label ?? this.label,
      totalTracks: totalTracks ?? this.totalTracks,
      albumType: albumType ?? this.albumType,
    );
  }

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['id'] as String,
      title: map['title'] as String,
      coverUrl: map['cover_url'] as String?,
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'] as String)
          : null,
      label: map['label'] as String?,
      totalTracks: map['total_tracks'] as int?,
      albumType: map['album_type'] as String?,
    );
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
      label: json['label'] as String?,
      totalTracks: json['total_tracks'] as int?,
      albumType: json['album_type'] as String?,
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
    };
  }

  @override
  String toString() {
    return 'AlbumModel(id: $id, title: $title, coverUrl: $coverUrl, releaseDate: $releaseDate, label: $label, totalTracks: $totalTracks, albumType: $albumType)';
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
