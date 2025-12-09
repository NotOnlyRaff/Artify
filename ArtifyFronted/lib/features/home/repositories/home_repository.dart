import 'dart:convert';
import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'home_repository.g.dart';

@riverpod
HomeRepository homeRepository(HomeRepositoryRef ref) {
  return HomeRepository();
}

class HomeRepository {
  Future<Either<AppFailure, SongModel>> uploadSong({
    required PickedMedia selectedAudio,
    required PickedMedia selectedThumbnail,
    required String songName,
    required String artist,
    required String hexCode,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('${ServerConstant.serverURL}/song/upload');

      final request = http.MultipartRequest('POST', uri);

      request.headers['x-auth-token'] = token;

      request.fields['song_name'] = songName;
      request.fields['artist'] = artist;
      request.fields['hex_code'] = hexCode;

      // AUDIO
      if (kIsWeb) {
        if (selectedAudio.bytes == null) {
          return Left(AppFailure('Audio bytes are null on Web'));
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio', // <-- nome field lato FastAPI
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
            'audio',
            selectedAudio.filePath!,
          ),
        );
      }

      // THUMBNAIL
      if (kIsWeb) {
        if (selectedThumbnail.bytes == null) {
          return Left(AppFailure('Image bytes are null on Web'));
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'thumbnail', // <-- nome field lato FastAPI
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201 && response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(AppFailure(body['detail']?.toString() ?? 'Upload failed'));
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final song = SongModel.fromMap(map); // adatta se la risposta è diversa

      return Right(song);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, bool>> deleteSong({
    required String songId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('${ServerConstant.serverURL}/song/$songId');
      // Se il tuo BE ha un path diverso (es. /song/delete/{id}),
      // cambia questa riga di conseguenza.

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return Left(AppFailure(body['detail']?.toString() ?? 'Delete failed'));
      }

      return const Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> getAllSongs({
    required String token,
  }) async {
    try {
      final res = await http
          .get(Uri.parse('${ServerConstant.serverURL}/song/list'), headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      });
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }
      resBodyMap = resBodyMap as List;

      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, bool>> favSong({
    required String token,
    required String songId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ServerConstant.serverURL}/song/favorite'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(
          {
            "song_id": songId,
          },
        ),
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }

      return Right(resBodyMap['message']);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<SongModel>>> getFavSongs({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${ServerConstant.serverURL}/song/list/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      var resBodyMap = jsonDecode(res.body);

      if (res.statusCode != 200) {
        resBodyMap = resBodyMap as Map<String, dynamic>;
        return Left(AppFailure(resBodyMap['detail']));
      }
      resBodyMap = resBodyMap as List;

      List<SongModel> songs = [];

      for (final map in resBodyMap) {
        songs.add(SongModel.fromMap(map['song']));
      }

      return Right(songs);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
