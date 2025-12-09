import 'dart:convert';
import 'package:client/core/constants/server_constant.dart';
import 'package:client/core/failure/failure.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/models/fav_song_model.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:client/features/home/repositories/home_local_repository.dart';
import 'package:client/features/home/repositories/home_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_viewmodel.g.dart';

@riverpod
Future<List<SongModel>> getAllSongs(GetAllSongsRef ref) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));
  final res = await ref.watch(homeRepositoryProvider).getAllSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

@riverpod
Future<List<SongModel>> getFavSongs(GetFavSongsRef ref) async {
  final token =
      ref.watch(currentUserNotifierProvider.select((user) => user!.token));
  final res = await ref.watch(homeRepositoryProvider).getFavSongs(
        token: token,
      );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

@riverpod
class HomeViewModel extends _$HomeViewModel {
  // 👉 niente più late: li prendo quando mi servono
  HomeRepository get _homeRepository => ref.read(homeRepositoryProvider);
  HomeLocalRepository get _homeLocalRepository =>
      ref.read(homeLocalRepositoryProvider);

  @override
  AsyncValue? build() {
    // stato iniziale: nessuna operazione in corso
    return null;
  }

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

      // Auth header (matcha l'auth_middleware che usa x-auth-token)
      request.headers['x-auth-token'] = token;

      // ----- FORM FIELDS -----
      request.fields['artist'] = artist;
      request.fields['song_name'] = songName;
      request.fields['hex_code'] = hexCode;

      // ----- AUDIO FILE (FastAPI: song: UploadFile = File(...)) -----
      if (kIsWeb) {
        if (selectedAudio.bytes == null) {
          return Left(AppFailure('Audio bytes are null on Web'));
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'song', // ⚠️ deve chiamarsi "song"
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
            'thumbnail', // ⚠️ deve chiamarsi "thumbnail"
            selectedThumbnail.filePath!,
          ),
        );
      }

      // ----- INVIO RICHIESTA -----
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        // Debug utile quando capitano 422
        print('UPLOAD ERROR STATUS: ${response.statusCode}');
        print('UPLOAD ERROR BODY: ${response.body}');

        String message;
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          message = body['detail']?.toString() ?? 'Upload failed';
        } catch (_) {
          message = 'Upload failed (${response.statusCode})';
        }
        return Left(AppFailure(message));
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;

      // FastAPI ritorna direttamente il Song serializzato
      final song = SongModel.fromMap(map);

      return Right(song);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<void> deleteSong({required String songId}) async {
    state = const AsyncValue.loading();

    final res = await _homeRepository.deleteSong(
      songId: songId,
      token: ref.read(currentUserNotifierProvider)!.token,
    );

    switch (res) {
      case Left(:final value):
        state = AsyncValue.error(value.message, StackTrace.current);
      case Right(:final value):
        if (value) {
          // aggiorna user / invalidate provider se serve
          ref.invalidate(getAllSongsProvider);
        }
        state = AsyncValue.data(value);
    }
  }

  // 👉 ora questo non può più dare LateInitializationError
  List<SongModel> getRecentlyPlayedSongs() {
    return _homeLocalRepository.loadSongs();
  }

  Future<void> favSong({required String songId}) async {
    state = const AsyncValue.loading();

    final res = await _homeRepository.favSong(
      songId: songId,
      token: ref.read(currentUserNotifierProvider)!.token,
    );

    final val = switch (res) {
      Left(value: final l) => state =
          AsyncValue.error(l.message, StackTrace.current),
      Right(value: final r) => _favSongSuccess(r, songId),
    };
    print(val);
  }

  AsyncValue _favSongSuccess(bool isFavorited, String songId) {
    final userNotifier = ref.read(currentUserNotifierProvider.notifier);
    final currentUser = ref.read(currentUserNotifierProvider)!;

    if (isFavorited) {
      userNotifier.addUser(
        currentUser.copyWith(
          favorites: [
            ...currentUser.favorites,
            FavSongModel(
              id: '',
              song_id: songId,
              user_id: '',
            ),
          ],
        ),
      );
    } else {
      userNotifier.addUser(
        currentUser.copyWith(
          favorites: currentUser.favorites
              .where((fav) => fav.song_id != songId)
              .toList(),
        ),
      );
    }

    ref.invalidate(getFavSongsProvider);
    return state = AsyncValue.data(isFavorited);
  }
}
