import 'dart:convert';
import 'package:flutter/foundation.dart';

enum UserRole {
  admin,
  artist,
  user;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String token;
  final UserRole role;
  final String? artistId;
  final String? image_url; // 🆕 Nuovo campo
  final List<String> favorites;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    required this.role,
    this.artistId,
    this.image_url,
    List<String>? favorites,
  }) : favorites = favorites ?? const [];

  bool get isArtist => role == UserRole.artist;
  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
  bool get hasArtistProfile => artistId?.isNotEmpty == true;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    UserRole? role,
    String? artistId,
    String? profilePicUrl, // 🆕 Aggiornato
    List<String>? favorites,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      role: role ?? this.role,
      artistId: artistId ?? this.artistId,
      image_url: image_url ?? this.image_url, // 🆕 Aggiornato
      favorites: favorites ?? this.favorites,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'role': role.name,
      'artist_id': artistId,
      'image_url': image_url, // 🆕 Snake_case per il backend
      'favorite_songs': favorites,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Gestione flessibile dei preferiti (oggetti completi o solo ID)
    final rawFavs = map['favorite_songs'];
    List<String> favoriteIds = [];

    if (rawFavs is List) {
      favoriteIds = rawFavs
          .map((item) {
            if (item is String) return item;
            if (item is Map) return (item['id'] ?? item['song_id'])?.toString();
            return null;
          })
          .whereType<String>()
          .toList();
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
      role: UserRole.fromString(map['role']?.toString() ?? 'user'),
      artistId: map['artist_id']?.toString(),
      image_url: map['image_url']?.toString(), // 🆕 Mappatura corretta
      favorites: favoriteIds,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: ${role.name}, artistId: $artistId, image_url: $image_url)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.email == email &&
        other.token == token &&
        other.role == role &&
        other.artistId == artistId &&
        other.image_url == image_url && // 🆕 Aggiunto al confronto
        listEquals(other.favorites, favorites);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      token,
      role,
      artistId,
      image_url, // 🆕 Aggiunto all'hash
      Object.hashAll(favorites),
    );
  }
}
