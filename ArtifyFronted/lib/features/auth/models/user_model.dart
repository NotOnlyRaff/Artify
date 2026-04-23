import 'dart:convert';
import 'package:flutter/foundation.dart';

enum UserRole {
  admin,
  artist,
  user;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.user;

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

  /// Token locale lato frontend/auth.
  /// Non è un campo del model backend User, quindi lo teniamo opzionale.
  final String? token;

  final UserRole role;
  final String? artistId;
  final String? imageUrl;

  /// Compatibilità col vecchio frontend.
  /// Il backend user non espone più favorite_songs come parte del model utente,
  /// ma se qualche endpoint vecchio lo restituisce ancora, lo supportiamo.
  final List<String> favoriteSongIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.token,
    required this.role,
    this.artistId,
    this.imageUrl,
    List<String>? favoriteSongIds,
  }) : favoriteSongIds = favoriteSongIds ?? const [];

  bool get isArtist => role == UserRole.artist;
  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
  bool get hasArtistProfile => artistId?.isNotEmpty == true;

  /// Getter di compatibilità col vecchio codice frontend che usa `favorites`
  List<String> get favorites => favoriteSongIds;

  /// Getter di compatibilità col vecchio naming `image_url`
  String? get image_url => imageUrl;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    UserRole? role,
    String? artistId,
    String? imageUrl,
    List<String>? favoriteSongIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      role: role ?? this.role,
      artistId: artistId ?? this.artistId,
      imageUrl: imageUrl ?? this.imageUrl,
      favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
    );
  }

  /// Mappa pensata per serializzazione locale / caching / persistenza app.
  /// Tiene anche il token.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'role': role.name,
      'artist_id': artistId,
      'image_url': imageUrl,
      'favorite_songs': favoriteSongIds,
    };
  }

  /// Mappa pensata per payload user "pulito" verso/da backend.
  /// Non include token, perché il token non fa parte del model User backend.
  Map<String, dynamic> toApiMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'artist_id': artistId,
      'image_url': imageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Supporta sia:
    // 1) payload utente diretto
    // 2) payload auth del tipo { "token": "...", "user": { ... } }
    final rawUser = map['user'];
    final userMap = rawUser is Map<String, dynamic>
        ? rawUser
        : Map<String, dynamic>.from(map);

    final String? token = map['token']?.toString() ?? userMap['token']?.toString();

    final rawFavs = userMap['favorite_songs'];
    List<String> favoriteIds = [];

    if (rawFavs is List) {
      favoriteIds = rawFavs
          .map((item) {
            if (item is String) return item;
            if (item is Map) {
              return (item['id'] ?? item['song_id'])?.toString();
            }
            return null;
          })
          .whereType<String>()
          .toList();
    }

    return UserModel(
      id: userMap['id']?.toString() ?? '',
      name: userMap['name']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      token: token,
      role: UserRole.fromString(userMap['role']?.toString()),
      artistId: userMap['artist_id']?.toString(),
      imageUrl: userMap['image_url']?.toString(),
      favoriteSongIds: favoriteIds,
    );
  }

  factory UserModel.fromAuthResponse(Map<String, dynamic> map) {
    return UserModel.fromMap(map);
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, token: $token, role: ${role.name}, artistId: $artistId, imageUrl: $imageUrl, favoriteSongIds: $favoriteSongIds)';
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
        other.imageUrl == imageUrl &&
        listEquals(other.favoriteSongIds, favoriteSongIds);
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
      imageUrl,
      Object.hashAll(favoriteSongIds),
    );
  }
}