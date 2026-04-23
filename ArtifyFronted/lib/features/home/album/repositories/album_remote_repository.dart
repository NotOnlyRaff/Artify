import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/network/http_client_provider.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_remote_repository.g.dart';

@riverpod
AlbumRemoteRepository albumRemoteRepository(AlbumRemoteRepositoryRef ref) {
  // FIX: client iniettato dal provider (come artist e song).
  final client = ref.watch(httpClientProvider);
  return AlbumRemoteRepository(client);
}

class AlbumRemoteRepository {
  final http.Client client;

  AlbumRemoteRepository(this.client);

  // FIX: tutti i path aggiornati da /album a /albums (convenzione REST plurale).
  Uri _uri(String path) => Uri.parse('${ServerConstant.serverURL}$path');

  Map<String, String> _jsonHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-auth-token': token,
      };

  Map<String, String> _authHeaders(String token) => {
        'Accept': 'application/json',
        'x-auth-token': token,
      };

  Map<String, dynamic>? _tryParseObject(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(Map<String, dynamic>? body,
      {String fallback = 'Server error'}) {
    if (body == null) return fallback;
    final detail = body['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
    }
    return fallback;
  }

  // ──────────────── UPLOAD ALBUM COVER ────────────────

  Future<Either<AppFailure, String>> uploadAlbumCover({
    required PickedMedia cover,
    required String token,
  }) async {
    try {
      // FIX: /albums/upload-cover
      final request =
          http.MultipartRequest('POST', _uri('/albums/upload-cover'));
      request.headers.addAll(_authHeaders(token));

      if (kIsWeb) {
        if (cover.bytes == null)
          return Left(AppFailure('Image bytes are null on Web'));
        request.files.add(http.MultipartFile.fromBytes('cover', cover.bytes!,
            filename: cover.name));
      } else {
        if (cover.filePath == null)
          return Left(AppFailure('Image path is null on mobile'));
        request.files
            .add(await http.MultipartFile.fromPath('cover', cover.filePath!));
      }

      final response = await http.Response.fromStream(await request.send());
      final body = _tryParseObject(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left(AppFailure(_extractError(body,
            fallback: 'Upload cover failed (${response.statusCode})')));
      }

      final coverUrl = body?['cover_url']?.toString();
      if (coverUrl == null || coverUrl.isEmpty)
        return Left(AppFailure('Cover URL missing in response'));

      return Right(coverUrl);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ──────────────── CREAZIONE ALBUM ────────────────

  Future<Either<AppFailure, AlbumModel>> createAlbum({
    required String title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    // artistIds e songIds: gli artisti e le song esistenti da collegare.
    List<String> artistIds = const [],
    // FIX: songIds con song già esistenti nel catalogo.
    // Il frontend invia la lista di AlbumSongAttachIn: { song_id, track_number }.
    // Per ora mappiamo con track_number = posizione nella lista (1-indexed).
    List<String> songIds = const [],
    required String token,
  }) async {
    try {
      // FIX: rimosso il campo new_songs — lo schema AlbumCreate aggiornato
      // non accetta song inline (song_url, artist_ids, artist_roles non esistono
      // più nello schema). Le song si uploadano separatamente e si collegano tramite
      // song_ids (lista di AlbumSongAttachIn).
      final songLinks = songIds
          .asMap()
          .entries
          .map((e) => {
                'song_id': e.value,
                'track_number': e.key + 1,
              })
          .toList();

      final body = <String, dynamic>{
        'title': title,
        if (releaseDate != null)
          'release_date': releaseDate.toIso8601String().split('T').first,
        if (label != null) 'label': label,
        if (albumType != null) 'album_type': albumType,
        if (genre != null) 'genre': genre,
        if (coverUrl != null) 'cover_url': coverUrl,
        'artist_ids': artistIds,
        'song_links': songLinks,
      };

      // FIX: rimossi print() e header Authorization duplicato.
      // FIX: /albums
      final response = await client.post(
        _uri('/albums'),
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      final bodyMap = _tryParseObject(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Album create failed (${response.statusCode})')));
      }
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(AlbumModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── GET SINGOLO ALBUM ─────────────

  Future<Either<AppFailure, AlbumModel>> getAlbum({
    required String albumId,
    required String token,
  }) async {
    try {
      // FIX: /albums/{id}
      final res = await client.get(_uri('/albums/$albumId'),
          headers: _authHeaders(token));
      final bodyMap = _tryParseObject(res.body);

      if (res.statusCode != 200) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Get album failed (${res.statusCode})')));
      }
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(AlbumModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── LISTA ALBUM ──────────────────

  Future<Either<AppFailure, List<AlbumModel>>> listAlbums({
    required String token,
    String? artistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // FIX: /albums con paginazione.
      final queryParams = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (artistId != null && artistId.isNotEmpty) 'artist_id': artistId,
      };
      final uri = _uri('/albums').replace(queryParameters: queryParams);

      final res = await client.get(uri, headers: _authHeaders(token));

      if (res.statusCode != 200) {
        final bodyMap = _tryParseObject(res.body);
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'List albums failed (${res.statusCode})')));
      }

      // FIX: backend restituisce {"items": [...], "total": ...} non lista piatta.
      final bodyMap = _tryParseObject(res.body);
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      final rawItems = bodyMap['items'];
      if (rawItems is! List)
        return Left(AppFailure('Missing items in response'));

      final albums = rawItems
          .whereType<Map>()
          .map((item) => AlbumModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      return Right(albums);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── UPDATE ALBUM ─────────────────

  Future<Either<AppFailure, AlbumModel>> updateAlbum({
    required String albumId,
    String? title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    List<String>? artistIds,
    List<String>? songIds,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title.trim();
      if (releaseDate != null)
        body['release_date'] = releaseDate.toIso8601String().split('T').first;
      if (label != null) body['label'] = label.trim();
      if (albumType != null) body['album_type'] = albumType.trim();
      if (genre != null) body['genre'] = genre.trim();
      if (coverUrl != null) body['cover_url'] = coverUrl.trim();
      if (artistIds != null) body['artist_ids'] = artistIds;
      if (songIds != null) {
        body['song_links'] = songIds
            .asMap()
            .entries
            .map((e) => {
                  'song_id': e.value,
                  'track_number': e.key + 1,
                })
            .toList();
      }

      if (body.isEmpty)
        return Left(AppFailure('No fields provided for album update'));

      // FIX: /albums/{id}
      final res = await client.patch(
        _uri('/albums/$albumId'),
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );
      final bodyMap = _tryParseObject(res.body);

      if (res.statusCode != 200) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Update album failed (${res.statusCode})')));
      }
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(AlbumModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── DELETE ALBUM ─────────────────

  Future<Either<AppFailure, bool>> deleteAlbum({
    required String albumId,
    required String token,
  }) async {
    try {
      // FIX: /albums/{id}
      final res = await client.delete(_uri('/albums/$albumId'),
          headers: _authHeaders(token));

      if (res.statusCode != 200 && res.statusCode != 204) {
        final bodyMap = _tryParseObject(res.body);
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Delete album failed (${res.statusCode})')));
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
