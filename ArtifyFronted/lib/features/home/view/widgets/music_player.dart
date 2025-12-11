import 'dart:ui';

import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/song/model/song_artist_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicPlayer extends ConsumerWidget {
  const MusicPlayer({super.key});

  String _primaryArtistName(song) {
    if (song.artists.isEmpty) return 'Unknown artist';

    final primary = song.artists
        .where((link) => link.role == SongArtistRole.primary)
        .toList();

    final artistLink = primary.isNotEmpty ? primary.first : song.artists.first;
    return artistLink.artist.name;
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongNotifierProvider);
    final songNotifier = ref.read(currentSongNotifierProvider.notifier);
    final userFavorites = ref.watch(
      currentUserNotifierProvider.select(
        (u) => u?.favorites ?? const [],
      ),
    );

    // Se per qualche motivo non c'è un brano selezionato
    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Text(
              'No track playing',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    final isFav = userFavorites.any((fav) => fav.song_id == currentSong.id);
    final artistName = _primaryArtistName(currentSong);
    final player = songNotifier.audioPlayer;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050509),
            Color(0xFF140813),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // 🔹 Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Now Playing',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // futuro: queue, cast, ecc.
                      },
                      icon: const Icon(
                        CupertinoIcons.ellipsis,
                        color: Colors.white70,
                      ),
                    )
                  ],
                ),
              ),

              // 🔹 ARWORK
              Expanded(
                flex: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Hero(
                    tag: 'music-image',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          currentSong.thumbnailUrl != null
                              ? Image.network(
                                  currentSong.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF811F1A),
                                        Color(0xFF4B39EF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white,
                                    size: 72,
                                  ),
                                ),
                          // leggero overlay per rendere il testo più leggibile se un giorno lo metti sopra
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.45),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 🔹 Dettagli + controlli
              Expanded(
                flex: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:
                          MainAxisSize.min, // non obbligatorio ma pulito
                      children: [
                        // Titolo + artista + cuore
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.songName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Pallete.whiteColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    artistName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Pallete.subtitleText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ref
                                    .read(songViewModelProvider.notifier)
                                    .favSong(songId: currentSong.id);
                              },
                              icon: Icon(
                                isFav
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                color: isFav
                                    ? Pallete.gradient2
                                    : Pallete.whiteColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Slider + tempi
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration = player.duration;

                            double sliderValue = 0.0;
                            bool canSeek = false;

                            if (duration != null &&
                                duration.inMilliseconds > 0) {
                              sliderValue = (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                                  .toDouble(); // piccolo hardening
                              canSeek = true;
                            }

                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white12,
                                    thumbColor: Colors.white,
                                    trackHeight: 4,
                                    overlayShape:
                                        SliderComponentShape.noOverlay,
                                  ),
                                  child: Slider(
                                    value: sliderValue,
                                    min: 0,
                                    max: 1,
                                    onChanged: canSeek ? (_) {} : null,
                                    onChangeEnd:
                                        canSeek ? songNotifier.seek : null,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Pallete.subtitleText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Pallete.subtitleText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // 🔹 Controlli principali
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withOpacity(0.03),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // TODO: shuffle logic
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.shuffle,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    // TODO: previous track
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.backward_end_alt_fill,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF811F1A),
                                        Color(0xFF4B39EF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: songNotifier.playPause,
                                    iconSize: 40,
                                    icon: Icon(
                                      songNotifier.isPlaying
                                          ? CupertinoIcons.pause_fill
                                          : CupertinoIcons.play_fill,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    // TODO: next track
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.forward_end_alt_fill,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    // TODO: repeat logic
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.repeat,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 🔹 Bottom row (device, queue, ecc.)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                // TODO: connect device / output
                              },
                              icon: const Icon(
                                CupertinoIcons.hifispeaker_fill,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'This device',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                // TODO: open queue
                              },
                              icon: const Icon(
                                CupertinoIcons.music_note_list,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
