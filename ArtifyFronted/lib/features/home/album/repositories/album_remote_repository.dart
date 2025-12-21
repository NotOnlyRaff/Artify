import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
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
  //   "genre": "...",
  //   "cover_url": "...",
  //   "artist_ids": ["..."],
  //   "song_ids": ["..."]   // 👈 ID di Song già esistenti
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
    List<SongModel> newSongs = const [],
    required String token,
  }) async {
    try {
      final uri = _uri('/album');

      final body = <String, dynamic>{
        'title': title.trim(),
        'artist_ids': artistIds,
        'song_ids': songIds,
        'new_song': newSongs.map((e) => e.toJson()).toList(),
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

      final dynamic resBody = jsonDecode(res.body);

      if (res.statusCode != 201) {
        if (resBody is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBody['detail']?.toString() ?? 'Create album failed',
            ),
          );
        }
        return Left(AppFailure('Create album failed (${res.statusCode})'));
      }

      if (resBody is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for AlbumCreate'));
      }

      final album = AlbumModel.fromMap(
        Map<String, dynamic>.from(resBody),
      );
      return Right(album);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── GET SINGLE ALBUM ─────────────

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

      final dynamic resBody = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBody is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBody['detail']?.toString() ?? 'Get album failed',
            ),
          );
        }
        return Left(AppFailure('Get album failed (${res.statusCode})'));
      }

      if (resBody is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for AlbumOut'));
      }

      final album = AlbumModel.fromMap(
        Map<String, dynamic>.from(resBody),
      );
      return Right(album);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── LIST ALBUMS ──────────────────

  Future<Either<AppFailure, List<AlbumModel>>> listAlbums({
    required String token,
    String? artistId,
  }) async {
    try {
      Uri uri;
      if (artistId != null && artistId.isNotEmpty) {
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

      final dynamic resBody = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBody is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBody['detail']?.toString() ?? 'List albums failed',
            ),
          );
        }
        return Left(AppFailure('List albums failed (${res.statusCode})'));
      }

      if (resBody is! List) {
        return Left(AppFailure('Invalid response format for albums list'));
      }

      final albums = <AlbumModel>[];
      for (final item in resBody) {
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
            releaseDate.toIso8601String().split('T').first;
      }
      if (label != null) body['label'] = label.trim();
      if (albumType != null) body['album_type'] = albumType.trim();
      if (genre != null) body['genre'] = genre.trim();
      if (coverUrl != null) body['cover_url'] = coverUrl.trim();
      if (artistIds != null) body['artist_ids'] = artistIds;
      if (songIds != null) body['song_ids'] = songIds;

      if (body.isEmpty) {
        return Left(AppFailure('No fields provided for album update'));
      }

      final res = await http.patch(
        uri,
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      final dynamic resBody = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBody is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBody['detail']?.toString() ?? 'Update album failed',
            ),
          );
        }
        return Left(AppFailure('Update album failed (${res.statusCode})'));
      }

      if (resBody is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for AlbumUpdate'));
      }

      final album = AlbumModel.fromMap(
        Map<String, dynamic>.from(resBody),
      );
      return Right(album);
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
      final uri = _uri('/album/$albumId');

      final res = await http.delete(
        uri,
        headers: _jsonHeaders(token),
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        dynamic resBody;
        try {
          resBody = jsonDecode(res.body);
        } catch (_) {
          return Left(
            AppFailure('Delete album failed (${res.statusCode})'),
          );
        }

        if (resBody is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBody['detail']?.toString() ?? 'Delete album failed',
            ),
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
