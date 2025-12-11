import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchSongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;

  const SearchSongTile({
    super.key,
    required this.song,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = song.songName;
    final artist = song.artists.isNotEmpty
        ? song.artists.map((a) => a.artist.name).join(', ')
        : 'Unknown Artist';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            song.thumbnailUrl ??
                'https://via.placeholder.com/150?text=No+Image',
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
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
                size: 22,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white60,
            size: 20,
          ),
          onPressed: () {
            // bottom sheet in futuro: play, add to playlist, ecc.
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
