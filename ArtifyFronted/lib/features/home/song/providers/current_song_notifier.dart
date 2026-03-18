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
  late final SongLocalRepository _songLocalRepository;
  late final AudioPlayer _audioPlayer;

  StreamSubscription<PlayerState>? _playerStateSub;

  /// Stato di play/pause (derivato dal player)
  bool isPlaying = false;

  AudioPlayer get audioPlayer => _audioPlayer;

  @override
  SongModel? build() {
    _songLocalRepository = ref.watch(songLocalRepositoryProvider);
    _audioPlayer = AudioPlayer();

    debugPrint('[CurrentSongNotifier] build() – initial state = null');

    // Listener UNICO sullo stato del player
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final processing = playerState.processingState;
      final playing = playerState.playing;

      debugPrint(
        '[CurrentSongNotifier] playerStateStream -> '
        'processing=$processing, playing=$playing',
      );

      // "playing" vero solo se è pronto e in riproduzione
      isPlaying = playing && processing == ProcessingState.ready;

      // Se la traccia è finita, riportiamo a inizio e mettiamo in pausa
      if (processing == ProcessingState.completed) {
        debugPrint('[CurrentSongNotifier] track completed – resetting');
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
        isPlaying = false;
      }

      // Se c'è una song selezionata notifichiamo la UI
      if (state != null) {
        state = state!.copyWith(); // trigger rebuild
      }
    });

    ref.onDispose(() {
      debugPrint(
          '[CurrentSongNotifier] onDispose – cancelling stream + dispose');
      _playerStateSub?.cancel();
      _audioPlayer.dispose();
    });

    // Nessun brano selezionato all’inizios
    return null;
  }

  Future<void> updateSong(SongModel song) async {
    debugPrint(
      '[CurrentSongNotifier] updateSong() called for ${song.id} – ${song.songName}',
    );
    debugPrint(
      '[CurrentSongNotifier] BEFORE – isPlaying=$isPlaying, state=${state?.id}',
    );

    // 🔹 1) Aggiorna SUBITO lo stato, così lo slab e il player vedono la canzone
    state = song;
    isPlaying = false;
    debugPrint(
      '[CurrentSongNotifier] state updated immediately -> ${state?.id}',
    );

    try {
      // 🔹 2) Ferma il brano precedente
      await _audioPlayer.stop();
      debugPrint('[CurrentSongNotifier] audioPlayer.stop() done');

      final artistName = song.artists.isNotEmpty
          ? song.artists.first.artistName // Passa l'artista corretto
          : 'Unknown artist';

      final mediaItem = MediaItem(
        id: song.id,
        title: song.songName,
        artist: artistName, // Assicurati di passare l'artista
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

      debugPrint(
        '[CurrentSongNotifier] setAudioSource -> ${song.songUrl}',
      );

      try {
        await _audioPlayer.setAudioSource(audioSource);
        await _audioPlayer.play();
      } on PlayerException catch (e, st) {
        debugPrint(
            '[PLAYER EXCEPTION] code=${e.code} message=${e.message}\n$st');
      } catch (e, st) {
        debugPrint('[PLAYER ERROR] $e\n$st');
      }

      // 🔹 4) Salva nei recently played (non blocca la UI)
      unawaited(_songLocalRepository.saveRecentlyPlayed(song));
      debugPrint('[CurrentSongNotifier] saved to recently played (async)');

      isPlaying = true;

      // Notifica la UI (MusicSlab, MusicPlayer, ecc.)
      state = state?.copyWith();

      debugPrint(
        '[CurrentSongNotifier] AFTER – isPlaying=$isPlaying, state=${state?.id}',
      );
    } catch (e, st) {
      debugPrint(
        '[CurrentSongNotifier] ERROR in updateSong: $e\n$st',
      );
      isPlaying = false;
      // Notifica comunque per far “aggiornare” UI
      if (state != null) {
        state = state!.copyWith();
      }
    }
  }

  Future<void> playPause() async {
    debugPrint(
      '[CurrentSongNotifier] playPause() – BEFORE isPlaying=$isPlaying, '
      'state=${state?.id}',
    );

    if (state == null) {
      debugPrint(
        '[CurrentSongNotifier] playPause() aborted – state is null (no song)',
      );
      return;
    }

    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }

      isPlaying = !isPlaying;
      state = state?.copyWith();

      debugPrint(
        '[CurrentSongNotifier] playPause() – AFTER isPlaying=$isPlaying',
      );
    } catch (e, st) {
      debugPrint(
        '[CurrentSongNotifier] ERROR in playPause: $e\n$st',
      );
    }
  }

  void seek(double val) {
    final duration = _audioPlayer.duration;
    if (duration == null) {
      debugPrint('[CurrentSongNotifier] seek() – duration is null, abort');
      return;
    }

    final targetMs = (val * duration.inMilliseconds).toInt();
    final target = Duration(milliseconds: targetMs);

    debugPrint(
      '[CurrentSongNotifier] seek() – val=$val -> $targetMs ms '
      '(duration=${duration.inMilliseconds} ms)',
    );

    _audioPlayer.seek(target);
  }
}
