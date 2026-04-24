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

// ---------------------------------------------------------------------------
// Stato unificato — song + isPlaying nello stesso oggetto Riverpod.
// ---------------------------------------------------------------------------
class CurrentSongState {
  final SongModel? song;
  final bool isPlaying;

  const CurrentSongState({this.song, this.isPlaying = false});

  CurrentSongState copyWith({
    SongModel? song,
    bool? isPlaying,
    bool clearSong = false,
  }) {
    return CurrentSongState(
      song: clearSong ? null : (song ?? this.song),
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentSongState &&
          song?.id == other.song?.id &&
          isPlaying == other.isPlaying;

  @override
  int get hashCode => Object.hash(song?.id, isPlaying);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
@Riverpod(keepAlive: true)
class CurrentSongNotifier extends _$CurrentSongNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // IMPORTANTE: lista MUTABILE. `const []` su web (dart2js) causa il crash
  //   Unsupported operation: set length
  // quando `just_audio` prova a fare clear()/length=0 sulla lista interna.
  final ConcatenatingAudioSource _queueSource = ConcatenatingAudioSource(
    children: <AudioSource>[],
    useLazyPreparation: true,
  );

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlayerException>? _playerErrorSub;
  StreamSubscription<int?>? _currentIndexSub;

  // Coda pura a catena di Future — zero race condition, zero flag sincroni.
  Future<void> _mutationQueue = Future<void>.value();

  int _playRequestId = 0;
  List<String> _loadedSequenceIds = const [];
  bool _sourceInitialized = false;
  bool _listenersAttached = false;

  AudioPlayer get audioPlayer => _audioPlayer;

  // Getter di comodità usati dal queue controller (compat API).
  bool get isPlaying => state.isPlaying;
  bool get hasLoadedSequence => _sourceInitialized;

  SongLocalRepository get _songLocalRepository =>
      ref.read(songLocalRepositoryProvider);

  void _triggerPlayDirect({String context = 'play'}) {
    unawaited(
      _audioPlayer.play().catchError((error, stackTrace) {
        debugPrint(
          '[CurrentSongNotifier] $context play() error: $error\n$stackTrace',
        );
        state = state.copyWith(isPlaying: false);
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Mutation queue: ogni chiamata attende la precedente. Niente flag booleani
  // sincroni, niente possibilità che due mutazioni partano in parallelo.
  // ---------------------------------------------------------------------------
  Future<T> _runPlayerMutation<T>(Future<T> Function() action) {
    final result = _mutationQueue.then<T>((_) => action());
    _mutationQueue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  CurrentSongState build() {
    if (!_listenersAttached) {
      _listenersAttached = true;
      Future.microtask(() {
        ref.read(playbackQueueControllerProvider);
        _attachPlayerListeners();
      });
    }

    ref.onDispose(() async {
      debugPrint('[CurrentSongNotifier] onDispose');
      await _playerStateSub?.cancel();
      await _playerErrorSub?.cancel();
      await _currentIndexSub?.cancel();
      await _audioPlayer.dispose();
    });

    return const CurrentSongState();
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

      final isNowPlaying = playing && processing != ProcessingState.completed;
      if (state.isPlaying != isNowPlaying) {
        state = state.copyWith(isPlaying: isNowPlaying);
      }
    });

    _playerErrorSub ??= _audioPlayer.errorStream.listen((error) {
      debugPrint(
        '[CurrentSongNotifier] PLAYER ERROR -> '
        'code=${error.code}, message=${error.message}, index=${error.index}',
      );
    });
  }

  // ---------------------------------------------------------------------------
  // URL helpers
  // ---------------------------------------------------------------------------
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
    if (uri.scheme == 'http') uri = uri.replace(scheme: 'https');

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

    if (path.contains('/video/upload/f_') ||
        path.contains('/video/upload/q_')) {
      return null;
    }

    final uploadIndex = path.indexOf(uploadSegment);
    // FIX: aggiunto `/` finale. Prima produceva URL malformati tipo
    // `/video/upload/f_mp3,q_autov1776985940/...` che Cloudinary non accetta.
    final transformedPath =
        '${path.substring(0, uploadIndex + uploadSegment.length)}'
        'f_mp3,q_auto/'
        '${path.substring(uploadIndex + uploadSegment.length)}';

    return uri.replace(path: transformedPath).toString();
  }

  List<String> _playbackCandidates(String rawUrl) {
    final normalized = _normalizedPlaybackUrl(rawUrl);
    if (normalized.isEmpty) return const [];

    final candidates = <String>[normalized];
    final fallback = _cloudinaryMp3FallbackUrl(normalized);
    if (fallback != null && fallback != normalized) candidates.add(fallback);
    return candidates;
  }

  AudioSource _buildSongSource(SongModel song, {String? playbackUrl}) {
    return AudioSource.uri(
      Uri.parse(playbackUrl ?? _normalizedPlaybackUrl(song.songUrl)),
      tag: _buildMediaItem(song),
    );
  }

  List<AudioSource> _buildSequenceSources(
    List<SongModel> songs, {
    int? overrideIndex,
    String? overrideUrl,
  }) {
    return songs.asMap().entries.map((entry) {
      return _buildSongSource(
        entry.value,
        playbackUrl: entry.key == overrideIndex ? overrideUrl : null,
      );
    }).toList(growable: false);
  }

  LoopMode _loopModeFor(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.off => LoopMode.off,
      PlaybackRepeatMode.all => LoopMode.all,
      PlaybackRepeatMode.one => LoopMode.one,
    };
  }

  Future<void> _applyRepeatModeDirect(PlaybackRepeatMode mode) =>
      _audioPlayer.setLoopMode(_loopModeFor(mode));

  bool _matchesLoadedSequence(List<SongModel> songs) {
    if (!_sourceInitialized || songs.length != _loadedSequenceIds.length) {
      return false;
    }
    for (var i = 0; i < songs.length; i++) {
      if (_loadedSequenceIds[i] != songs[i].id) return false;
    }
    return true;
  }

  bool _isStaleRequest(int requestId) => requestId != _playRequestId;

  void _handlePlayerQueueIndexChanged(int? index) {
    if (index == null) return;

    final queueState = ref.read(playbackQueueControllerProvider);
    if (queueState.items.isEmpty ||
        index < 0 ||
        index >= queueState.items.length) return;

    final queueSong = queueState.items[index].song;

    if (queueState.currentIndex != index) {
      ref.read(playbackQueueControllerProvider.notifier).syncPlayerIndex(index);
    }

    unawaited(_songLocalRepository.saveRecentlyPlayed(queueSong));

    if (state.song?.id != queueSong.id) {
      state = state.copyWith(song: queueSong.copyWith());
    }
  }

  // ---------------------------------------------------------------------------
  // Core loading
  // ---------------------------------------------------------------------------
  Future<void> _loadSequence({
    required List<SongModel> songs,
    required int initialIndex,
    required Duration initialPosition,
    required String playbackUrl,
    required bool autoplay,
    required int requestId,
  }) async {
    // clear() solo se c'è effettivamente qualcosa dentro — evita di toccare
    // la lista interna in casi edge.
    if (_queueSource.length > 0) {
      await _queueSource.clear();
    }
    await _queueSource.addAll(
      _buildSequenceSources(
        songs,
        overrideIndex: initialIndex,
        overrideUrl: playbackUrl,
      ),
    );
    _loadedSequenceIds = songs.map((s) => s.id).toList(growable: false);
    _sourceInitialized = true;

    if (_isStaleRequest(requestId)) return;

    await _audioPlayer.setAudioSource(
      _queueSource,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );

    if (_isStaleRequest(requestId)) return;

    if (autoplay) {
      _triggerPlayDirect(context: '_loadSequence');
      state = state.copyWith(isPlaying: true);
    } else {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------
  Future<void> applyRepeatMode(PlaybackRepeatMode mode) =>
      _runPlayerMutation(() => _applyRepeatModeDirect(mode));

  Future<void> updateSong(
    SongModel song, {
    bool syncQueue = true,
    bool autoplay = true,
  }) async {
    debugPrint(
      '[CurrentSongNotifier] updateSong() -> ${song.id} - ${song.songName}',
    );

    if (syncQueue) {
      ref
          .read(playbackQueueControllerProvider.notifier)
          .syncSingleSongQueue(song);
    }

    final requestId = ++_playRequestId;
    state = state.copyWith(song: song);

    await _runPlayerMutation(() async {
      try {
        final candidates = _playbackCandidates(song.songUrl);
        if (candidates.isEmpty) {
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

        await _applyRepeatModeDirect(queueState.repeatMode);
        if (_isStaleRequest(requestId)) return;

        if (_matchesLoadedSequence(playbackSongs)) {
          await _audioPlayer.seek(Duration.zero, index: initialIndex);
          if (_isStaleRequest(requestId)) return;

          if (autoplay) {
            unawaited(_songLocalRepository.saveRecentlyPlayed(song));
            _triggerPlayDirect(context: 'updateSong.reuseSequence');
            state = state.copyWith(isPlaying: true);
          } else {
            await _audioPlayer.pause();
            state = state.copyWith(isPlaying: false);
          }
          return;
        }

        Object? lastError;
        StackTrace? lastStackTrace;
        var started = false;

        for (final url in candidates) {
          if (_isStaleRequest(requestId)) return;
          try {
            debugPrint('[CurrentSongNotifier] loadSequence -> $url');
            await _loadSequence(
              songs: playbackSongs,
              initialIndex: initialIndex,
              initialPosition: Duration.zero,
              playbackUrl: url,
              autoplay: autoplay,
              requestId: requestId,
            );
            if (_isStaleRequest(requestId)) return;
            if (autoplay) {
              unawaited(_songLocalRepository.saveRecentlyPlayed(song));
            }
            started = true;
            break;
          } on PlayerException catch (e, st) {
            lastError = e;
            lastStackTrace = st;
            debugPrint(
              '[CurrentSongNotifier] candidate failed -> '
              'code=${e.code}, message=${e.message}, url=$url\n$st',
            );
          } catch (e, st) {
            lastError = e;
            lastStackTrace = st;
            debugPrint(
              '[CurrentSongNotifier] candidate failed -> url=$url\n$e\n$st',
            );
          }
        }

        if (!started) {
          Error.throwWithStackTrace(
            lastError is PlayerException
                ? lastError
                : StateError(
                    'Unable to start playback for ${song.id}: $lastError',
                  ),
            lastStackTrace ?? StackTrace.current,
          );
        }
      } on PlayerException catch (e, st) {
        if (_isStaleRequest(requestId)) return;
        debugPrint(
          '[CurrentSongNotifier] PlayerException -> '
          'code=${e.code}, message=${e.message}\n$st',
        );
        state = state.copyWith(isPlaying: false);
      } catch (e, st) {
        if (_isStaleRequest(requestId)) return;
        debugPrint('[CurrentSongNotifier] ERROR in updateSong: $e\n$st');
        state = state.copyWith(isPlaying: false);
      }
    });
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
    final shouldAutoplay = autoplay ?? state.isPlaying;
    final currentSong = songs[currentIndex];
    final candidates = _playbackCandidates(currentSong.songUrl);

    if (candidates.isEmpty) return;

    state = state.copyWith(song: currentSong);

    await _runPlayerMutation(() async {
      // Posizione letta DENTRO la mutation per evitare valori stale.
      final currentPosition =
          preservePosition ? _audioPlayer.position : Duration.zero;

      try {
        Object? lastError;
        StackTrace? lastStackTrace;
        var refreshed = false;

        for (final url in candidates) {
          if (_isStaleRequest(requestId)) return;
          try {
            await _applyRepeatModeDirect(queueState.repeatMode);
            await _loadSequence(
              songs: songs,
              initialIndex: currentIndex,
              initialPosition: currentPosition,
              playbackUrl: url,
              autoplay: shouldAutoplay,
              requestId: requestId,
            );
            refreshed = true;
            break;
          } on PlayerException catch (e, st) {
            lastError = e;
            lastStackTrace = st;
            debugPrint(
              '[CurrentSongNotifier] refresh candidate failed -> '
              'code=${e.code}, message=${e.message}, url=$url\n$st',
            );
          } catch (e, st) {
            lastError = e;
            lastStackTrace = st;
            debugPrint(
              '[CurrentSongNotifier] refresh candidate failed -> '
              'url=$url\n$e\n$st',
            );
          }
        }

        if (!refreshed) {
          throw StateError(
            'Unable to refresh playback for ${currentSong.id}: '
            '${lastError ?? 'unknown error'}\n${lastStackTrace ?? ''}',
          );
        }
      } catch (e, st) {
        if (_isStaleRequest(requestId)) return;
        debugPrint(
            '[CurrentSongNotifier] ERROR in refreshQueueSource: $e\n$st');
      }
    });
  }

  Future<void> insertIntoQueueSequence(
    int index,
    List<SongModel> songs,
  ) async {
    await _runPlayerMutation(() async {
      if (songs.isEmpty || !_sourceInitialized) return;

      final safeIndex = index.clamp(0, _queueSource.length);
      await _queueSource.insertAll(safeIndex, _buildSequenceSources(songs));

      final updatedIds = [..._loadedSequenceIds];
      updatedIds.insertAll(safeIndex, songs.map((s) => s.id));
      _loadedSequenceIds = updatedIds;
    });
  }

  Future<void> moveInQueueSequence(int oldIndex, int newIndex) async {
    await _runPlayerMutation(() async {
      if (!_sourceInitialized ||
          oldIndex < 0 ||
          oldIndex >= _queueSource.length ||
          newIndex < 0 ||
          newIndex >= _queueSource.length ||
          oldIndex == newIndex) return;

      await _queueSource.move(oldIndex, newIndex);

      final updatedIds = [..._loadedSequenceIds];
      final moved = updatedIds.removeAt(oldIndex);
      updatedIds.insert(newIndex, moved);
      _loadedSequenceIds = updatedIds;
    });
  }

  Future<void> removeFromQueueSequence(
    int index, {
    int? replacementIndex,
    bool autoplay = false,
  }) async {
    await _runPlayerMutation(() async {
      if (!_sourceInitialized ||
          index < 0 ||
          index >= _queueSource.length ||
          index >= _loadedSequenceIds.length) return;

      final removingCurrent = _audioPlayer.currentIndex == index;

      await _queueSource.removeAt(index);

      final updatedIds = [..._loadedSequenceIds]..removeAt(index);
      _loadedSequenceIds = updatedIds;

      if (removingCurrent && replacementIndex != null) {
        await _audioPlayer.seek(Duration.zero, index: replacementIndex);
        if (autoplay) {
          _triggerPlayDirect(context: 'removeFromQueueSequence');
          state = state.copyWith(isPlaying: true);
        } else {
          await _audioPlayer.pause();
          state = state.copyWith(isPlaying: false);
        }
      }
    });
  }

  Future<void> seekToQueueIndex(int index, {bool autoplay = true}) async {
    await _runPlayerMutation(() async {
      if (!_sourceInitialized ||
          index < 0 ||
          index >= _queueSource.length ||
          index >= _loadedSequenceIds.length) return;

      await _audioPlayer.seek(Duration.zero, index: index);

      if (autoplay) {
        _triggerPlayDirect(context: 'seekToQueueIndex');
        state = state.copyWith(isPlaying: true);
      } else {
        await _audioPlayer.pause();
        state = state.copyWith(isPlaying: false);
      }
    });
  }

  Future<void> playPause() async {
    if (state.song == null) return;

    await _runPlayerMutation(() async {
      try {
        if (state.isPlaying) {
          await _audioPlayer.pause();
          state = state.copyWith(isPlaying: false);
        } else {
          _triggerPlayDirect(context: 'playPause');
          state = state.copyWith(isPlaying: true);
        }
      } catch (e, st) {
        debugPrint('[CurrentSongNotifier] ERROR in playPause: $e\n$st');
      }
    });
  }

  Future<void> stopAndClear() async {
    debugPrint('[CurrentSongNotifier] stopAndClear()');
    final requestId = ++_playRequestId;

    await _runPlayerMutation(() async {
      try {
        await _audioPlayer.stop();
        if (_queueSource.length > 0) {
          await _queueSource.clear();
        }
      } catch (e, st) {
        debugPrint('[CurrentSongNotifier] stopAndClear() ERROR: $e\n$st');
      }

      _sourceInitialized = false;
      _loadedSequenceIds = const [];

      if (_isStaleRequest(requestId)) return;

      state = const CurrentSongState();
    });
  }

  // seek() nella mutation queue — non interferisce più con altre operazioni.
  Future<void> seek(double val) {
    return _runPlayerMutation(() async {
      final duration = _audioPlayer.duration;
      if (duration == null) return;

      final targetMs = (val * duration.inMilliseconds).toInt();
      await _audioPlayer.seek(Duration(milliseconds: targetMs));
    });
  }
}
