// lib/features/home/song/view/widgets/latest_today_section.dart

import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/song/widget/SongPage/song_artist_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class LatestTodaySection extends ConsumerWidget {
  const LatestTodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 260,
      child: ref.watch(getAllSongsProvider).when(
            data: (songs) => _buildList(context, ref, songs),
            error: (error, st) => Center(
              child: Text(
                error.toString(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
            loading: () => const Center(child: Loader()),
          ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<SongModel> songs,
  ) {
    if (songs.isEmpty) {
      return Center(
        child: Text(
          'No songs yet.\nUpload your first track on Artify!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: songs.length,
      padding: const EdgeInsets.only(left: 16, right: 16),
      itemBuilder: (context, index) {
        final song = songs[index];

        return GestureDetector(
          onTap: () {
            ref.read(currentSongNotifierProvider.notifier).updateSong(song);
          },
          child: Padding(
            padding: EdgeInsets.only(right: index == songs.length - 1 ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: song.thumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(song.thumbnailUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: song.thumbnailUrl == null ? Colors.white10 : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: song.thumbnailUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            color: Colors.white54,
                            size: 40,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 180,
                  child: Text(
                    song.songName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    song.formattedArtists,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Pallete.subtitleText,
                      fontSize: 12,
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
}
