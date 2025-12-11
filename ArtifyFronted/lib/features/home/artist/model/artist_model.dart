// lib/features/home/models/artist_model.dart

class ArtistModel {
  final String id;
  final String name;
  final String? displayName;
  final String? slug;
  final String? imageUrl;
  final String? bio;
  final String? country;

  const ArtistModel({
    required this.id,
    required this.name,
    this.displayName,
    this.slug,
    this.imageUrl,
    this.bio,
    this.country,
  });

  ArtistModel copyWith({
    String? id,
    String? name,
    String? displayName,
    String? slug,
    String? imageUrl,
    String? bio,
    String? country,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      slug: slug ?? this.slug,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
    );
  }

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id: map['id'] as String,
      name: map['name'] as String,
      displayName: map['display_name'] as String?,
      slug: map['slug'] as String?,
      imageUrl: map['image_url'] as String?,
      bio: map['bio'] as String?,
      country: map['country'] as String?,
    );
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String?,
      slug: json['slug'] as String?,
      imageUrl: json['image_url'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
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
    };
  }

  @override
  String toString() {
    return 'ArtistModel(id: $id, name: $name, displayName: $displayName, slug: $slug, imageUrl: $imageUrl, bio: $bio, country: $country)';
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
        other.country == country;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        displayName.hashCode ^
        slug.hashCode ^
        imageUrl.hashCode ^
        bio.hashCode ^
        country.hashCode;
  }
}
