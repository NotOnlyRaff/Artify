import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'album_remote_repository.g.dart';

@riverpod
AlbumRemoteRepository albumRemoteRepository(AlbumRemoteRepositoryRef ref) {
  return AlbumRemoteRepository();
}

class AlbumRemoteRepository {
  Uri _uri(String path) => Uri.parse('${ServerConstant.serverURL}$path');

  Map<String, String> _jsonHeaders(String token) => {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      };

  // ───────────────── CREATE ALBUM ─────────────────
  //
  // POST /album
  // body = AlbumCreate:
  // {
  //   "title": "...",
  //   "release_date": "YYYY-MM-DD" | null,
  //   "label": "...",
  //   "album_type": "album|single|ep|...",
  //   "cover_url": "...",
  //   "artist_ids": ["..."],
  //   "song_ids": ["..."]
  // }

  Future<Either<AppFailure, AlbumModel>> createAlbum({
    required String title,
    DateTime? releaseDate,
    String? label,
    String? albumType,
    String? genre,
    String? coverUrl,
    List<String> artistIds = const [],
    List<String> songIds = const [],
    required String token,
  }) async {
    try {
      final uri = _uri('/album');

      final body = <String, dynamic>{
        'title': title.trim(),
        'artist_ids': artistIds,
        'song_ids': songIds,
      };

      if (releaseDate != null) {
        body['release_date'] =
            releaseDate.toIso8601String().split('T').first; // yyyy-MM-dd
      }
      if (label != null && label.trim().isNotEmpty) {
        body['label'] = label.trim();
      }
      if (albumType != null && albumType.trim().isNotEmpty) {
        body['album_type'] = albumType.trim();
      }
      if (genre != null && genre.trim().isNotEmpty) {
        body['genre'] = genre.trim();
      }
      if (coverUrl != null && coverUrl.trim().isNotEmpty) {
        body['cover_url'] = coverUrl.trim();
      }

      final res = await http.post(
        uri,
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 201) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
                resBodyMap['detail']?.toString() ?? 'Create album failed'),
          );
        }
        return Left(AppFailure('Create album failed (${res.statusCode})'));
      }

      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for AlbumCreate'));
      }

      final album = AlbumModel.fromMap(
        Map<String, dynamic>.from(resBodyMap),
      );
      return Right(album);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── GET SINGLE ALBUM ─────────────
  //
  // GET /album/{album_id}
  // response_model = AlbumOut

  Future<Either<AppFailure, AlbumModel>> getAlbum({
    required String albumId,
    required String token,
  }) async {
    try {
      final uri = _uri('/album/$albumId');

      final res = await http.get(
        uri,
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(resBodyMap['detail']?.toString() ?? 'Get album failed'),
          );
        }
        return Left(AppFailure('Get album failed (${res.statusCode})'));
      }

      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for AlbumOut'));
      }

      final album = AlbumModel.fromMap(
        Map<String, dynamic>.from(resBodyMap),
      );
      return Right(album);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── LIST ALBUMS ──────────────────
  //
  // GET /album
  // GET /album?artist_id=...

  Future<Either<AppFailure, List<AlbumModel>>> listAlbums({
    required String token,
    String? artistId,
  }) async {
    try {
      Uri uri;
      if (artistId != null && artistId.isNotEmpty) {
        // /album?artist_id=...
        uri = _uri('/album').replace(
          queryParameters: {'artist_id': artistId},
        );
      } else {
        uri = _uri('/album');
      }

      final res = await http.get(
        uri,
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
                resBodyMap['detail']?.toString() ?? 'List albums failed'),
          );
        }
        return Left(AppFailure('List albums failed (${res.statusCode})'));
      }

      if (resBodyMap is! List) {
        return Left(AppFailure('Invalid response format for albums list'));
      }

      final albums = <AlbumModel>[];
      for (final item in resBodyMap) {
        if (item is Map<String, dynamic>) {
          albums.add(AlbumModel.fromMap(item));
        } else if (item is Map) {
          albums.add(
            AlbumModel.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }

      return Right(albums);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── UPDATE ALBUM ─────────────────
  //
  // PATCH /album/{album_id}
  // body = AlbumUpdate (tutti i campi opzionali)

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
      final uri = _uri('/album/$albumId');

      final body = <String, dynamic>{};

      if (title != null) body['title'] = title.trim();

      if (releaseDate != null) {
        body['release_date'] =
            releaseDate.toIso8601String().split('T').first; // yyyy-MM-dd
      }

      if (label != null) body['label'] = label.trim();
      if (albumType != null) body['album_type'] = albumType.trim();
      if (genre != null) body['genre'] = genre.trim();
      if (coverUrl != null) body['cover_url'] = coverUrl.trim();

      if (artistIds != null) {
        body['artist_ids'] = artistIds;
      }
      if (songIds != null) {
        body['song_ids'] = songIds;
      }

      if (body.isEmpty) {
        return Left(AppFailure('No fields provided for album update'));
      }

      final res = await http.patch(
        uri,
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
                resBodyMap['detail']?.toString() ?? 'Update album failed'),
          );
        }
        return Left(AppFailure('Update album failed (${res.statusCode})'));
      }

      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for AlbumUpdate'));
      }

      final album = AlbumModel.fromMap(
        Map<String, dynamic>.from(resBodyMap),
      );
      return Right(album);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── DELETE ALBUM ─────────────────
  //
  // DELETE /album/{album_id}

  Future<Either<AppFailure, bool>> deleteAlbum({
    required String albumId,
    required String token,
  }) async {
    try {
      final uri = _uri('/album/$albumId');

      final res = await http.delete(
        uri,
        headers: _jsonHeaders(token),
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        dynamic resBodyMap;
        try {
          resBodyMap = jsonDecode(res.body);
        } catch (_) {
          return Left(
            AppFailure('Delete album failed (${res.statusCode})'),
          );
        }

        if (resBodyMap is Map<String, dynamic>) {
          return Left(
            AppFailure(
                resBodyMap['detail']?.toString() ?? 'Delete album failed'),
          );
        }

        return Left(
          AppFailure('Delete album failed (${res.statusCode})'),
        );
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
