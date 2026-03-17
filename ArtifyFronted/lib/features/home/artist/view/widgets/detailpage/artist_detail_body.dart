import 'package:client/features/home/artist/view/widgets/detailpage/album_card.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/artist_actions_row.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/cosmic_header.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/section_card.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/song_row.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtistDetailBody extends ConsumerWidget {
  final String artistId;

  const ArtistDetailBody({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(getArtistProvider(artistId));

    return artistAsync.when(
      data: (artist) {
        final displayName = artist.displayName?.trim().isNotEmpty == true
            ? artist.displayName!.trim()
            : artist.name;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmicHeader(artist: artist),
              const SizedBox(height: 20),
              ArtistActionsRow(artist: artist),
              const SizedBox(height: 18),
              const SizedBox(height: 26),
              if ((artist.bio ?? '').trim().isNotEmpty ||
                  (artist.country ?? '').trim().isNotEmpty ||
                  (artist.slug ?? '').trim().isNotEmpty) ...[
                const SectionTitle('Artist identity'),
                const SizedBox(height: 12),
                AboutSection(artist: artist),
                const SizedBox(height: 26),
              ],
              const SectionTitle('Popular tracks'),
              const SizedBox(height: 12),
              if (artist.songs.isEmpty)
                const SectionPlaceholder(
                  title: 'No published tracks',
                  subtitle:
                      'This artist does not have visible songs in the catalog yet.',
                  icon: Icons.music_off_rounded,
                )
              else
                SectionCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: artist.songs.take(8).toList().asMap().entries.map(
                      (entry) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == artist.songs.take(8).length - 1
                                ? 0
                                : 8,
                          ),
                          child: SongRow(
                            index: entry.key + 1,
                            song: entry.value,
                            artistName: displayName,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              const SizedBox(height: 26),
              const SectionTitle('Discography'),
              const SizedBox(height: 12),
              if (artist.albums.isEmpty)
                const SectionPlaceholder(
                  title: 'No releases yet',
                  subtitle:
                      'Albums and official releases will appear here once available.',
                  icon: Icons.album_outlined,
                )
              else
                SizedBox(
                  height: 242,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: artist.albums.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return AlbumCard(album: artist.albums[index]);
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SectionPlaceholder(
            title: 'Unable to load artist',
            subtitle: error.toString(),
            icon: Icons.error_outline_rounded,
          ),
        ),
      ),
    );
  }
}
