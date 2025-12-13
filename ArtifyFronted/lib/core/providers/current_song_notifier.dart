import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/model/song_artist_model.dart';
import 'package:client/features/home/song/repositories/song_local_repository.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_song_notifier.g.dart';

@riverpod
class CurrentSongNotifier extends _$CurrentSongNotifier {
  late final SongLocalRepository _songLocalRepository;
  late final AudioPlayer _audioPlayer;

  /// Stato di play/pause
  bool isPlaying = false;

  AudioPlayer get audioPlayer => _audioPlayer;

  @override
  SongModel? build() {
    _songLocalRepository = ref.watch(songLocalRepositoryProvider);
    _audioPlayer = AudioPlayer();

    // Quando il provider viene eliminato, distruggiamo il player
    ref.onDispose(() {
      _audioPlayer.dispose();
    });

    // Nessun brano selezionato all’inizio
    return null;
  }

  /// Prende il nome dell'artista da mostrare:
  /// - se c'è un PRIMARY -> quello
  /// - altrimenti il primo della lista
  String? _getDisplayArtist(SongModel song) {
    if (song.artists.isEmpty) return null;

    final primary = song.artists.where(
      (link) => link.role == SongArtistRole.primary,
    );

    final SongArtistModel chosen =
        primary.isNotEmpty ? primary.first : song.artists.first;

    return chosen.artist.name;
  }

  Future<void> updateSong(SongModel song) async {
    // Stop del brano precedente
    await _audioPlayer.stop();

    final artistName = _getDisplayArtist(song);

    final mediaItem = MediaItem(
      id: song.id,
      title: song.songName,
      artist: artistName,
      artUri: song.thumbnailUrl != null ? Uri.parse(song.thumbnailUrl!) : null,
      duration: song.durationSeconds != null
          ? Duration(seconds: song.durationSeconds!)
          : null,
    );

    final audioSource = AudioSource.uri(
      Uri.parse(song.songUrl),
      tag: mediaItem,
    );

    await _audioPlayer.setAudioSource(audioSource);

    // Listener di fine traccia
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
        isPlaying = false;

        // copia “identica” giusto per triggherare la UI
        state = state?.copyWith();
      }
    });

    // Salva tra i "recently played"
    await _songLocalRepository.saveRecentlyPlayed(song);

    await _audioPlayer.play();
    isPlaying = true;
    state = song;
  }

  Future<void> playPause() async {
    if (state == null) return; // nessuna song selezionata

    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }

    isPlaying = !isPlaying;
    // copia “identica” per notificare la UI
    state = state?.copyWith();
  }

  void seek(double val) {
    if (_audioPlayer.duration == null) return;

    final total = _audioPlayer.duration!;
    final target = Duration(
      milliseconds: (val * total.inMilliseconds).toInt(),
    );
    _audioPlayer.seek(target);
  }
}
