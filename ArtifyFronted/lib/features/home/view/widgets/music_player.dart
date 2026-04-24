import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/home/models/fav_song_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/song/view/pages/playback_queue_page.dart';
import 'package:client/features/home/song/view/widgets/song_playback_actions.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/view/widgets/space_background.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicPlayer extends ConsumerWidget {
  const MusicPlayer({super.key});

  String _primaryArtistName(SongModel song) {
    if (song.artists.isEmpty) return 'Unknown artist';

    try {
      final primary = song.artists
          .where((link) => link.role == SongArtistRole.primary)
          .toList();

      final chosen = primary.isNotEmpty ? primary.first : song.artists.first;
      final candidate = chosen.artistName;

      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate;
      }
    } catch (e, st) {
      debugPrint('[MusicPlayer] _primaryArtistName error: $e\n$st');
    }

    return 'Unknown artist';
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secStr';
  }

  String _repeatLabel(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.off => 'Repeat off',
      PlaybackRepeatMode.all => 'Repeat all',
      PlaybackRepeatMode.one => 'Repeat current track',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongState = ref.watch(currentSongNotifierProvider);
    final currentSong = currentSongState.song;
    final queueState = ref.watch(playbackQueueControllerProvider);
    final songNotifier = ref.read(currentSongNotifierProvider.notifier);
    final queueController = ref.read(playbackQueueControllerProvider.notifier);
    final player = songNotifier.audioPlayer;

    final userFavorites = ref.watch(
      currentUserNotifierProvider.select(
        (u) => u?.favorites ?? const <FavSongModel>[],
      ),
    );

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: const [
            Positioned.fill(child: SpaceBackground()),
            SafeArea(
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
          ],
        ),
      );
    }

    final isFav = userFavorites.any((fav) => fav == currentSong.id);
    final artistName = _primaryArtistName(currentSong);
    final size = MediaQuery.of(context).size;
    final queuedItems = queueState.queuedItems;
    final queuedCount = queueState.queuedCount;
    final queueSongs = queueState.items.map((item) => item.song).toList();
    final currentQueueIndex = queueState.currentIndex ?? 0;

    final repeatColor = queueState.repeatMode == PlaybackRepeatMode.off
        ? Colors.white70
        : Colors.white;
    final repeatIcon = queueState.repeatMode == PlaybackRepeatMode.one
        ? CupertinoIcons.repeat_1
        : CupertinoIcons.repeat;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackground()),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Now Playing',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              queuedCount == 0
                                  ? 'No tracks queued after this one'
                                  : '$queuedCount track${queuedCount == 1 ? '' : 's'} queued next',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => showSongPlaybackActionsSheet(
                            context: context,
                            ref: ref,
                            song: currentSong,
                            contextSongs: queueSongs,
                            startIndex: currentQueueIndex,
                            sourceType: queueState.currentItem?.sourceType ??
                                PlaybackSourceType.manual,
                            sourceId: queueState.currentItem?.sourceId,
                          ),
                          icon: const Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width * 0.8,
                            maxHeight: size.height * 0.45,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
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
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      .toDouble();
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
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
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
                                        showSnackBar(
                                          context,
                                          'Queue MVP is live. Shuffle is the next upgrade.',
                                        );
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.shuffle,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () async {
                                        await queueController.skipToPrevious();
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
                                        onPressed: () async {
                                          await songNotifier.playPause();
                                        },
                                        iconSize: 40,
                                        icon: Icon(
                                          currentSongState.isPlaying
                                              ? CupertinoIcons.pause_fill
                                              : CupertinoIcons.play_fill,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () async {
                                        await queueController.skipToNext();
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
                                        final mode =
                                            queueController.cycleRepeatMode();
                                        showSnackBar(
                                          context,
                                          _repeatLabel(mode),
                                        );
                                      },
                                      icon: Icon(
                                        repeatIcon,
                                        color: repeatColor,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (queuedItems.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Next up',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      queuedItems.first.song.songName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _primaryArtistName(
                                          queuedItems.first.song),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
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
                                if (queuedCount > 0)
                                  Text(
                                    queuedCount > 9 ? '9+' : '$queuedCount',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PlaybackQueuePage(),
                                      ),
                                    );
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
        ],
      ),
    );
  }
}
