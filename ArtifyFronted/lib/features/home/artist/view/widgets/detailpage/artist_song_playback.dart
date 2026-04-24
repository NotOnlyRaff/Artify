import 'package:client/core/utils.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/providers/playback_queue_controller.dart';
import 'package:client/features/home/song/view/widgets/song_playback_actions.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> playArtistSongRef({
  required BuildContext context,
  required WidgetRef ref,
  required ArtistSongRef songRef,
  List<ArtistSongRef>? queueRefs,
  String? sourceId,
}) async {
  final songId = songRef.songId.trim();
  if (songId.isEmpty) {
    if (context.mounted) {
      showSnackBar(context, 'This track is missing a valid id.');
    }
    return false;
  }

  try {
    final refs = (queueRefs != null && queueRefs.isNotEmpty)
        ? queueRefs.where((item) => item.songId.trim().isNotEmpty).toList()
        : <ArtistSongRef>[songRef];

    final songs = await Future.wait(
      refs.map(
        (item) => ref.read(getSongProvider(item.songId.trim()).future),
      ),
    );
    final index = songs.indexWhere((item) => item.id == songId);

    if (songs.length > 1 && index >= 0) {
      await playSongsFromSource(
        ref: ref,
        songs: songs,
        startIndex: index,
        sourceType: PlaybackSourceType.artist,
        sourceId: sourceId,
      );
    } else {
      final song = songs.isNotEmpty
          ? songs.firstWhere(
              (item) => item.id == songId,
              orElse: () => songs.first,
            )
          : await ref.read(getSongProvider(songId).future);

      await playSingleSongNow(
        ref: ref,
        song: song,
        sourceType: PlaybackSourceType.artist,
        sourceId: sourceId,
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      showSnackBar(
        context,
        'Unable to play "${songRef.songName ?? 'this track'}": ${_errorMessage(error)}',
      );
    }
    return false;
  }
}

Future<void> queueArtistSongRef({
  required WidgetRef ref,
  required ArtistSongRef songRef,
  String? sourceId,
}) async {
  final songId = songRef.songId.trim();
  if (songId.isEmpty) {
    throw Exception('This track is missing a valid id.');
  }

  final song = await ref.read(getSongProvider(songId).future);
  await ref.read(playbackQueueControllerProvider.notifier).addToQueue(
        song,
        sourceType: PlaybackSourceType.artist,
        sourceId: sourceId,
      );
}

String _errorMessage(Object error) {
  final message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message.isEmpty ? 'Unknown error' : message;
}
