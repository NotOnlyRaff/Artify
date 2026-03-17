import 'package:client/features/home/song/providers/current_song_notifier.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SongRow extends ConsumerWidget {
  final int index;
  final SongModel song;
  final String artistName;

  const SongRow({
    required this.index,
    required this.song,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = song.songName.isNotEmpty ? song.songName : 'Untitled track';
    final durationLabel = song.durationSeconds != null
        ? _formatDuration(song.durationSeconds!)
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // Corretta invocazione del metodo updateSong
        debugPrint("Song tapped: ${song.songName}");
        ref.read(currentSongNotifierProvider.notifier).updateSong(song);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.02),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                index.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song.thumbnailUrl ??
                    'https://via.placeholder.com/150?text=Track',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4B39EF),
                        Color(0xFF111827),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (durationLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                durationLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: Colors.white54,
              ),
              onPressed: () {
                // TODO: sheet con azioni (add to playlist, fav, share, ecc.)
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}
