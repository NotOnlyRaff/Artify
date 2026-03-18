import 'dart:async';

import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/repositories/song_local_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_song_notifier.g.dart';

@Riverpod(keepAlive: true)
class CurrentSongNotifier extends _$CurrentSongNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlayerException>? _playerErrorSub;

  bool isPlaying = false;
  bool _listenersAttached = false;

  AudioPlayer get audioPlayer => _audioPlayer;

  SongLocalRepository get _songLocalRepository =>
      ref.read(songLocalRepositoryProvider);

  @override
  SongModel? build() {
    if (!_listenersAttached) {
      _listenersAttached = true;
      Future.microtask(_attachPlayerListeners);
    }

    ref.onDispose(() async {
      debugPrint('[CurrentSongNotifier] onDispose – dispose player');
      await _playerStateSub?.cancel();
      await _playerErrorSub?.cancel();
      await _audioPlayer.dispose();
    });

    return null;
  }

  void _attachPlayerListeners() {
    _playerStateSub ??= _audioPlayer.playerStateStream.listen((playerState) {
      final processing = playerState.processingState;
      final playing = playerState.playing;

      debugPrint(
        '[CurrentSongNotifier] playerStateStream -> '
        'processing=$processing, playing=$playing',
      );

      isPlaying = playing && processing == ProcessingState.ready;

      if (processing == ProcessingState.completed) {
        debugPrint('[CurrentSongNotifier] track completed – resetting');
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
        isPlaying = false;
      }

      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    });

    _playerErrorSub ??= _audioPlayer.errorStream.listen((error) {
      debugPrint(
        '[CurrentSongNotifier] PLAYER ERROR -> '
        'code=${error.code}, message=${error.message}, index=${error.index}',
      );
    });
  }

  Future<void> updateSong(SongModel song) async {
    debugPrint(
      '[CurrentSongNotifier] updateSong() called for ${song.id} – ${song.songName}',
    );

    state = song;
    isPlaying = false;

    try {
      await _audioPlayer.stop();

      final artistName = song.artists.isNotEmpty
          ? (song.artists.first.artistName ?? 'Unknown artist')
          : 'Unknown artist';

      final mediaItem = MediaItem(
        id: song.id,
        title: song.songName,
        artist: artistName,
        artUri:
            song.thumbnailUrl != null ? Uri.parse(song.thumbnailUrl!) : null,
        duration: song.durationSeconds != null
            ? Duration(seconds: song.durationSeconds!)
            : null,
      );

      final audioSource = AudioSource.uri(
        Uri.parse(song.songUrl),
        tag: mediaItem,
      );

      debugPrint('[CurrentSongNotifier] setAudioSource -> ${song.songUrl}');
      await _audioPlayer.setAudioSource(audioSource);
      debugPrint('[CurrentSongNotifier] setAudioSource DONE');

      unawaited(_songLocalRepository.saveRecentlyPlayed(song));

      await _audioPlayer.play();
      debugPrint('[CurrentSongNotifier] audioPlayer.play() started');

      isPlaying = true;

      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    } on PlayerException catch (e, st) {
      debugPrint(
        '[CurrentSongNotifier] PlayerException -> '
        'code=${e.code}, message=${e.message}\n$st',
      );
      isPlaying = false;

      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    } catch (e, st) {
      debugPrint('[CurrentSongNotifier] ERROR in updateSong: $e\n$st');
      isPlaying = false;

      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    }
  }

  Future<void> playPause() async {
    final current = state;
    if (current == null) return;

    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }

      isPlaying = !isPlaying;
      state = current.copyWith();
    } catch (e, st) {
      debugPrint('[CurrentSongNotifier] ERROR in playPause: $e\n$st');
    }
  }

  void seek(double val) {
    final duration = _audioPlayer.duration;
    if (duration == null) return;

    final targetMs = (val * duration.inMilliseconds).toInt();
    _audioPlayer.seek(Duration(milliseconds: targetMs));
  }
}
