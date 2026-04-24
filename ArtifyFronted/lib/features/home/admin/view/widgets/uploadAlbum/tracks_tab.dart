import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/new_track_sheet.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AlbumTrackLocal {
  final String localId;
  final String title;
  final String composer;
  final PickedMedia audio;
  final String? genre;
  final String? mood;
  final String? lyrics;
  final List<String> artistIds;
  final Map<String, SongArtistRole> artistRoles;

  const AlbumTrackLocal({
    required this.localId,
    required this.title,
    required this.composer,
    required this.audio,
    this.genre,
    this.mood,
    this.lyrics,
    this.artistIds = const [],
    this.artistRoles = const {},
  });
}

class AlbumTrackEntry {
  final SongModel? existingSong;
  final AlbumTrackLocal? local;

  const AlbumTrackEntry.existing(this.existingSong) : local = null;
  const AlbumTrackEntry.local(this.local) : existingSong = null;

  bool get isExisting => existingSong != null;
  bool get isLocal => local != null;

  String get displayTitle =>
      existingSong?.songName ?? local?.title ?? 'Untitled track';

  String get displaySubtitle {
    if (existingSong != null) {
      final artistNames = existingSong!.artists
          .map((artist) => artist.artistName)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .join(', ');
      return artistNames.isNotEmpty
          ? artistNames
          : (existingSong!.genre ?? 'Catalog track');
    }

    if (local != null) {
      final details = <String>[];
      if (local!.composer.trim().isNotEmpty) {
        details.add('Composer: ${local!.composer.trim()}');
      }
      if (local!.genre?.trim().isNotEmpty == true) {
        details.add(local!.genre!.trim());
      }
      if (local!.artistIds.isNotEmpty) {
        details.add(
          '${local!.artistIds.length} linked artist${local!.artistIds.length == 1 ? '' : 's'}',
        );
      }
      if (details.isNotEmpty) {
        return details.join(' - ');
      }
    }

    return 'Local draft';
  }

  String? get thumbnailUrl => existingSong?.thumbnailUrl;
}

class TracksTab extends ConsumerWidget {
  final List<AlbumTrackEntry> tracks;
  final ValueChanged<SongModel> onAddExistingTrack;
  final ValueChanged<AlbumTrackLocal> onAddLocalTrack;
  final ValueChanged<AlbumTrackEntry> onRemoveTrack;
  final void Function(int fromIndex, int toIndex) onMoveTrack;
  final TextEditingController trackSearchController;
  final String trackSearchQuery;
  final ValueChanged<String> onTrackQueryChanged;

  const TracksTab({
    super.key,
    required this.tracks,
    required this.onAddExistingTrack,
    required this.onAddLocalTrack,
    required this.onRemoveTrack,
    required this.onMoveTrack,
    required this.trackSearchController,
    required this.trackSearchQuery,
    required this.onTrackQueryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(getAllSongsProvider);
    final trimmedQuery = trackSearchQuery.trim().toLowerCase();
    final enableSearch = trimmedQuery.length >= 2;
    final existingSongIds = tracks
        .where((entry) => entry.existingSong != null)
        .map((entry) => entry.existingSong!.id)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ArtifySectionTitle('Tracklist'),
            const Spacer(),
            Text(
              '${tracks.length} track${tracks.length == 1 ? '' : 's'}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                tracks.isEmpty
                    ? 'Create brand new songs or attach tracks already present in the catalog.'
                    : 'The order here becomes the real album sequence. Local drafts are uploaded as songs before the album is created.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _NewTrackButton(onCreated: onAddLocalTrack),
          ],
        ),
        const SizedBox(height: 18),
        if (tracks.isEmpty)
          _EmptyTrackState()
        else
          Column(
            children: List.generate(
              tracks.length,
              (index) => _TrackRow(
                entry: tracks[index],
                index: index,
                isFirst: index == 0,
                isLast: index == tracks.length - 1,
                onMoveUp:
                    index == 0 ? null : () => onMoveTrack(index, index - 1),
                onMoveDown: index == tracks.length - 1
                    ? null
                    : () => onMoveTrack(index, index + 1),
                onRemove: () => onRemoveTrack(tracks[index]),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'link existing tracks',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Search & add tracks from library',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: trackSearchController,
          onChanged: onTrackQueryChanged,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Search songs by title or artist...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Pallete.gradient2,
                width: 1.2,
              ),
            ),
            suffixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          enableSearch
              ? 'Tracks already linked to this album are automatically hidden.'
              : 'Type at least 2 characters to search tracks.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        if (enableSearch)
          songsAsync.when(
            data: (songs) {
              final filtered = songs
                  .where((song) {
                    final titleMatch =
                        song.songName.toLowerCase().contains(trimmedQuery);
                    final artistMatch = song.artists.any(
                      (artist) => (artist.artistName ?? '')
                          .toLowerCase()
                          .contains(trimmedQuery),
                    );
                    return titleMatch || artistMatch;
                  })
                  .where((song) => !existingSongIds.contains(song.id))
                  .take(8)
                  .toList();

              if (filtered.isEmpty) {
                return Text(
                  'No tracks found for "$trimmedQuery".',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                );
              }

              return Column(
                children: filtered
                    .map(
                      (song) => _LibraryTrackRow(
                        song: song,
                        onAdd: () => onAddExistingTrack(song),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Pallete.gradient2,
                ),
              ),
            ),
            error: (error, _) => Text(
              error.toString(),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  final AlbumTrackEntry entry;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onRemove;

  const _TrackRow({
    required this.entry,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = entry.isLocal;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: isLocal
              ? Pallete.gradient2.withOpacity(0.45)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Text(
            (index + 1).toString().padLeft(2, '0'),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: entry.thumbnailUrl != null
                ? Image.network(
                    entry.thumbnailUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _TrackPlaceholder(isLocal: isLocal),
                  )
                : _TrackPlaceholder(isLocal: isLocal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TrackKindChip(isLocal: isLocal),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.displaySubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded,
                    size: 18, color: Colors.white70),
                onPressed: onMoveUp,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded,
                    size: 18, color: Colors.white70),
                onPressed: onMoveDown,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.white54,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _TrackPlaceholder extends StatelessWidget {
  final bool isLocal;

  const _TrackPlaceholder({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLocal
              ? const [Color(0xFFF97316), Color(0xFF8B5CF6)]
              : const [Color(0xFF811F1A), Color(0xFF4B39EF)],
        ),
      ),
      child: Icon(
        isLocal ? Icons.upload_file_rounded : Icons.music_note_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _TrackKindChip extends StatelessWidget {
  final bool isLocal;

  const _TrackKindChip({required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isLocal
            ? Pallete.gradient2.withOpacity(0.26)
            : Colors.white.withOpacity(0.08),
      ),
      child: Text(
        isLocal ? 'Upload' : 'Library',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LibraryTrackRow extends StatelessWidget {
  final SongModel song;
  final VoidCallback onAdd;

  const _LibraryTrackRow({
    required this.song,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = song.artists
        .map((artist) => artist.artistName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.025),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbnailUrl != null
                  ? Image.network(
                      song.thumbnailUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _TrackPlaceholder(isLocal: false),
                    )
                  : const _TrackPlaceholder(isLocal: false),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.songName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.add_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrackState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.06),
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No tracks added yet',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You can mix fresh uploads and catalog tracks. Local drafts will be uploaded first, then linked into the final album in this exact order.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewTrackButton extends StatelessWidget {
  final ValueChanged<AlbumTrackLocal> onCreated;

  const _NewTrackButton({
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final localTrack = await showModalBottomSheet<AlbumTrackLocal>(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF050509),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: NewTrackSheet(
                onCreated: (track) => Navigator.of(ctx).pop(track),
              ),
            );
          },
        );

        if (localTrack != null) {
          onCreated(localTrack);
        }
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Pallete.gradient2.withOpacity(0.18),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(
        Icons.add_rounded,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        'New track',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
