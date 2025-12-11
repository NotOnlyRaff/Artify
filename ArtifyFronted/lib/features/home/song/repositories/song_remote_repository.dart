import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart'; // PickedMedia
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_remote_repository.g.dart';

@riverpod
SongRemoteRepository songRemoteRepository(SongRemoteRepositoryRef ref) {
  return SongRemoteRepository();
}

class SongRemoteRepository {
  Uri _uri(String path) => Uri.parse('${ServerConstant.serverURL}$path');

  Map<String, String> _jsonHeaders(String token) => {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      };

  Map<String, String> _authHeaders(String token) => {
        'x-auth-token': token,
      };

  // ───────────────── UPLOAD SONG ─────────────────

  Future<Either<AppFailure, SongModel>> uploadSong({
    required PickedMedia selectedAudio,
    required PickedMedia selectedThumbnail,
    required String songName,
    required DateTime releaseDate,
    required String composerName,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<String> artistIds = const [],
    required String token,
  }) async {
    try {
      final uri = _uri('/song/upload');
      final request = http.MultipartRequest('POST', uri);

      // header auth (il middleware sul BE legge x-auth-token)
      request.headers.addAll(_authHeaders(token));

      // ----- FORM FIELDS (devono combaciare con i parametri FastAPI) -----
      request.fields['song_name'] = songName.trim();
      request.fields['composer_name'] = composerName.trim();

      // release_date: FastAPI si aspetta una date (YYYY-MM-DD)
      final releaseDateStr =
          releaseDate.toIso8601String().split('T').first; // yyyy-MM-dd
      request.fields['release_date'] = releaseDateStr;

      if (producerName != null && producerName.trim().isNotEmpty) {
        request.fields['producer_name'] = producerName.trim();
      }
      if (genre != null && genre.trim().isNotEmpty) {
        request.fields['genre'] = genre.trim();
      }
      if (lyrics != null && lyrics.trim().isNotEmpty) {
        request.fields['lyrics'] = lyrics;
      }
      if (mood != null && mood.trim().isNotEmpty) {
        request.fields['mood'] = mood.trim();
      }

      // 👇 nuovo: JSON con gli artist id
      if (artistIds.isNotEmpty) {
        request.fields['artist_ids_json'] = jsonEncode(artistIds);
      }

      // ----- AUDIO FILE (FastAPI: song: UploadFile = File(...)) -----
      if (kIsWeb) {
        if (selectedAudio.bytes == null) {
          return Left(AppFailure('Audio bytes are null on Web'));
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'song', // ⚠️ deve chiamarsi "song" come nel BE
            selectedAudio.bytes!,
            filename: selectedAudio.name,
          ),
        );
      } else {
        if (selectedAudio.filePath == null) {
          return Left(AppFailure('Audio path is null on mobile'));
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'song', // ⚠️ deve chiamarsi "song"
            selectedAudio.filePath!,
          ),
        );
      }

      // ----- THUMBNAIL FILE (FastAPI: thumbnail: UploadFile = File(...)) -----
      if (kIsWeb) {
        if (selectedThumbnail.bytes == null) {
          return Left(AppFailure('Image bytes are null on Web'));
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'thumbnail', // ⚠️ deve chiamarsi "thumbnail"
            selectedThumbnail.bytes!,
            filename: selectedThumbnail.name,
          ),
        );
      } else {
        if (selectedThumbnail.filePath == null) {
          return Left(AppFailure('Image path is null on mobile'));
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            selectedThumbnail.filePath!,
          ),
        );
      }

      // ----- INVIO RICHIESTA -----
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201 && response.statusCode != 200) {
        // utile in debug
        print('UPLOAD ERROR STATUS: ${response.statusCode}');
        print('UPLOAD ERROR BODY: ${response.body}');

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          return Left(
            AppFailure(body['detail']?.toString() ?? 'Upload failed'),
          );
        } catch (_) {
          return Left(
            AppFailure('Upload failed (${response.statusCode})'),
          );
        }
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final song = SongModel.fromMap(map);
      return Right(song);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── DELETE SONG ─────────────────

  Future<Either<AppFailure, bool>> deleteSong({
    required String songId,
    required String token,
  }) async {
    try {
      final uri = _uri('/song/$songId');

      final response = await http.delete(
        uri,
        headers: _jsonHeaders(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          return Left(
            AppFailure(body['detail']?.toString() ?? 'Delete failed'),
          );
        } catch (_) {
          return Left(
            AppFailure('Delete failed (${response.statusCode})'),
          );
        }
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── LIST ALL SONGS ──────────────

  Future<Either<AppFailure, List<SongModel>>> getAllSongs({
    required String token,
  }) async {
    try {
      final res = await http.get(
        _uri('/song/list'),
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(AppFailure(resBodyMap['detail']?.toString() ?? 'Error'));
        }
        return Left(AppFailure('Error (${res.statusCode})'));
      }

      if (resBodyMap is! List) {
        return Left(AppFailure('Invalid response format for songs list'));
      }

      final songs = <SongModel>[];
      for (final item in resBodyMap) {
        if (item is Map<String, dynamic>) {
          songs.add(SongModel.fromMap(item));
        } else if (item is Map) {
          songs.add(
            SongModel.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── TOGGLE FAVORITE ─────────────

  Future<Either<AppFailure, bool>> favSong({
    required String token,
    required String songId,
  }) async {
    try {
      final res = await http.post(
        _uri('/song/favorite'),
        headers: _jsonHeaders(token),
        body: jsonEncode(
          {
            'song_id': songId,
          },
        ),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(AppFailure(resBodyMap['detail']?.toString() ?? 'Error'));
        }
        return Left(AppFailure('Error (${res.statusCode})'));
      }

      if (resBodyMap is! Map<String, dynamic>) {
        return Left(AppFailure('Invalid response format for favorite toggle'));
      }

      // BE ritorna {"message": True/False}
      final msg = resBodyMap['message'];
      if (msg is bool) {
        return Right(msg);
      }

      return Left(AppFailure('Invalid "message" field in response'));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ───────────────── LIST FAVORITE SONGS ─────────

  Future<Either<AppFailure, List<SongModel>>> getFavSongs({
    required String token,
  }) async {
    try {
      final res = await http.get(
        _uri('/song/list/favorites'),
        headers: _jsonHeaders(token),
      );

      dynamic resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        if (resBodyMap is Map<String, dynamic>) {
          return Left(AppFailure(resBodyMap['detail']?.toString() ?? 'Error'));
        }
        return Left(AppFailure('Error (${res.statusCode})'));
      }

      if (resBodyMap is! List) {
        return Left(AppFailure('Invalid response format for favorites'));
      }

      final songs = <SongModel>[];
      for (final item in resBodyMap) {
        if (item is Map<String, dynamic>) {
          // ⚠️ Ora il BE ritorna direttamente SongOut, NON più {"song": {...}}
          songs.add(SongModel.fromMap(item));
        } else if (item is Map) {
          songs.add(
            SongModel.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
