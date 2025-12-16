import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart'; // PickedMedia, pickAudio, showSnackBar
import 'package:client/core/widgets/artify_audio_picker.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_lyrics_field.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// ───────────────────────────── MODEL LOCALI ─────────────────────────────

/// Bozza di traccia creata *solo* dentro l'UploadAlbum.
/// Non esiste ancora sul backend.
class AlbumTrackDraft {
  final String localId;
  final String title;
  final String composer;
  final String? genre;
  final String? mood;
  final String? lyrics;
  final PickedMedia audioFile;

  const AlbumTrackDraft({
    required this.localId,
    required this.title,
    required this.composer,
    required this.audioFile,
    this.genre,
    this.mood,
    this.lyrics,
  });
}

/// Entry generica della tracklist dell’album:
/// - o una SongModel esistente (dal catalogo)
/// - o una bozza locale (AlbumTrackDraft)
class AlbumTrackEntry {
  final SongModel? existingSong;
  final AlbumTrackDraft? draft;

  const AlbumTrackEntry.existing(this.existingSong) : draft = null;
  const AlbumTrackEntry.draft(this.draft) : existingSong = null;

  bool get isDraft => draft != null;

  String get displayTitle =>
      existingSong?.songName ?? draft!.title;

  String get displaySubtitle {
    if (existingSong != null) {
      return existingSong!.genre ?? 'Unknown genre';
    }
    if (draft != null && draft!.genre != null && draft!.genre!.trim().isNotEmpty) {
      return draft!.genre!;
    }
    return 'Draft track';
  }

  String? get thumbnailUrl => existingSong?.thumbnailUrl;

  /// Id “reale” solo per le song esistenti (serve per song_ids)
  String? get persistedSongId => existingSong?.id;
}

/// ───────────────────────────── TRACKS TAB ─────────────────────────────

class TracksTab extends ConsumerWidget {
  /// Tracklist dell’album (mista: song esistenti + draft locali)
  final List<AlbumTrackEntry> tracks;

  /// Aggiunge una track esistente dal catalogo (Search library)
  final ValueChanged<SongModel> onAddExistingTrack;

  /// Aggiunge una nuova bozza creata dal bottom sheet
  final ValueChanged<AlbumTrackDraft> onAddDraftTrack;

  /// Rimuove qualunque entry (song esistente o draft)
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
    required this.onAddDraftTrack,
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
        .where((t) => !t.isDraft && t.existingSong != null)
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
                    ? 'Start by creating a brand new song or linking existing tracks.'
                    : 'Reorder, remove or add more tracks. The order here defines the album sequence.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _NewTrackButton(
              onCreated: (draft) {
                if (draft != null) {
                  onAddDraftTrack(draft);
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
              final isDraft = entry.isDraft;

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
                    color: isDraft
                        ? Pallete.gradient2.withOpacity(0.5)
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
                              if (isDraft) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Pallete.gradient2.withOpacity(0.3),
                                  ),
                                  child: Text(
                                    'Draft',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                    (s) =>
                        s.songName.toLowerCase().contains(trimmedQuery),
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
  final ValueChanged<AlbumTrackDraft?> onCreated;

  const _NewTrackButton({
    required this.onCreated,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final draft = await showModalBottomSheet<AlbumTrackDraft>(
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
              child: _NewTrackSheet(
                onCreated: (d) => Navigator.of(ctx).pop(d),
              ),
            );
          },
        );

        onCreated(draft);
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

class _NewTrackSheet extends StatefulWidget {
  final ValueChanged<AlbumTrackDraft> onCreated;

  const _NewTrackSheet({
    required this.onCreated,
  });

  @override
  State<_NewTrackSheet> createState() => _NewTrackSheetState();
}

class _NewTrackSheetState extends State<_NewTrackSheet> {
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();

  PickedMedia? _audio;

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _genreController.dispose();
    _moodController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final picked = await pickAudio();
    if (picked != null) {
      setState(() {
        _audio = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final composer = _composerController.text.trim();
    final genre = _genreController.text.trim();
    final mood = _moodController.text.trim();
    final lyrics = _lyricsController.text.trim();

    if (title.isEmpty || composer.isEmpty || _audio == null) {
      showSnackBar(
        context,
        'Please fill track title, composer and select audio.',
      );
      return;
    }

    final draft = AlbumTrackDraft(
      localId: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      composer: composer,
      audioFile: _audio!,
      genre: genre.isEmpty ? null : genre,
      mood: mood.isEmpty ? null : mood,
      lyrics: lyrics.isEmpty ? null : lyrics,
    );

    widget.onCreated(draft);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Text(
            'New album track',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Audio and basic metadata. Artwork will use the album cover.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),

          // Audio
          ArtifyAudioPicker(
            selectedAudio: _audio,
            onTapSelectAudio: _pickAudio,
          ),
          const SizedBox(height: 18),

          // Text
          UploadTextField(
            label: 'Track title',
            placeholder: 'Give this track a name',
            controller: _titleController,
            required: true,
          ),
          const SizedBox(height: 12),
          UploadTextField(
            label: 'Composer(s)',
            placeholder: 'Who wrote this track?',
            controller: _composerController,
            required: true,
          ),
          const SizedBox(height: 12),
          UploadTextField(
            label: 'Genre',
            placeholder: 'Pop, Electronic, Indie...',
            controller: _genreController,
          ),
          const SizedBox(height: 12),
          UploadTextField(
            label: 'Mood',
            placeholder: 'Chill, Dark, Upbeat...',
            controller: _moodController,
          ),
          const SizedBox(height: 12),
          UploadLyricsField(
            controller: _lyricsController,
          ),

          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.gradient2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'Add to album',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
