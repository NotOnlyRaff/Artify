// lib/features/home/song/model/fav_song_model.dart

import 'dart:convert';

/// Rappresentazione leggera della song nei preferiti (SongRef dal backend).
class FavSongRef {
  final String id;
  final String? songName;
  final String? thumbnailUrl;

  const FavSongRef({
    required this.id,
    this.songName,
    this.thumbnailUrl,
  });

  factory FavSongRef.fromMap(Map<String, dynamic> map) {
    return FavSongRef(
      id: map['id']?.toString() ?? '',
      songName: map['song_name']?.toString(),
      thumbnailUrl: map['thumbnail_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'song_name': songName,
        'thumbnail_url': thumbnailUrl,
      };
}

/// Modello per una riga della tabella favorites.
/// Corrisponde a FavoriteOut del backend.
///
/// MODIFICHE rispetto alla versione precedente:
/// - Rinominati campi da snake_case a camelCase (convenzione Dart).
/// - Aggiunto [createdAt] — presente in FavoriteOut dal backend.
/// - Aggiunto [song] opzionale — SongRef annidato quando disponibile.
class FavSongModel {
  final String id;
  final String songId;
  final String userId;

  /// Timestamp di quando la song è stata aggiunta ai preferiti.
  final DateTime? createdAt;

  /// Dati della song — presenti se il backend popola il campo song.
  final FavSongRef? song;

  const FavSongModel({
    required this.id,
    required this.songId,
    required this.userId,
    this.createdAt,
    this.song,
  });

  FavSongModel copyWith({
    String? id,
    String? songId,
    String? userId,
    DateTime? createdAt,
    FavSongRef? song,
  }) {
    return FavSongModel(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      song: song ?? this.song,
    );
  }

  factory FavSongModel.fromMap(Map<String, dynamic> map) {
    FavSongRef? songRef;
    final rawSong = map['song'];
    if (rawSong is Map) {
      songRef = FavSongRef.fromMap(Map<String, dynamic>.from(rawSong));
    }

    DateTime? createdAt;
    final rawDate = map['created_at'];
    if (rawDate != null) {
      createdAt = DateTime.tryParse(rawDate.toString());
    }

    return FavSongModel(
      id: map['id']?.toString() ?? '',
      songId: map['song_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      createdAt: createdAt,
      song: songRef,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'song_id': songId,
      'user_id': userId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (song != null) 'song': song!.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  factory FavSongModel.fromJson(String source) =>
      FavSongModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'FavSongModel(id: $id, songId: $songId, userId: $userId, createdAt: $createdAt)';

  @override
  bool operator ==(covariant FavSongModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.songId == songId &&
        other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ songId.hashCode ^ userId.hashCode;
}