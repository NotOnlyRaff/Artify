import 'package:client/core/theme/app_pallete.dart';

// SONG
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/song/widget/searchPage/search_explore_section.dart';
import 'package:client/features/home/song/widget/searchPage/search_field.dart';
import 'package:client/features/home/song/widget/searchPage/search_header.dart';
import 'package:client/features/home/song/widget/searchPage/search_results_section.dart';

// ARTIST
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';

// ALBUM
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';

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
    // SONGS (lista completa, filtriamo lato client)
    final songsAsync = ref.watch(getAllSongsProvider);

    // ALBUMS (lista completa, filtriamo lato client)
    final albumsAsync = ref.watch(getAllAlbumsProvider());

    // ARTISTS (usiamo il parametro search lato backend)
    final artistsAsync = ref.watch(
      getArtistsProvider(
        search: _query.trim().isEmpty ? null : _query.trim(),
      ),
    );

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
              const SearchHeader(),
              const SizedBox(height: 16),
              SearchField(
                controller: _searchController,
                query: _query,
                onQueryChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: songsAsync.when(
                  data: (songs) {
                    final List<AlbumModel> albums =
                        albumsAsync.asData?.value ?? <AlbumModel>[];
                    final List<ArtistModel> artists =
                        artistsAsync.asData?.value ?? <ArtistModel>[];

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _query.trim().isEmpty
                          ? SearchExploreSection(
                              songs: songs,
                              // se vuoi in futuro puoi estendere Explore per usare artists/albums
                            )
                          : SearchResultsSection(
                              songs: songs,
                              artists: artists,
                              albums: albums,
                              query: _query,
                            ),
                    );
                  },
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
}
