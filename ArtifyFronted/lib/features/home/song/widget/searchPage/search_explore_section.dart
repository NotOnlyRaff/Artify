import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/widget/searchPage/search_song_tile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchExploreSection extends StatelessWidget {
  final List<SongModel> songs;

  const SearchExploreSection({
    super.key,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final hasSongs = songs.isNotEmpty;

    if (!hasSongs) {
      return Center(
        child: Text(
          'No songs available yet.\nUpload your first track to start exploring.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    final cards = [
      ('For focus', 'Lo-fi, ambient, chill study vibes'),
      ('For the night', 'Slow, dark & immersive tracks'),
      ('Fresh uploads', 'Your latest additions'),
      ('Feel good', 'Warm, bright, uplifting energy'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'Browse by mood',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 110,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final (title, subtitle) = cards[index];
            final gradientColors = _tileGradient(index);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.blur_on_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'All tracks',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...songs.take(10).map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SearchSongTile(
                  song: s,
                  onTap: () {
                    // TODO: integra col player
                  },
                ),
              ),
            ),
      ],
    );
  }

  List<Color> _tileGradient(int index) {
    switch (index % 4) {
      case 0:
        return const [Color(0xFF811F1A), Color(0xFF4B39EF)];
      case 1:
        return const [Color(0xFF0F766E), Color(0xFF22C55E)];
      case 2:
        return const [Color(0xFF7C3AED), Color(0xFFEC4899)];
      default:
        return const [Color(0xFF1D4ED8), Color(0xFF38BDF8)];
    }
  }
}
