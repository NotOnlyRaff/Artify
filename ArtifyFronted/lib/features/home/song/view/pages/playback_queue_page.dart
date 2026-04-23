import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/view/widgets/space_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaybackQueuePage extends ConsumerWidget {
  const PlaybackQueuePage({super.key});

  String _artistName(PlaybackQueueItem item) {
    final artists = item.song.artists
        .map((artist) => artist.artistName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (artists.isEmpty) return 'Unknown artist';
    return artists.join(', ');
  }

  String _sourceLabel(PlaybackQueueItem item) {
    final label = switch (item.sourceType) {
      PlaybackSourceType.latest => 'Latest today',
      PlaybackSourceType.recent => 'Recently played',
      PlaybackSourceType.library => 'Library',
      PlaybackSourceType.search => 'Search',
      PlaybackSourceType.artist => 'Artist',
      PlaybackSourceType.album => 'Album',
      PlaybackSourceType.playlist => 'Playlist',
      PlaybackSourceType.restored => 'Restored session',
      PlaybackSourceType.manual => 'Manual queue',
    };

    if (item.isManuallyQueued && item.sourceType != PlaybackSourceType.manual) {
      return '$label - added manually';
    }

    return label;
  }

  String _repeatLabel(PlaybackRepeatMode mode) {
    return switch (mode) {
      PlaybackRepeatMode.off => 'Repeat off',
      PlaybackRepeatMode.all => 'Repeat all',
      PlaybackRepeatMode.one => 'Repeat one',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(playbackQueueControllerProvider);
    final queueController = ref.read(playbackQueueControllerProvider.notifier);
    final songNotifier = ref.read(currentSongNotifierProvider.notifier);

    final currentItem = queueState.currentItem;
    final currentIndex = queueState.currentIndex ?? 0;
    final previousItems = queueState.previousItems;
    final upcomingItems = queueState.upcomingItems;
    final queuedCount = queueState.queuedCount;
    final historyCount = queueState.historyCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: SpaceBackground()),
          SafeArea(
            child: !queueState.hasQueue || currentItem == null
                ? _EmptyQueueState(
                    onBack: () => Navigator.of(context).pop(),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _QueueHeader(
                            queuedCount: queuedCount,
                            historyCount: historyCount,
                            onBack: () => Navigator.of(context).pop(),
                            onClear: () async {
                              await queueController.clearQueue();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        SliverToBoxAdapter(
                          child: _QueueOverviewStrip(
                            queuedCount: queuedCount,
                            historyCount: historyCount,
                            repeatLabel: _repeatLabel(queueState.repeatMode),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        const SliverToBoxAdapter(
                          child: _SectionHeading(
                            eyebrow: 'LIVE',
                            title: 'Current track',
                            subtitle:
                                'A dedicated spotlight for the song playing now.',
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        SliverToBoxAdapter(
                          child: _CurrentTrackCard(
                            item: currentItem,
                            artistName: _artistName(currentItem),
                            sourceLabel: _sourceLabel(currentItem),
                            isPlaying: songNotifier.isPlaying,
                            upcomingCount: upcomingItems.length,
                            onPlayPause: () => songNotifier.playPause(),
                            onNext: upcomingItems.isNotEmpty
                                ? () => queueController.skipToNext()
                                : null,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),
                        SliverToBoxAdapter(
                          child: _QueueSectionCard(
                            icon: Icons.upcoming_rounded,
                            eyebrow: 'NEXT',
                            title: 'Up next',
                            subtitle: queuedCount == 0
                                ? 'There are no tracks waiting after the current one.'
                                : '$queuedCount track${queuedCount == 1 ? '' : 's'} lined up after the current song.',
                            child: upcomingItems.isEmpty
                                ? const _InlineMessage(
                                    icon: Icons.queue_music_rounded,
                                    title: 'Queue complete',
                                    subtitle:
                                        'Add more tracks with Play next or Add to queue.',
                                  )
                                : Column(
                                    children: upcomingItems.asMap().entries.map(
                                      (entry) {
                                        final absoluteIndex =
                                            currentIndex + 1 + entry.key;
                                        final item = entry.value;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: entry.key ==
                                                    upcomingItems.length - 1
                                                ? 0
                                                : 14,
                                          ),
                                          child: _UpcomingQueueCard(
                                            item: item,
                                            queuePosition: entry.key + 1,
                                            isFirstUp: entry.key == 0,
                                            artistName: _artistName(item),
                                            sourceLabel: _sourceLabel(item),
                                            onTap: () => queueController
                                                .skipToIndex(absoluteIndex),
                                            onMoveUp:
                                                absoluteIndex > currentIndex + 1
                                                    ? () => queueController
                                                            .moveQueueItem(
                                                          absoluteIndex,
                                                          absoluteIndex - 1,
                                                        )
                                                    : null,
                                            onMoveDown: absoluteIndex <
                                                    queueState.items.length - 1
                                                ? () => queueController
                                                        .moveQueueItem(
                                                      absoluteIndex,
                                                      absoluteIndex + 1,
                                                    )
                                                : null,
                                            onRemove: () =>
                                                queueController.removeQueueItem(
                                              item.queueId,
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                          ),
                        ),
                        if (previousItems.isNotEmpty) ...[
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          SliverToBoxAdapter(
                            child: _QueueSectionCard(
                              icon: Icons.history_rounded,
                              eyebrow: 'BEFORE',
                              title: 'Played in this session',
                              subtitle:
                                  '${previousItems.length} track${previousItems.length == 1 ? '' : 's'} came before the current one in this session.',
                              child: Column(
                                children: previousItems.asMap().entries.map(
                                  (entry) {
                                    final item = entry.value;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: entry.key ==
                                                previousItems.length - 1
                                            ? 0
                                            : 10,
                                      ),
                                      child: _PastQueueCard(
                                        item: item,
                                        artistName: _artistName(item),
                                        sourceLabel: _sourceLabel(item),
                                        onTap: () =>
                                            queueController.skipToIndex(
                                          entry.key,
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  final int queuedCount;
  final int historyCount;
  final VoidCallback onBack;
  final VoidCallback onClear;

  const _QueueHeader({
    required this.queuedCount,
    required this.historyCount,
    required this.onBack,
    required this.onClear,
  });

  String get _subtitle {
    if (queuedCount <= 0 && historyCount <= 0) {
      return 'No tracks are queued after the current song';
    }

    if (queuedCount <= 0) {
      return '$historyCount played already in this session';
    }

    if (historyCount <= 0) {
      return '$queuedCount track${queuedCount == 1 ? '' : 's'} queued after the current song';
    }

    return '$queuedCount queued • $historyCount played earlier';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundHeaderButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Playback queue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _PillActionButton(
          icon: Icons.delete_sweep_rounded,
          label: 'Clear',
          onTap: onClear,
        ),
      ],
    );
  }
}

class _QueueOverviewStrip extends StatelessWidget {
  final int queuedCount;
  final int historyCount;
  final String repeatLabel;

  const _QueueOverviewStrip({
    required this.queuedCount,
    required this.historyCount,
    required this.repeatLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111621).withOpacity(0.88),
            const Color(0xFF211625).withOpacity(0.80),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              label: 'Queued',
              value: '$queuedCount',
              accent: const Color(0xFF58E1FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatPill(
              label: 'Played',
              value: '$historyCount',
              accent: const Color(0xFFFE7A6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatPill(
              label: 'Mode',
              value: repeatLabel,
              accent: const Color(0xFFFFD66B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFFFE7A6B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _QueueSectionCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  const _QueueSectionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF0E1320).withOpacity(0.72),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFE7A6B).withOpacity(0.22),
                      const Color(0xFF58E1FF).withOpacity(0.18),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Color(0xFF58E1FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _CurrentTrackCard extends StatelessWidget {
  final PlaybackQueueItem item;
  final String artistName;
  final String sourceLabel;
  final bool isPlaying;
  final int upcomingCount;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;

  const _CurrentTrackCard({
    required this.item,
    required this.artistName,
    required this.sourceLabel,
    required this.isPlaying,
    required this.upcomingCount,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF211824).withOpacity(0.96),
            const Color(0xFF101A28).withOpacity(0.92),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.13),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE7A6B).withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                label: 'NOW PLAYING',
                background: const Color(0xFFFE7A6B).withOpacity(0.16),
                foreground: Colors.white,
              ),
              _TagChip(
                label: sourceLabel,
                background: Colors.white.withOpacity(0.07),
                foreground: Colors.white70,
              ),
              _TagChip(
                label: upcomingCount == 0
                    ? 'Queue ends here'
                    : '$upcomingCount waiting next',
                background: const Color(0xFF58E1FF).withOpacity(0.12),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Artwork(
                imageUrl: item.song.thumbnailUrl,
                size: 112,
                borderRadius: 24,
                iconSize: 40,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.song.songName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      artistName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _HeroActionButton(
                          icon: isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          label: isPlaying ? 'Pause' : 'Play',
                          onTap: onPlayPause,
                          fillColor: const Color(0xFFFE7A6B),
                          foregroundColor: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        _HeroActionButton(
                          icon: Icons.skip_next_rounded,
                          label: 'Next',
                          onTap: onNext,
                          fillColor: Colors.white.withOpacity(0.08),
                          foregroundColor:
                              onNext != null ? Colors.white : Colors.white38,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingQueueCard extends StatelessWidget {
  final PlaybackQueueItem item;
  final int queuePosition;
  final bool isFirstUp;
  final String artistName;
  final String sourceLabel;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onRemove;

  const _UpcomingQueueCard({
    required this.item,
    required this.queuePosition,
    required this.isFirstUp,
    required this.artistName,
    required this.sourceLabel,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(isFirstUp ? 0.10 : 0.06),
            const Color(0xFF0E1624).withOpacity(isFirstUp ? 0.82 : 0.76),
          ],
        ),
        border: Border.all(
          color: isFirstUp
              ? const Color(0xFF58E1FF).withOpacity(0.34)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: isFirstUp
            ? [
                BoxShadow(
                  color: const Color(0xFF58E1FF).withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isFirstUp
                        ? const Color(0xFF58E1FF).withOpacity(0.16)
                        : Colors.white.withOpacity(0.07),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$queuePosition',
                    style: TextStyle(
                      color: isFirstUp
                          ? Colors.white
                          : Colors.white.withOpacity(0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _Artwork(
                  imageUrl: item.song.thumbnailUrl,
                  size: 66,
                  borderRadius: 18,
                  iconSize: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isFirstUp)
                            _TagChip(
                              label: 'NEXT',
                              background:
                                  const Color(0xFF58E1FF).withOpacity(0.16),
                              foreground: Colors.white,
                            ),
                          if (item.isManuallyQueued)
                            _TagChip(
                              label: 'MANUAL',
                              background:
                                  const Color(0xFFFE7A6B).withOpacity(0.15),
                              foreground: Colors.white,
                            ),
                        ],
                      ),
                      if (isFirstUp || item.isManuallyQueued)
                        const SizedBox(height: 8),
                      Text(
                        item.song.songName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        sourceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniQueueAction(
                      icon: Icons.keyboard_arrow_up_rounded,
                      onTap: onMoveUp,
                    ),
                    const SizedBox(height: 8),
                    _MiniQueueAction(
                      icon: Icons.keyboard_arrow_down_rounded,
                      onTap: onMoveDown,
                    ),
                    const SizedBox(height: 8),
                    _MiniQueueAction(
                      icon: Icons.close_rounded,
                      onTap: onRemove,
                      foregroundColor: const Color(0xFFFFB3AA),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PastQueueCard extends StatelessWidget {
  final PlaybackQueueItem item;
  final String artistName;
  final String sourceLabel;
  final VoidCallback onTap;

  const _PastQueueCard({
    required this.item,
    required this.artistName,
    required this.sourceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.035),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.06),
                ),
                child: const Icon(
                  Icons.history_toggle_off_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.song.songName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$artistName - $sourceLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.replay_rounded,
                color: Colors.white30,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQueueState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyQueueState({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              _RoundHeaderButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF171B27).withOpacity(0.90),
                      const Color(0xFF241823).withOpacity(0.84),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your queue is empty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start a song, then use Play next or Add to queue to build the session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 26,
            color: Colors.white54,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundHeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.07),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color fillColor;
  final Color foregroundColor;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.fillColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: foregroundColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniQueueAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  const _MiniQueueAction({
    required this.icon,
    required this.onTap,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: onTap != null
                ? (foregroundColor ?? Colors.white70)
                : Colors.white24,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final double iconSize;

  const _Artwork({
    required this.imageUrl,
    required this.size,
    required this.borderRadius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : Container(
              width: size,
              height: size,
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
              child: Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
    );
  }
}
