class ArtistAlbumModel {
  final String id;
  final String title;
  final String? coverUrl;

  const ArtistAlbumModel({
    required this.id,
    required this.title,
    this.coverUrl,
  });

  factory ArtistAlbumModel.fromMap(Map<String, dynamic> map) {
    return ArtistAlbumModel(
      id: map['id'] as String,
      title: map['title'] as String,
      coverUrl: map['cover_url'] as String?,
    );
  }

  factory ArtistAlbumModel.fromJson(Map<String, dynamic> json) {
    return ArtistAlbumModel(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
    };
  }

  @override
  String toString() =>
      'ArtistAlbumModel(id: $id, title: $title, coverUrl: $coverUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ArtistAlbumModel &&
        other.id == id &&
        other.title == title &&
        other.coverUrl == coverUrl;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ coverUrl.hashCode;
}