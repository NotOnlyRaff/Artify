import 'dart:ui';

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/home/models/fav_song_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/song/view/pages/playback_queue_page.dart';
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
    return artistLink.artistName ?? 'Unknown artist';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongState = ref.watch(currentSongNotifierProvider);
    final currentSong = currentSongState.song;
    final queueState = ref.watch(playbackQueueControllerProvider);

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final songNotifier = ref.read(currentSongNotifierProvider.notifier);
    final queueController = ref.read(playbackQueueControllerProvider.notifier);

    final userFavorites = ref.watch(
      currentUserNotifierProvider.select(
        (u) => u?.favorites ?? const <FavSongModel>[],
      ),
    );

    final isFav = userFavorites.any((fav) => fav == currentSong.id);
    final queuedUpNext = queueState.queuedCount;
    final queueBadgeText = queuedUpNext > 9 ? '9+' : '$queuedUpNext';

    final size = MediaQuery.of(context).size;
    final slabWidth = size.width - 16;
    final slabHeight = 72.0;
    final currentIndex = queueState.currentIndex ?? 0;
    final canSkipNext = queueState.totalItems > 1 &&
        (currentIndex < queueState.totalItems - 1 ||
            queueState.repeatMode == PlaybackRepeatMode.all);
    final canSkipPrevious = queueState.totalItems > 1 ||
        songNotifier.audioPlayer.position > const Duration(seconds: 3);

    Future<void> openPlayer() async {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const MusicPlayer();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    }

    Future<void> handleSwipe(DragEndDetails details) async {
      final velocity = details.primaryVelocity ?? 0;
      if (velocity <= -240 && canSkipNext) {
        await queueController.skipToNext();
        return;
      }

      if (velocity >= 240 && canSkipPrevious) {
        await queueController.skipToPrevious();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: openPlayer,
                onHorizontalDragEnd: handleSwipe,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: slabHeight,
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
              ),
            ),
            Container(
              height: slabHeight,
              width: slabWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: openPlayer,
                      onHorizontalDragEnd: handleSwipe,
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
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
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _primaryArtistName(currentSong),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Pallete.subtitleText,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    if (queuedUpNext > 0) ...[
                                      const SizedBox(width: 8),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PlaybackQueuePage(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: Colors.white
                                                  .withOpacity(0.08),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.06),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  CupertinoIcons
                                                      .music_note_list,
                                                  size: 11,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  queueBadgeText,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white70,
                                                    height: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                          await ref
                              .read(songViewModelProvider.notifier)
                              .favSong(songId: currentSong.id);
                        },
                      ),
                      const SizedBox(width: 2),
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
                            currentSongState.isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_fill,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () async {
                            await songNotifier.playPause();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    );
  }
}
