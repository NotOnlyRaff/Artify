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
  final List<String> favorites;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    required this.role,
    this.artistId,
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
    List<String>? favorites,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      role: role ?? this.role,
      artistId: artistId ?? this.artistId,
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
      'favorite_songs': favorites,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
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
      favorites: favoriteIds,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: ${role.name}, artistId: $artistId)';
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
      Object.hashAll(favorites),
    );
  }
}
