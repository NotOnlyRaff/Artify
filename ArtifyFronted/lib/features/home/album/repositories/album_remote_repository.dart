import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/foundation.dart';
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

  Map<String, String> _authHeaders(String token) => {
        'x-auth-token': token,
      };

  // ──────────────── UPLOAD ALBUM COVER ────────────────

  Future<Either<AppFailure, String>> uploadAlbumCover({
    required PickedMedia cover,
    required String token,
  }) async {
    try {
      final uri = _uri('/album/upload-cover');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll(_authHeaders(token));

      if (kIsWeb) {
        if (cover.bytes == null) {
          return Left(AppFailure('Image bytes are null on Web'));
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'cover',
            cover.bytes!,
            filename: cover.name,
          ),
        );
      } else {
        if (cover.filePath == null) {
          return Left(AppFailure('Image path is null on mobile'));
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'cover',
            cover.filePath!,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return Left(
            AppFailure(body['detail']?.toString() ?? 'Upload cover failed'),
          );
        }
        return Left(
          AppFailure('Upload cover failed (${response.statusCode})'),
        );
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response for cover upload'));
      }
      final coverUrl = payload['cover_url']?.toString();
      if (coverUrl == null || coverUrl.isEmpty) {
        return Left(AppFailure('Cover URL missing in response'));
      }

      return Right(coverUrl);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

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
      // 🔹 Mappiamo i SongModel -> SongCreate (schema backend, snake_case)
      final List<Map<String, dynamic>> newSongsPayload = newSongs.map((song) {
        final artistIds = song.artists.map((sa) => sa.artistId).toList();
        final artistRoles = <String, String>{
          for (final sa in song.artists) sa.artistId: sa.role.name,
        };

        return {
          'song_name': song.songName,
          'song_url': song.songUrl,
          'thumbnail_url': song.thumbnailUrl,
          // meglio solo data, visto che il BE usa date
          'release_date': song.releaseDate?.toIso8601String().split('T').first,
          'composer_name': song.composerName,
          'producer_name': song.producerName,
          'genre': song.genre,
          'lyrics': song.lyrics,
          'mood': song.mood,
          'duration_seconds': null,

          'artist_ids': artistIds,
          'artist_roles': artistRoles,
        };
      }).toList();

      final body = <String, dynamic>{
        'title': title,
        'release_date': releaseDate?.toIso8601String().split('T').first,
        'label': label,
        'album_type': albumType,
        'genre': genre,
        'cover_url': coverUrl,
        'artist_ids': artistIds,
        'song_ids': songIds,
        'new_songs': newSongsPayload,
      };

      print('==== [AlbumRemoteRepository] createAlbum BODY ====');
      print(const JsonEncoder.withIndent('  ').convert(body));

      final uri = _uri('/album');

      // usa x-auth-token come tutti gli altri
      final headers = _jsonHeaders(token);
      headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print(
          '[AlbumRemoteRepository] createAlbum status=${response.statusCode}');
      print('[AlbumRemoteRepository] response body=${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        dynamic resBody;
        try {
          resBody = jsonDecode(response.body);
        } catch (_) {
          return Left(
            AppFailure('Album create failed (${response.statusCode})'),
          );
        }

        if (resBody is Map<String, dynamic>) {
          return Left(
            AppFailure(
              resBody['detail']?.toString() ??
                  'Album create failed (${response.statusCode})',
            ),
          );
        }

        return Left(
          AppFailure('Album create failed (${response.statusCode})'),
        );
      }

      final dynamic resBody = jsonDecode(response.body);

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
        body['release_date'] = releaseDate.toIso8601String().split('T').first;
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
