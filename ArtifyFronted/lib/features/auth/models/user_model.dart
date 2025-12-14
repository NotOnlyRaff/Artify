// lib/features/auth/models/user_model.dart (o percorso reale)

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class UserModel {
  final String name;
  final String email;
  final String id;
  final String token;

  /// lista di ID delle canzoni preferite (song.id)
  final List<String> favorites;

  UserModel({
    required this.name,
    required this.email,
    required this.id,
    required this.token,
    List<String>? favorites,
  }) : favorites = favorites ?? const [];

  UserModel copyWith({
    String? name,
    String? email,
    String? id,
    String? token,
    List<String>? favorites,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      id: id ?? this.id,
      token: token ?? this.token,
      favorites: favorites ?? this.favorites,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'id': id,
      'token': token,
      // li rimandiamo come lista di id (se mai servirà)
      'favorite_songs': favorites,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // backend: favorite_songs: List[SongRef]
    // SongRef: { id, song_name, thumbnail_url }
    final rawFavs = map['favorite_songs'];

    List<String> favoriteIds = [];
    if (rawFavs is List) {
      favoriteIds = rawFavs
          .map((item) {
            if (item == null) return null;

            if (item is String) {
              // nel caso in futuro decidessi di mandare solo ID
              return item;
            }

            if (item is Map<String, dynamic>) {
              final id = item['id'] ?? item['song_id'];
              if (id == null) return null;
              return id.toString();
            }

            if (item is Map) {
              final id = (item['id'] ?? item['song_id'])?.toString();
              return id;
            }

            return null;
          })
          .whereType<String>() // filtra solo gli id non null
          .toList();
    }

    return UserModel(
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      id: map['id']?.toString() ?? '',
      // signup e /auth/current non mandano token → lo metti dopo con copyWith
      token: map['token']?.toString() ?? '',
      favorites: favoriteIds,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(name: $name, email: $email, id: $id, token: $token, favorites: $favorites)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.email == email &&
        other.id == id &&
        other.token == token &&
        listEquals(other.favorites, favorites);
  }

  @override
  int get hashCode {
    return name.hashCode ^
        email.hashCode ^
        id.hashCode ^
        token.hashCode ^
        favorites.hashCode;
  }
}
