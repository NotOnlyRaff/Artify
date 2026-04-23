import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> playSongsFromSource({
  required WidgetRef ref,
  required List<SongModel> songs,
  required int startIndex,
  PlaybackSourceType sourceType = PlaybackSourceType.manual,
  String? sourceId,
}) async {
  await ref.read(playbackQueueControllerProvider.notifier).playSongs(
        songs,
        startIndex: startIndex,
        sourceType: sourceType,
        sourceId: sourceId,
      );
}

Future<void> playSingleSongNow({
  required WidgetRef ref,
  required SongModel song,
  PlaybackSourceType sourceType = PlaybackSourceType.manual,
  String? sourceId,
}) async {
  await ref.read(playbackQueueControllerProvider.notifier).playSongNow(
        song,
        sourceType: sourceType,
        sourceId: sourceId,
      );
}

Future<void> showSongPlaybackActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required SongModel song,
  List<SongModel>? contextSongs,
  int? startIndex,
  PlaybackSourceType sourceType = PlaybackSourceType.manual,
  String? sourceId,
}) async {
  final effectiveSongs = contextSongs != null && contextSongs.isNotEmpty
      ? contextSongs
      : <SongModel>[song];
  final effectiveIndex = startIndex ??
      effectiveSongs.indexWhere((candidate) => candidate.id == song.id);
  final resolvedIndex = effectiveIndex >= 0 ? effectiveIndex : 0;

  Future<void> execute(Future<void> Function() action) async {
    Navigator.of(context).pop();
    await action();
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12131A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white),
                title: const Text(
                  'Play now',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  effectiveSongs.length > 1
                      ? 'Play inside the current source queue'
                      : 'Replace playback with this track',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => execute(
                  () => ref
                      .read(playbackQueueControllerProvider.notifier)
                      .playSongNow(
                        song,
                        contextSongs: effectiveSongs,
                        startIndex: resolvedIndex,
                        sourceType: sourceType,
                        sourceId: sourceId,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.queue_play_next_rounded,
                    color: Colors.white),
                title: const Text(
                  'Play next',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Insert right after the current track',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => execute(
                  () => ref
                      .read(playbackQueueControllerProvider.notifier)
                      .playNext(
                        song,
                        sourceType: sourceType,
                        sourceId: sourceId,
                      ),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.playlist_add_rounded, color: Colors.white),
                title: const Text(
                  'Add to queue',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Send this track to the end of the queue',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => execute(
                  () => ref
                      .read(playbackQueueControllerProvider.notifier)
                      .addToQueue(
                        song,
                        sourceType: sourceType,
                        sourceId: sourceId,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
