import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/song/model/playback_queue_state.dart';

// SONG
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/song/widget/searchPage/search_explore_section.dart';
import 'package:client/features/home/song/widget/searchPage/search_field.dart';
import 'package:client/features/home/song/widget/searchPage/search_filter_chips.dart';
import 'package:client/features/home/song/widget/searchPage/search_header.dart';
import 'package:client/features/home/song/widget/searchPage/search_results_section.dart';
import 'package:client/features/home/song/view/widgets/song_playback_actions.dart';

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

  /// Filtro categoria: all / songs / artists / albums.
  SearchFilter _filter = SearchFilter.all;

  /// Se l'utente ha espanso la sezione songs via "Show more".
  /// Si resetta quando cambia query o filtro.
  bool _songsExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _songsExpanded = false;
    });
  }

  void _onFilterChanged(SearchFilter filter) {
    setState(() {
      _filter = filter;
      _songsExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.trim().isNotEmpty;

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

    // ⚠️ NIENTE Scaffold, NIENTE gradient locale:
    // lascia che lo sfondo arrivi da HomePage (SpaceBackground)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const SearchHeader(),
        const SizedBox(height: 16),

        // campo di ricerca
        SearchField(
          controller: _searchController,
          query: _query,
          onQueryChanged: _onQueryChanged,
        ),

        // chip di filtro: visibili solo quando c'è una query attiva
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isSearching
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SearchFilterChips(
                    current: _filter,
                    onChanged: _onFilterChanged,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // risultati / explore
        Expanded(
          child: songsAsync.when(
            data: (songs) {
              final List<AlbumModel> albums =
                  albumsAsync.asData?.value ?? <AlbumModel>[];
              final List<ArtistModel> artists =
                  artistsAsync.asData?.value ?? <ArtistModel>[];

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: !isSearching
                    ? SearchExploreSection(
                        songs: songs,
                        onSongTap: (visibleSongs, index) => playSongsFromSource(
                          ref: ref,
                          songs: visibleSongs,
                          startIndex: index,
                          sourceType: PlaybackSourceType.search,
                        ),
                        onSongMoreTap: (visibleSongs, index) =>
                            showSongPlaybackActionsSheet(
                          context: context,
                          ref: ref,
                          song: visibleSongs[index],
                          contextSongs: visibleSongs,
                          startIndex: index,
                          sourceType: PlaybackSourceType.search,
                        ),
                      )
                    : SearchResultsSection(
                        songs: songs,
                        artists: artists,
                        albums: albums,
                        query: _query,
                        filter: _filter,
                        songsCollapsedLimit: 5,
                        songsExpanded: _songsExpanded,
                        onToggleSongsExpanded: () {
                          setState(() {
                            _songsExpanded = !_songsExpanded;
                          });
                        },
                        onSongTap: (visibleSongs, index) => playSongsFromSource(
                          ref: ref,
                          songs: visibleSongs,
                          startIndex: index,
                          sourceType: PlaybackSourceType.search,
                        ),
                        onSongMoreTap: (visibleSongs, index) =>
                            showSongPlaybackActionsSheet(
                          context: context,
                          ref: ref,
                          song: visibleSongs[index],
                          contextSongs: visibleSongs,
                          startIndex: index,
                          sourceType: PlaybackSourceType.search,
                        ),
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
    );
  }
}
