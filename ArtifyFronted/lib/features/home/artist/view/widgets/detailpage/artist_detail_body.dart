import 'package:client/features/home/artist/view/widgets/detailpage/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/cosmic_header.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/artist_actions_row.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/cosmic_stats_row.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/song_row.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/album_card.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';

class ArtistDetailBody extends ConsumerWidget {
  final String artistId;

  const ArtistDetailBody({
    required this.artistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Otteniamo i dettagli dell'artista dal provider
    final artistAsync = ref.watch(getArtistProvider(artistId));

    return artistAsync.when(
      data: (artist) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cosmico Header
              CosmicHeader(
                  displayName: artist.displayName ?? 'Unknown',
                  imageUrl: artist.imageUrl),
              const SizedBox(height: 26),

              // Azioni dell'artista (Play, Shuffle)
              ArtistActionsRow(artist: artist),
              const SizedBox(height: 24),

              // Statistiche Cosmica
              CosmicStatsRow(
                trackCount: artist.songs.length,
                activeSince: artist.displayName, // Usa l'anno corretto
                origin: artist.country,
              ),
              const SizedBox(height: 28),

              // Top Songs
              if (artist.songs.isNotEmpty) ...[
                const SectionTitle('Top songs'),
                const SizedBox(height: 10),
                ...artist.songs.take(8).toList().asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SongRow(
                          index: entry.key + 1,
                          song: entry.value,
                          artistName: artist.displayName ?? artist.name,
                        ),
                      ),
                    ),
                const SizedBox(height: 28),
              ],

              // Discografia (Album)
              if (artist.albums.isNotEmpty) ...[
                const SectionTitle('Discography in orbit'),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: artist.albums.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final album = artist.albums[index];
                      return AlbumCard(album: album);
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Bio dell'artista
              if ((artist.bio ?? '').trim().isNotEmpty) ...[
                const SectionTitle('About this entity'),
                const SizedBox(height: 10),
                AboutSection(artist: artist),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }
}
