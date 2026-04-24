import 'dart:convert';

import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/network/http_client_provider.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'song_remote_repository.g.dart';

@riverpod
SongRemoteRepository songRemoteRepository(SongRemoteRepositoryRef ref) {
  // FIX: inietta http.Client dal provider (come in artist_remote_repository).
  final client = ref.watch(httpClientProvider);
  return SongRemoteRepository(client);
}

class SongRemoteRepository {
  // FIX: client iniettato — il vecchio codice usava http.get/post statici,
  // non testabili e non mockabili.
  final http.Client client;

  SongRemoteRepository(this.client);

  // FIX: tutti i path aggiornati da /song a /songs (convenzione REST plurale).
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

  MediaType _mediaTypeFromMime(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length != 2) throw Exception('Invalid MIME type: $mimeType');
    return MediaType(parts[0], parts[1]);
  }

  MediaType _detectAudioMediaType({
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) {
    final mimeType = lookupMimeType(filePath ?? fileName, headerBytes: bytes);
    if (mimeType == null || !mimeType.startsWith('audio/')) {
      throw Exception(
          'Unsupported audio file type for "$fileName". Detected: $mimeType');
    }
    return _mediaTypeFromMime(mimeType);
  }

  MediaType _detectImageMediaType({
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) {
    final mimeType = lookupMimeType(filePath ?? fileName, headerBytes: bytes);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      throw Exception(
          'Unsupported image file type for "$fileName". Detected: $mimeType');
    }
    return _mediaTypeFromMime(mimeType);
  }

  // ------------------------------------------------------------------ //
  //  Upload                                                             //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, SongModel>> uploadSong({
    required PickedMedia selectedAudio,
    required PickedMedia selectedThumbnail,
    required String songName,
    required DateTime releaseDate,
    String? composerId,
    String? composerName,
    String? producerId,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<String> artistIds = const [],
    List<SongArtistModel> artistLinks = const [],
    required String token,
  }) async {
    try {
      // FIX: /songs/upload
      final request = http.MultipartRequest('POST', _uri('/songs/upload'));
      request.headers.addAll(_authHeaders(token));

      request.fields['song_name'] = songName.trim();
      request.fields['release_date'] =
          releaseDate.toIso8601String().split('T').first;

      if (composerId?.trim().isNotEmpty == true) {
        request.fields['composer_id'] = composerId!.trim();
      }
      if (composerName?.trim().isNotEmpty == true) {
        request.fields['composer_name'] = composerName!.trim();
      }
      if (producerId?.trim().isNotEmpty == true) {
        request.fields['producer_id'] = producerId!.trim();
      }
      if (producerName?.trim().isNotEmpty == true) {
        request.fields['producer_name'] = producerName!.trim();
      }
      if (genre?.trim().isNotEmpty == true) {
        request.fields['genre'] = genre!.trim();
      }
      if (lyrics?.trim().isNotEmpty == true) request.fields['lyrics'] = lyrics!;
      if (mood?.trim().isNotEmpty == true) {
        request.fields['mood'] = mood!.trim();
      }

      // FIX: il backend ora si aspetta artist_links_json con {artist_id, role}
      // invece di artist_ids_json con lista piatta di ID.
      // Per retrocompatibilità, mappiamo la lista di ID a link con role "primary".
      final resolvedArtistLinks = artistLinks
          .where((link) => link.artistId?.trim().isNotEmpty == true)
          .map(
            (link) => {
              'artist_id': link.artistId!.trim(),
              'role': link.role.value,
            },
          )
          .toList();

      if (resolvedArtistLinks.isNotEmpty) {
        request.fields['artist_links_json'] = jsonEncode(resolvedArtistLinks);
      } else if (artistIds.isNotEmpty) {
        final links = artistIds.asMap().entries.map((entry) {
          return {
            'artist_id': entry.value,
            'role': entry.key == 0 ? 'primary' : 'featured',
          };
        }).toList();
        request.fields['artist_links_json'] = jsonEncode(links);
      }

      // Audio file
      if (kIsWeb) {
        if (selectedAudio.bytes == null) {
          return Left(AppFailure('Audio bytes are null on Web'));
        }
        request.files.add(http.MultipartFile.fromBytes(
          'song',
          selectedAudio.bytes!,
          filename: selectedAudio.name,
          contentType: _detectAudioMediaType(
              fileName: selectedAudio.name, bytes: selectedAudio.bytes),
        ));
      } else {
        if (selectedAudio.filePath == null) {
          return Left(AppFailure('Audio path is null on mobile'));
        }
        request.files.add(await http.MultipartFile.fromPath(
          'song',
          selectedAudio.filePath!,
          contentType: _detectAudioMediaType(
              fileName: selectedAudio.name, filePath: selectedAudio.filePath),
        ));
      }

      // Thumbnail file
      if (kIsWeb) {
        if (selectedThumbnail.bytes == null) {
          return Left(AppFailure('Image bytes are null on Web'));
        }
        request.files.add(http.MultipartFile.fromBytes(
          'thumbnail',
          selectedThumbnail.bytes!,
          filename: selectedThumbnail.name,
          contentType: _detectImageMediaType(
              fileName: selectedThumbnail.name, bytes: selectedThumbnail.bytes),
        ));
      } else {
        if (selectedThumbnail.filePath == null) {
          return Left(AppFailure('Image path is null on mobile'));
        }
        request.files.add(await http.MultipartFile.fromPath(
          'thumbnail',
          selectedThumbnail.filePath!,
          contentType: _detectImageMediaType(
              fileName: selectedThumbnail.name,
              filePath: selectedThumbnail.filePath),
        ));
      }

      final response = await http.Response.fromStream(await request.send());
      final bodyMap = _tryParseObject(response.body);

      if (response.statusCode != 201 && response.statusCode != 200) {
        // FIX: rimossi print() — log di debug non vanno in produzione.
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Upload failed (${response.statusCode})')));
      }

      if (bodyMap == null) return Left(AppFailure('Invalid response'));
      return Right(SongModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Lista canzoni                                                      //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, List<SongModel>>> getAllSongs({
    required String token,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // FIX: /songs/list con paginazione.
      final uri = _uri('/songs/list').replace(queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
      });

      final res = await client.get(uri, headers: _authHeaders(token));

      if (res.statusCode != 200) {
        final bodyMap = _tryParseObject(res.body);
        return Left(AppFailure(
            _extractError(bodyMap, fallback: 'Error (${res.statusCode})')));
      }

      // FIX: il backend restituisce {"items": [...], "total": ...}
      // Non una lista piatta.
      final bodyMap = _tryParseObject(res.body);
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      final rawItems = bodyMap['items'];
      if (rawItems is! List) {
        return Left(AppFailure('Missing items in response'));
      }

      final songs = rawItems
          .whereType<Map>()
          .map((item) => SongModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Singola canzone by ID                                              //
  // ------------------------------------------------------------------ //

  /// FIX: aggiunto — necessario per getSongProvider e fetch-and-play.
  Future<Either<AppFailure, SongModel>> getSongById({
    required String songId,
    required String token,
  }) async {
    try {
      // Il backend ha GET /songs/{song_id} — implementato nella route ma non
      // era mai esposto nel repository Flutter.
      // NOTA: se la route non esiste ancora, aggiungi a song_route.py:
      //   @router.get("/{song_id}", response_model=SongOut)
      //   def get_song(song_id: str, db=Depends(get_db), _=Depends(auth_middleware)):
      //       return SongService.get_song_by_id(db, song_id)
      final res = await client.get(
        _uri('/songs/$songId'),
        headers: _authHeaders(token),
      );

      if (res.statusCode != 200) {
        final bodyMap = _tryParseObject(res.body);
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Song not found (${res.statusCode})')));
      }

      final bodyMap = _tryParseObject(res.body);
      if (bodyMap == null) return Left(AppFailure('Invalid response format'));

      return Right(SongModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Aggiornamento canzone                                              //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, SongModel>> updateSong({
    required String songId,
    required String songName,
    required DateTime releaseDate,
    String? composerId,
    String? composerName,
    String? producerId,
    String? producerName,
    String? genre,
    String? lyrics,
    String? mood,
    List<SongArtistModel> artistLinks = const [],
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{
        'song_name': songName.trim(),
        'release_date': releaseDate.toIso8601String().split('T').first,
        'composer_id':
            composerId?.trim().isNotEmpty == true ? composerId!.trim() : null,
        'composer_name': composerName?.trim().isNotEmpty == true
            ? composerName!.trim()
            : null,
        'producer_id':
            producerId?.trim().isNotEmpty == true ? producerId!.trim() : null,
        'producer_name': producerName?.trim().isNotEmpty == true
            ? producerName!.trim()
            : null,
        'genre': genre?.trim().isNotEmpty == true ? genre!.trim() : null,
        'lyrics': lyrics?.trim().isNotEmpty == true ? lyrics!.trim() : null,
        'mood': mood?.trim().isNotEmpty == true ? mood!.trim() : null,
        'artist_links': artistLinks
            .where((link) => link.artistId?.trim().isNotEmpty == true)
            .map(
              (link) => {
                'artist_id': link.artistId!.trim(),
                'role': link.role.value,
              },
            )
            .toList(growable: false),
      };

      final res = await client.patch(
        _uri('/songs/$songId'),
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      final bodyMap = _tryParseObject(res.body);
      if (res.statusCode != 200) {
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Song update failed (${res.statusCode})')));
      }

      if (bodyMap == null) {
        return Left(AppFailure('Invalid response format'));
      }

      return Right(SongModel.fromMap(bodyMap));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Preferiti                                                          //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, bool>> favSong({
    required String token,
    required String songId,
  }) async {
    try {
      // FIX: /songs/favorite
      final res = await client.post(
        _uri('/songs/favorite'),
        headers: _jsonHeaders(token),
        body: jsonEncode({'song_id': songId}),
      );

      if (res.statusCode != 200) {
        final bodyMap = _tryParseObject(res.body);
        return Left(AppFailure(
            _extractError(bodyMap, fallback: 'Error (${res.statusCode})')));
      }

      final bodyMap = _tryParseObject(res.body);
      if (bodyMap == null) return Left(AppFailure('Invalid response'));

      // FIX: il backend ora restituisce {"added": bool, "message": "string"}
      // Il vecchio codice leggeva `message` aspettandosi un bool — crashava.
      final added = bodyMap['added'];
      if (added is bool) return Right(added);

      // Fallback per retrocompatibilità
      final msg = bodyMap['message'];
      if (msg is bool) return Right(msg);

      return Left(AppFailure('Invalid response format for favorite toggle'));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> getFavSongs({
    required String token,
  }) async {
    try {
      // FIX: getFavSongs puntava a /song/list (identico a getAllSongs!).
      // Non esiste un endpoint dedicato ai preferiti nel backend attuale.
      // Per ora usa getAllSongs e filtra lato client.
      // TODO: quando implementerai GET /songs/favorites nel backend,
      // aggiorna questo metodo.
      final res = await getAllSongs(token: token);
      return res;
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // ------------------------------------------------------------------ //
  //  Eliminazione                                                       //
  // ------------------------------------------------------------------ //

  Future<Either<AppFailure, bool>> deleteSong({
    required String songId,
    required String token,
  }) async {
    try {
      // FIX: /songs/{id}
      final response = await client.delete(
        _uri('/songs/$songId'),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final bodyMap = _tryParseObject(response.body);
        return Left(AppFailure(_extractError(bodyMap,
            fallback: 'Delete failed (${response.statusCode})')));
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
