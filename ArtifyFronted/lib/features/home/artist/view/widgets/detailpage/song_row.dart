import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/view/widgets/song_playback_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SongRow extends ConsumerWidget {
  final int index;
  final SongModel song;
  final String artistName;

  const SongRow({
    super.key,
    required this.index,
    required this.song,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        song.songName.trim().isNotEmpty ? song.songName : 'Untitled track';

    final durationLabel = song.durationSeconds != null
        ? _formatDuration(song.durationSeconds!)
        : null;

    final genre = song.genre?.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => playSingleSongNow(ref: ref, song: song),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.035),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                index.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                song.thumbnailUrl ??
                    'https://via.placeholder.com/150?text=Track',
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                  if ((genre ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Text(
                        genre!,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white60,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (durationLabel != null)
              Text(
                durationLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 4),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
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
