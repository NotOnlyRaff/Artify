import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/song/view/widgets/song_playback_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(getFavSongsProvider).when(
          data: (data) {
            if (data.isEmpty) {
              return const Center(
                child: Text(
                  'No favorite songs yet.\nStart adding tracks to your library.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final song = data[index];

                return ListTile(
                  onTap: () => playSongsFromSource(
                    ref: ref,
                    songs: data,
                    startIndex: index,
                    sourceType: PlaybackSourceType.library,
                  ),
                  onLongPress: () => showSongPlaybackActionsSheet(
                    context: context,
                    ref: ref,
                    song: song,
                    contextSongs: data,
                    startIndex: index,
                    sourceType: PlaybackSourceType.library,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Pallete.backgroundColor,
                    backgroundImage: song.thumbnailUrl != null
                        ? NetworkImage(song.thumbnailUrl!)
                        : null,
                    child: song.thumbnailUrl == null
                        ? const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                  title: Text(
                    song.songName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    song.artists.isNotEmpty
                        ? song.artists.map((a) => a.artistName).join(', ')
                        : 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            );
          },
          error: (error, st) {
            return Center(
              child: Text(
                error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          },
          loading: () => const Loader(),
        );
  }
}
