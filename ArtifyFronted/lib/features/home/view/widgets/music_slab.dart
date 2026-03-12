import 'dart:ui';

import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/models/fav_song_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/view/widgets/music_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicSlab extends ConsumerWidget {
  const MusicSlab({super.key});

  String _primaryArtistName(SongModel song) {
    if (song.artists.isEmpty) return 'Unknown artist';

    final primary = song.artists
        .where((link) => link.role == SongArtistRole.primary)
        .toList();

    final artistLink = primary.isNotEmpty ? primary.first : song.artists.first;

    // se hai solo artistName usa quello, altrimenti prova artist.name
    return artistLink.artistName ?? artistLink.artistName ?? 'Unknown artist';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongNotifierProvider);

    // Se non c'è una canzone corrente, mostra un MusicSlab vuoto o un placeholder
    if (currentSong == null) {
      return const SizedBox.shrink(); // O un altro placeholder
    }

    final songNotifier = ref.read(currentSongNotifierProvider.notifier);

    final userFavorites = ref.watch(
      currentUserNotifierProvider.select(
        (u) => u?.favorites ?? const <FavSongModel>[],
      ),
    );

    debugPrint(
      '[MusicSlab] build – currentSong: ${currentSong.id} / '
      '${currentSong.songName}',
    );

    final isFav = userFavorites.any((fav) => fav == currentSong.id);

    final size = MediaQuery.of(context).size;
    final slabWidth = size.width - 16;

    return GestureDetector(
        onTap: () {
          debugPrint('[MusicSlab] onTap -> open MusicPlayer');
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return const MusicPlayer();
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final tween =
                    Tween(begin: const Offset(0, 1), end: Offset.zero).chain(
                  CurveTween(curve: Curves.easeOutCubic),
                );
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Sfondo glassmorphism
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 72,
                    width: slabWidth,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF15131F),
                          Color(0xFF24132A),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                ),

                // Contenuto
                Container(
                  height: 72,
                  width: slabWidth,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // Cover
                      Hero(
                        tag: 'music-image',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: currentSong.thumbnailUrl != null
                              ? Image.network(
                                  currentSong.thumbnailUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
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
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Titolo + artista
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.songName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _primaryArtistName(currentSong),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Pallete.subtitleText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Azioni
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isFav
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: isFav ? Pallete.gradient2 : Colors.white70,
                              size: 20,
                            ),
                            onPressed: () async {
                              debugPrint(
                                '[MusicSlab] fav tap – songId=${currentSong.id}',
                              );
                              await ref
                                  .read(songViewModelProvider.notifier)
                                  .favSong(songId: currentSong.id);
                            },
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 34,
                            height: 34,
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
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                songNotifier.isPlaying
                                    ? CupertinoIcons.pause_fill
                                    : CupertinoIcons.play_fill,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () async {
                                debugPrint('[MusicSlab] playPause tap');
                                await songNotifier.playPause();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Barra di progresso (background)
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: Container(
                    height: 3,
                    width: slabWidth - 20,
                    decoration: BoxDecoration(
                      color: Pallete.inactiveSeekColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Barra di progresso (foreground)
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: StreamBuilder<Duration>(
                    stream: songNotifier.audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data;
                      final duration = songNotifier.audioPlayer.duration;

                      if (position == null ||
                          duration == null ||
                          duration.inMilliseconds == 0) {
                        return const SizedBox.shrink();
                      }

                      final ratio =
                          position.inMilliseconds / duration.inMilliseconds;
                      final clamped = ratio.clamp(0.0, 1.0).toDouble();

                      return Container(
                        height: 3,
                        width: clamped * (slabWidth - 20),
                        decoration: BoxDecoration(
                          color: Pallete.whiteColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
