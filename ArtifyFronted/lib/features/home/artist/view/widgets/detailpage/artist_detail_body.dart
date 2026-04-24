import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/album/view/pages/album_detail_page.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/artist_actions_row.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/artist_song_playback.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/cosmic_header.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/section_card.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/song/view/widgets/queue_swipe_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtistDetailBody extends ConsumerWidget {
  final String artistId;

  const ArtistDetailBody({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(getArtistProvider(artistId));

    return artistAsync.when(
      data: (artist) {
        final visibleSongs = artist.songs.take(8).toList(growable: false);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmicHeader(artist: artist),
              const SizedBox(height: 20),
              ArtistActionsRow(artist: artist),
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
              if (visibleSongs.isEmpty)
                const SectionPlaceholder(
                  title: 'No published tracks',
                  subtitle: 'This artist does not have visible songs yet.',
                  icon: Icons.music_off_rounded,
                )
              else
                SectionCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: visibleSongs.asMap().entries.map((entry) {
                      final isLast = entry.key == visibleSongs.length - 1;

                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                        child: ArtistSongRefRow(
                          index: entry.key + 1,
                          songRef: entry.value,
                          queueRefs: visibleSongs,
                          artistId: artist.id,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 26),
              const SectionTitle('Discography'),
              const SizedBox(height: 12),
              if (artist.albums.isEmpty)
                const SectionPlaceholder(
                  title: 'No releases yet',
                  subtitle: 'Albums will appear here once available.',
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
                      final albumRef = artist.albums[index];
                      return ArtistAlbumRefCard(albumRef: albumRef);
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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

class ArtistSongRefRow extends ConsumerStatefulWidget {
  final int index;
  final ArtistSongRef songRef;
  final List<ArtistSongRef> queueRefs;
  final String artistId;

  const ArtistSongRefRow({
    super.key,
    required this.index,
    required this.songRef,
    required this.queueRefs,
    required this.artistId,
  });

  @override
  ConsumerState<ArtistSongRefRow> createState() => _ArtistSongRefRowState();
}

class _ArtistSongRefRowState extends ConsumerState<ArtistSongRefRow> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await playArtistSongRef(
        context: context,
        ref: ref,
        songRef: widget.songRef,
        queueRefs: widget.queueRefs,
        sourceId: widget.artistId,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQueue() {
    return queueArtistSongRef(
      ref: ref,
      songRef: widget.songRef,
      sourceId: widget.artistId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final songRef = widget.songRef;

    return QueueSwipeWrapper(
      swipeKey: ValueKey(
        'artist-${widget.artistId}-${songRef.songId}-${widget.index}',
      ),
      successMessage: 'Added "${songRef.songName ?? 'this track'}" to queue',
      onQueue: _handleQueue,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: _isLoading ? null : _handleTap,
        leading: SizedBox(
          width: 36,
          child: Center(
            child: Text(
              '${widget.index}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ),
        title: Text(
          songRef.songName ?? 'Unknown track',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          songRef.role,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              )
            : songRef.thumbnailUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      songRef.thumbnailUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.music_note_rounded, color: Colors.white38),
      ),
    );
  }
}

class ArtistAlbumRefCard extends StatelessWidget {
  final ArtistAlbumRef albumRef;

  const ArtistAlbumRefCard({super.key, required this.albumRef});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlbumDetailPage(albumId: albumRef.albumId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  albumRef.coverUrl != null
                      ? Image.network(
                          albumRef.coverUrl!,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 160,
                          height: 160,
                          color: Colors.white.withOpacity(0.06),
                          child: const Icon(
                            Icons.album_outlined,
                            color: Colors.white38,
                            size: 48,
                          ),
                        ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              albumRef.title ?? 'Unknown album',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (albumRef.role != null)
              Text(
                albumRef.role!,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
