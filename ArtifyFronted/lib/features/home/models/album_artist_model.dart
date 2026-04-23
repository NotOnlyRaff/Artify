// lib/features/home/album/model/album_artist_model.dart

/// Ruoli possibili di un artista su un album.
/// Allineato a AlbumArtistRole nel backend (enums.py).
enum AlbumArtistRole {
  primary,
  featured,
  guest;

  static AlbumArtistRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'featured':
        return AlbumArtistRole.featured;
      case 'guest':
        return AlbumArtistRole.guest;
      case 'primary':
      default:
        return AlbumArtistRole.primary;
    }
  }

  String get value => name; // 'primary', 'featured', 'guest'
}

/// Modello per una riga di album_artists.
/// Corrisponde ad AlbumArtistLinkOut del backend.
///
/// Nota: [id] e [albumId] non sono presenti in AlbumArtistLinkOut
/// (il backend non li espone quando annidati in AlbumOut).
/// Vengono popolati solo se l'API li restituisce (es. endpoint dedicato).
class AlbumArtistModel {
  /// Id della riga album_artists — presente solo in endpoint dedicati.
  final String? id;

  /// album_id — non presente in AlbumArtistLinkOut (implicito dal contesto).
  final String? albumId;

  /// artist_id — sempre presente.
  final String artistId;

  /// Ruolo dell'artista sull'album.
  final AlbumArtistRole role;

  /// Dati artista annidati (ArtistRef: id, name, display_name, image_url).
  final String artistName;
  final String? artistDisplayName;
  final String? artistImageUrl;

  const AlbumArtistModel({
    this.id,
    this.albumId,
    required this.artistId,
    this.role = AlbumArtistRole.primary,
    required this.artistName,
    this.artistDisplayName,
    this.artistImageUrl,
  });

  AlbumArtistModel copyWith({
    String? id,
    String? albumId,
    String? artistId,
    AlbumArtistRole? role,
    String? artistName,
    String? artistDisplayName,
    String? artistImageUrl,
  }) {
    return AlbumArtistModel(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      role: role ?? this.role,
      artistName: artistName ?? this.artistName,
      artistDisplayName: artistDisplayName ?? this.artistDisplayName,
      artistImageUrl: artistImageUrl ?? this.artistImageUrl,
    );
  }

  /// Parsa da AlbumArtistLinkOut:
  /// { "artist_id": "...", "role": "primary", "artist": { "id": "...", "name": "...", ... } }
  factory AlbumArtistModel.fromMap(Map<String, dynamic> map) {
    // Dati artista dal nested ArtistRef
    final rawArtist = map['artist'];
    String artistId = map['artist_id']?.toString() ?? '';
    String artistName = 'Unknown artist';
    String? artistDisplayName;
    String? artistImageUrl;

    if (rawArtist is Map) {
      final a = Map<String, dynamic>.from(rawArtist);
      artistId = a['id']?.toString() ?? artistId;
      artistName = a['name']?.toString() ?? artistName;
      artistDisplayName = a['display_name']?.toString();
      artistImageUrl = a['image_url']?.toString();
    }

    return AlbumArtistModel(
      id: map['id']?.toString(),
      albumId: map['album_id']?.toString(),
      artistId: artistId,
      role: AlbumArtistRole.fromString(map['role']?.toString()),
      artistName: artistName,
      artistDisplayName: artistDisplayName,
      artistImageUrl: artistImageUrl,
    );
  }

  factory AlbumArtistModel.fromJson(Map<String, dynamic> json) =>
      AlbumArtistModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (albumId != null) 'album_id': albumId,
      'artist_id': artistId,
      'role': role.value,
      'artist': {
        'id': artistId,
        'name': artistName,
        'display_name': artistDisplayName,
        'image_url': artistImageUrl,
      },
    };
  }

  @override
  String toString() =>
      'AlbumArtistModel(artistId: $artistId, role: ${role.value}, name: $artistName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumArtistModel &&
          other.artistId == artistId &&
          other.role == role;

  @override
  int get hashCode => artistId.hashCode ^ role.hashCode;
}