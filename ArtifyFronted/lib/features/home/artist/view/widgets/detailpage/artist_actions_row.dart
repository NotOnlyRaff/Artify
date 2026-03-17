import 'dart:math';

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistActionsRow extends ConsumerWidget {
  final ArtistModel artist;

  const ArtistActionsRow({
    super.key,
    required this.artist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSongs = artist.songs.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasSongs
                ? () {
                    ref
                        .read(currentSongNotifierProvider.notifier)
                        .updateSong(artist.songs.first);
                  }
                : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              'Play top track',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.gradient2,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withOpacity(0.08),
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: hasSongs
              ? () {
                  final randomSong =
                      artist.songs[Random().nextInt(artist.songs.length)];
                  ref
                      .read(currentSongNotifierProvider.notifier)
                      .updateSong(randomSong);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.08),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withOpacity(0.05),
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Icon(Icons.shuffle_rounded, size: 20),
        ),
      ],
    );
  }
}
