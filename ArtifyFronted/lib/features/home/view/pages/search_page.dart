import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:client/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(getAllSongsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050509),
              Color(0xFF140813),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSearchBar(context),
              const SizedBox(height: 16),
              Expanded(
                child: songsAsync.when(
                  data: (songs) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _query.trim().isEmpty
                        ? _buildExploreGrid(context, songs)
                        : _buildResults(context, songs),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: Pallete.gradient2,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER -------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Artify',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find tracks, artists and moods in your library.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH BAR ---------------------------------------------------------------

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
        ),
        cursorColor: Pallete.gradient2,
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search tracks or artists',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFF111018),

          // padding verticale moderno, niente effetto "vecchio material"
          contentPadding: const EdgeInsets.symmetric(vertical: 12),

          // ICONA A SINISTRA
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Pallete.gradient2,
                    Color(0xFF811F1A),
                  ],
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),

          // ICONA CLEAR A DESTRA
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,

          // BORDI MODERNI
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.16),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(
              color: Pallete.gradient2,
              width: 1.4,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  // SEZIONE "EXPLORE" QUANDO NON C'È QUERY -----------------------------------

  Widget _buildExploreGrid(BuildContext context, List<SongModel> songs) {
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
                child: _buildSongTile(context, s),
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

  // RISULTATI DI RICERCA -----------------------------------------------------

  Widget _buildResults(BuildContext context, List<SongModel> allSongs) {
    final query = _query.trim().toLowerCase();

    final filtered = query.isEmpty
        ? allSongs
        : allSongs.where((song) {
            final name = song.song_name.toLowerCase();
            final artist = song.artist.toLowerCase();
            return name.contains(query) || artist.contains(query);
          }).toList();

    if (allSongs.isEmpty) {
      return Center(
        child: Text(
          'No songs available yet.\nTry uploading your first track!',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    if (filtered.isEmpty && query.isNotEmpty) {
      return Center(
        child: Text(
          'No results for "$_query".',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = filtered[index];
        return _buildSongTile(context, song);
      },
    );
  }

  // TILE CANZONE -------------------------------------------------------------

  Widget _buildSongTile(BuildContext context, SongModel song) {
    final title = song.song_name;
    final artist = song.artist;

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
            song.thumbnail_url,
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
            // Qui in futuro: bottom sheet con play / add to playlist ecc.
          },
        ),
        onTap: () {
          // TODO: integra con il tuo player / MusicSlab per fare play di questa canzone
        },
      ),
    );
  }
}
