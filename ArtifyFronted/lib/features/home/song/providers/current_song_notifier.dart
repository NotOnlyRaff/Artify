import 'dart:async';

import 'package:client/features/home/song/model/playback_queue_state.dart';
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
  StreamSubscription<int?>? _currentIndexSub;

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
      await _currentIndexSub?.cancel();
      await _audioPlayer.dispose();
    });

    return null;
  }

  void _attachPlayerListeners() {
    _currentIndexSub ??= _audioPlayer.currentIndexStream.listen(
      _handlePlayerQueueIndexChanged,
    );

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

  MediaItem _buildMediaItem(SongModel song) {
    final artistName = song.artists.isNotEmpty
        ? (song.artists.first.artistName ?? 'Unknown artist')
        : 'Unknown artist';

    return MediaItem(
      id: song.id,
      title: song.songName,
      artist: artistName,
      artUri: song.thumbnailUrl != null ? Uri.parse(song.thumbnailUrl!) : null,
      duration: song.durationSeconds != null
          ? Duration(seconds: song.durationSeconds!)
          : null,
    );
  }

  String _normalizedPlaybackUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return trimmed;

    var uri = parsed;
    if (uri.scheme == 'http') {
      uri = uri.replace(scheme: 'https');
    }

    return uri.toString();
  }

  String? _cloudinaryMp3FallbackUrl(String normalizedUrl) {
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final path = uri.path;
    const uploadSegment = '/video/upload/';

    if (host != 'res.cloudinary.com' || !path.contains(uploadSegment)) {
      return null;
    }

    final alreadyTransformed =
        path.contains('/video/upload/f_') || path.contains('/video/upload/q_');
    if (alreadyTransformed) {
      return null;
    }

    final uploadIndex = path.indexOf(uploadSegment);
    final transformedPath =
        '${path.substring(0, uploadIndex + uploadSegment.length)}'
        'f_mp3,q_auto'
        '${path.substring(uploadIndex + uploadSegment.length)}';

    return uri.replace(path: transformedPath).toString();
  }

  List<String> _playbackCandidates(String rawUrl) {
    final normalized = _normalizedPlaybackUrl(rawUrl);
    if (normalized.isEmpty) return const [];

    final candidates = <String>[normalized];
    final cloudinaryFallback = _cloudinaryMp3FallbackUrl(normalized);
    if (cloudinaryFallback != null && cloudinaryFallback != normalized) {
      candidates.add(cloudinaryFallback);
    }
    return candidates;
  }

  AudioSource _buildSongSource(SongModel song, {String? playbackUrl}) {
    return AudioSource.uri(
      Uri.parse(playbackUrl ?? _normalizedPlaybackUrl(song.songUrl)),
      tag: _buildMediaItem(song),
    );
  }

  AudioSource _buildQueueSource(
    List<SongModel> songs, {
    int? overrideIndex,
    String? overrideUrl,
  }) {
    if (songs.length == 1) {
      return _buildSongSource(
        songs.first,
        playbackUrl: overrideIndex == 0 ? overrideUrl : null,
      );
    }

    return ConcatenatingAudioSource(
      children: songs.asMap().entries.map((entry) {
        return _buildSongSource(
          entry.value,
          playbackUrl: entry.key == overrideIndex ? overrideUrl : null,
        );
      }).toList(growable: false),
    );
  }

  LoopMode _loopModeFor(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.off => LoopMode.off,
      PlaybackRepeatMode.all => LoopMode.all,
      PlaybackRepeatMode.one => LoopMode.one,
    };
  }

  Future<void> applyRepeatMode(PlaybackRepeatMode mode) async {
    await _audioPlayer.setLoopMode(_loopModeFor(mode));
  }

  void _handlePlayerQueueIndexChanged(int? index) {
    if (index == null) return;

    final queueState = ref.read(playbackQueueControllerProvider);
    if (queueState.items.isEmpty ||
        index < 0 ||
        index >= queueState.items.length) {
      return;
    }

    final queueSong = queueState.items[index].song;

    if (queueState.currentIndex != index) {
      ref.read(playbackQueueControllerProvider.notifier).syncPlayerIndex(index);
    }

    unawaited(_songLocalRepository.saveRecentlyPlayed(queueSong));

    final current = state;
    if (current == null || current.id != queueSong.id) {
      state = queueSong.copyWith();
      return;
    }

    state = current.copyWith();
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
      final playbackCandidates = _playbackCandidates(song.songUrl);
      if (playbackCandidates.isEmpty) {
        throw StateError('Missing playback URL for song ${song.id}');
      }

      final queueState = ref.read(playbackQueueControllerProvider);
      final queueSongs =
          queueState.items.map((item) => item.song).toList(growable: false);
      final queueIndex = queueState.currentIndex ?? 0;
      final useQueueSource = queueSongs.isNotEmpty &&
          queueIndex >= 0 &&
          queueIndex < queueSongs.length &&
          queueSongs[queueIndex].id == song.id;
      final playbackSongs = useQueueSource ? queueSongs : <SongModel>[song];
      final initialIndex = useQueueSource ? queueIndex : 0;

      await _audioPlayer.stop();
      if (_isStaleRequest(requestId)) return;

      Object? lastError;
      StackTrace? lastStackTrace;
      var started = false;

      for (final playbackUrl in playbackCandidates) {
        try {
          if (_isStaleRequest(requestId)) return;
          await applyRepeatMode(queueState.repeatMode);
          debugPrint('[CurrentSongNotifier] setAudioSource -> $playbackUrl');
          await _audioPlayer.setAudioSource(
            _buildQueueSource(
              playbackSongs,
              overrideIndex: initialIndex,
              overrideUrl: playbackUrl,
            ),
            initialIndex: initialIndex,
            initialPosition: Duration.zero,
          );
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

          started = true;
          break;
        } on PlayerException catch (e, st) {
          lastError = e;
          lastStackTrace = st;
          debugPrint(
            '[CurrentSongNotifier] candidate failed -> '
            'code=${e.code}, message=${e.message}, url=$playbackUrl\n$st',
          );
          try {
            await _audioPlayer.stop();
          } catch (_) {}
        } catch (e, st) {
          lastError = e;
          lastStackTrace = st;
          debugPrint(
            '[CurrentSongNotifier] candidate failed -> url=$playbackUrl\n$e\n$st',
          );
          try {
            await _audioPlayer.stop();
          } catch (_) {}
        }
      }

      if (!started) {
        if (lastError is PlayerException) {
          throw lastError;
        }
        throw StateError(
          'Unable to start playback for ${song.id}: ${lastError ?? 'unknown error'}\n${lastStackTrace ?? ''}',
        );
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

  Future<void> refreshQueueSource({
    bool? autoplay,
    bool preservePosition = true,
  }) async {
    final queueState = ref.read(playbackQueueControllerProvider);
    final songs =
        queueState.items.map((item) => item.song).toList(growable: false);
    final currentIndex = queueState.currentIndex;

    if (songs.isEmpty || currentIndex == null) return;

    final requestId = ++_playRequestId;
    final shouldAutoplay = autoplay ?? isPlaying;
    final currentPosition =
        preservePosition ? _audioPlayer.position : Duration.zero;
    final currentSong = songs[currentIndex];
    final playbackCandidates = _playbackCandidates(currentSong.songUrl);

    if (playbackCandidates.isEmpty) return;

    state = currentSong;

    try {
      Object? lastError;
      StackTrace? lastStackTrace;
      var refreshed = false;

      for (final playbackUrl in playbackCandidates) {
        try {
          await applyRepeatMode(queueState.repeatMode);
          await _audioPlayer.setAudioSource(
            _buildQueueSource(
              songs,
              overrideIndex: currentIndex,
              overrideUrl: playbackUrl,
            ),
            initialIndex: currentIndex,
            initialPosition: currentPosition,
          );
          if (_isStaleRequest(requestId)) return;

          if (shouldAutoplay) {
            await _audioPlayer.play();
            isPlaying = true;
          } else {
            await _audioPlayer.pause();
            isPlaying = false;
          }

          refreshed = true;
          break;
        } on PlayerException catch (e, st) {
          lastError = e;
          lastStackTrace = st;
          debugPrint(
            '[CurrentSongNotifier] refresh candidate failed -> '
            'code=${e.code}, message=${e.message}, url=$playbackUrl\n$st',
          );
          try {
            await _audioPlayer.stop();
          } catch (_) {}
        } catch (e, st) {
          lastError = e;
          lastStackTrace = st;
          debugPrint(
            '[CurrentSongNotifier] refresh candidate failed -> url=$playbackUrl\n$e\n$st',
          );
          try {
            await _audioPlayer.stop();
          } catch (_) {}
        }
      }

      if (!refreshed) {
        throw StateError(
          'Unable to refresh playback for ${currentSong.id}: ${lastError ?? 'unknown error'}\n${lastStackTrace ?? ''}',
        );
      }

      if (_isStaleRequest(requestId)) return;
      final current = state;
      if (current != null) {
        state = current.copyWith();
      }
    } catch (e, st) {
      if (_isStaleRequest(requestId)) return;
      debugPrint('[CurrentSongNotifier] ERROR in refreshQueueSource: $e\n$st');
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
