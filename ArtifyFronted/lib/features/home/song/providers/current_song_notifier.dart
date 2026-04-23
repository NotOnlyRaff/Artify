import 'dart:async';

import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
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
  bool _handlingTrackCompletion = false;
  int _playRequestId = 0;

  AudioPlayer get audioPlayer => _audioPlayer;

  SongLocalRepository get _songLocalRepository =>
      ref.read(songLocalRepositoryProvider);

  @override
  SongModel? build() {
    if (!_listenersAttached) {
      _listenersAttached = true;
      Future.microtask(() {
        ref.read(playbackQueueControllerProvider);
        _attachPlayerListeners();
      });
    }

    ref.onDispose(() async {
      debugPrint('[CurrentSongNotifier] onDispose - dispose player');
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
        unawaited(_handleTrackCompleted());
        return;
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

  bool _isStaleRequest(int requestId) => requestId != _playRequestId;

  Future<void> _handleTrackCompleted() async {
    if (_handlingTrackCompletion) return;
    _handlingTrackCompletion = true;

    try {
      final advanced = await ref
          .read(playbackQueueControllerProvider.notifier)
          .handleTrackCompleted();

      if (advanced) return;

      debugPrint('[CurrentSongNotifier] track completed - resetting');
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.pause();
      isPlaying = false;

      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[CurrentSongNotifier] completion handling error: $error\n$stackTrace',
      );
    } finally {
      _handlingTrackCompletion = false;
    }
  }

  Future<void> updateSong(
    SongModel song, {
    bool syncQueue = true,
    bool autoplay = true,
  }) async {
    debugPrint(
      '[CurrentSongNotifier] updateSong() called for ${song.id} - ${song.songName}',
    );

    if (syncQueue) {
      ref
          .read(playbackQueueControllerProvider.notifier)
          .syncSingleSongQueue(song);
    }

    final requestId = ++_playRequestId;

    state = song;
    isPlaying = false;

    try {
      await _audioPlayer.stop();
      if (_isStaleRequest(requestId)) return;

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

      if (_isStaleRequest(requestId)) return;
      debugPrint('[CurrentSongNotifier] setAudioSource -> ${song.songUrl}');
      await _audioPlayer.setAudioSource(audioSource);
      debugPrint('[CurrentSongNotifier] setAudioSource DONE');
      if (_isStaleRequest(requestId)) return;

      if (autoplay) {
        unawaited(_songLocalRepository.saveRecentlyPlayed(song));
        if (_isStaleRequest(requestId)) return;
        await _audioPlayer.play();
        debugPrint('[CurrentSongNotifier] audioPlayer.play() started');
        if (_isStaleRequest(requestId)) return;
        isPlaying = true;
      } else {
        isPlaying = false;
      }

      if (_isStaleRequest(requestId)) return;
      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    } on PlayerException catch (e, st) {
      if (_isStaleRequest(requestId)) return;
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
      if (_isStaleRequest(requestId)) return;
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

  Future<void> stopAndClear() async {
    debugPrint('[CurrentSongNotifier] stopAndClear() called');
    final requestId = ++_playRequestId;

    try {
      await _audioPlayer.stop();
      debugPrint('[CurrentSongNotifier] audioPlayer.stop() DONE');
    } catch (e, st) {
      debugPrint('[CurrentSongNotifier] stopAndClear() ERROR: $e\n$st');
    }

    if (_isStaleRequest(requestId)) return;

    isPlaying = false;
    state = null;
  }

  void seek(double val) {
    final duration = _audioPlayer.duration;
    if (duration == null) return;

    final targetMs = (val * duration.inMilliseconds).toInt();
    _audioPlayer.seek(Duration(milliseconds: targetMs));
  }
}
