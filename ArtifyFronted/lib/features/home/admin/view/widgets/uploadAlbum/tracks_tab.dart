import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/new_track_sheet.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// ───────────────────────────── MODEL LOCALI ─────────────────────────────
/// Traccia definita dentro l’UploadAlbum.
/// Non esiste ancora sul backend: verrà creata insieme all’album.
class AlbumTrackLocal {
  final String localId;
  final String title;
  final String composer;
  final String? genre;
  final String? mood;
  final String? lyrics;
  final PickedMedia audioFile;

  /// Artisti (dal DB) collegati a questa traccia.
  final List<String> artistIds;

  /// Ruolo per ogni artista (enum SongArtistRole come in UploadSongPage).
  final Map<String, SongArtistRole> artistRoles;

  AlbumTrackLocal({
    required this.localId,
    required this.title,
    required this.composer,
    required this.audioFile,
    this.genre,
    this.mood,
    this.lyrics,
    this.artistIds = const [],
    this.artistRoles = const {},
  });
}

/// Entry della tracklist dell’album:
/// - o una SongModel esistente (dal catalogo)
/// - o una traccia locale definita in questa pagina
class AlbumTrackEntry {
  final SongModel? existingSong;
  final AlbumTrackLocal? localTrack;

  const AlbumTrackEntry.existing(this.existingSong) : localTrack = null;
  const AlbumTrackEntry.local(this.localTrack) : existingSong = null;

  bool get isLocal => localTrack != null;

  String get displayTitle => existingSong?.songName ?? localTrack!.title;

  String get displaySubtitle {
    final String? genre = existingSong?.genre ?? localTrack?.genre;
    if (genre != null && genre.trim().isNotEmpty) {
      return genre;
    }
    return 'Unreleased track';
  }

  String? get thumbnailUrl => existingSong?.thumbnailUrl;

  /// Id reale solo per le song già esistenti (serve per song_ids)
  String? get persistedSongId => existingSong?.id;
}

/// ───────────────────────────── TRACKS TAB ─────────────────────────────

class TracksTab extends ConsumerWidget {
  /// Tracklist dell’album (mista: song esistenti + locali)
  final List<AlbumTrackEntry> tracks;

  /// Aggiunge una track esistente dal catalogo (Search library)
  final ValueChanged<SongModel> onAddExistingTrack;

  /// Aggiunge una nuova traccia locale creata dal bottom sheet
  final ValueChanged<AlbumTrackLocal> onAddLocalTrack;

  /// Rimuove qualunque entry (song esistente o locale)
  final ValueChanged<AlbumTrackEntry> onRemoveTrack;

  /// Riordina tenendo conto dell’indice nella lista `tracks`
  final void Function(int fromIndex, int toIndex) onMoveTrack;

  // Search
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
    final trimmedQuery = trackSearchQuery.trim().toLowerCase();
    final bool enableSearch = trimmedQuery.length >= 2;

    final songsAsync = ref.watch(getAllSongsProvider);

    final totalTracks = tracks.length;
    final existingSongIds = tracks
        .where((t) => t.existingSong != null)
        .map((t) => t.existingSong!.id)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER ----------------------------------------------------------------
        Row(
          children: [
            const ArtifySectionTitle('Tracklist'),
            const Spacer(),
            Text(
              '$totalTracks track${totalTracks == 1 ? '' : 's'}',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Top row: hint + "New track" button
        Row(
          children: [
            Expanded(
              child: Text(
                totalTracks == 0
                    ? 'Start by creating a new track or linking existing songs from your catalog.'
                    : 'Reorder, remove or add more tracks. The order here defines the album sequence.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _NewTrackButton(
              onCreated: (localTrack) {
                if (localTrack != null) {
                  onAddLocalTrack(localTrack);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 18),

        // TRACKLIST CORRENTE ----------------------------------------------------
        if (totalTracks == 0)
          Text(
            'No tracks added yet. The album will be created without a tracklist unless you link or create songs.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          )
        else
          Column(
            children: List.generate(tracks.length, (index) {
              final entry = tracks[index];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: entry.thumbnailUrl != null
                          ? Image.network(
                              entry.thumbnailUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
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
                                size: 20,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.displaySubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                          onPressed: index == 0
                              ? null
                              : () => onMoveTrack(index, index - 1),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                          onPressed: index == tracks.length - 1
                              ? null
                              : () => onMoveTrack(index, index + 1),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => onRemoveTrack(entry),
                    ),
                  ],
                ),
              );
            }),
          ),

        const SizedBox(height: 24),

        // Divider "or link existing tracks"
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
              'or link existing tracks',
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

        // SEARCH LIBRARY --------------------------------------------------------
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
            hintText: 'Search songs by title...',
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
              ? 'Type to search tracks already in your catalog.'
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
                  .where(
                    (s) => s.songName.toLowerCase().contains(trimmedQuery),
                  )
                  .where(
                    (s) => !existingSongIds.contains(s.id),
                  )
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filtered.map((song) {
                  return InkWell(
                    onTap: () => onAddExistingTrack(song),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white.withOpacity(0.06),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              song.songName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
            error: (e, _) => Text(
              e.toString(),
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

/// ───────────────────────── NEW TRACK BOTTOM SHEET ─────────────────────────

class _NewTrackButton extends StatelessWidget {
  final ValueChanged<AlbumTrackLocal?> onCreated;

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
                onCreated: (t) => Navigator.of(ctx).pop(t),
              ),
            );
          },
        );

        onCreated(localTrack);
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
