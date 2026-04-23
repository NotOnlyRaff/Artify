import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_audio_picker.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/tracks_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_lyrics_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class NewTrackSheet extends ConsumerStatefulWidget {
  final ValueChanged<AlbumTrackLocal> onCreated;

  const NewTrackSheet({
    super.key,
    required this.onCreated,
  });

  @override
  ConsumerState<NewTrackSheet> createState() => _NewTrackSheetState();
}

class _NewTrackSheetState extends ConsumerState<NewTrackSheet> {
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();

  // Audio
  PickedMedia? _audio;

  // Artists
  final TextEditingController _artistSearchController = TextEditingController();
  String _artistSearchQuery = '';
  final List<ArtistModel> _selectedArtists = [];
  final Map<String, SongArtistRole> _artistRoles = {};

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _genreController.dispose();
    _moodController.dispose();
    _lyricsController.dispose();
    _artistSearchController.dispose();
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

  void _onSelectArtist(ArtistModel artist) {
    setState(() {
      if (_selectedArtists.any((a) => a.id == artist.id)) return;

      _selectedArtists.add(artist);

      // Di default il primo è PRIMARY, gli altri FEATURED
      if (_selectedArtists.length == 1) {
        _artistRoles[artist.id] = SongArtistRole.primary;
      } else {
        _artistRoles[artist.id] = SongArtistRole.featured;
      }
    });
  }

  void _onRemoveArtist(ArtistModel artist) {
    setState(() {
      _selectedArtists.removeWhere((a) => a.id == artist.id);
      _artistRoles.remove(artist.id);
    });
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

    // 1) Prendo il path grezzo (nullable) da PickedMedia
    final String? rawSongPath =
        _audio!.filePath; // o .path / .url a seconda di PickedMedia

    // 2) Validazione: se è null o vuoto, blocco
    if (rawSongPath == null || rawSongPath.isEmpty) {
      showSnackBar(
        context,
        'Audio file path is missing. Please re-select the audio.',
      );
      return;
    }

    // 3) Ora ho una String non-null
    final String songUrl = rawSongPath;

    final artistIds = _selectedArtists.map((a) => a.id).toList();
    final rolesCopy = Map<String, SongArtistRole>.from(_artistRoles);

    final track = AlbumTrackLocal(
      localId: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      composer: composer,
      songUrl: songUrl, // ✅ String, non più String?
      genre: genre.isEmpty ? null : genre,
      mood: mood.isEmpty ? null : mood,
      lyrics: lyrics.isEmpty ? null : lyrics,
      artistIds: artistIds,
      artistRoles: rolesCopy,
    );

    debugPrint('NewTrackSheet -> created local track:');
    debugPrint('  localId: ${track.localId}');
    debugPrint('  title: ${track.title}');
    debugPrint('  composer: ${track.composer}');
    debugPrint('  songUrl: ${track.songUrl}');
    debugPrint('  artistIds: ${track.artistIds}');
    debugPrint('  artistRoles: ${track.artistRoles}');

    widget.onCreated(track);
  }

  @override
  Widget build(BuildContext context) {
    final trimmedArtistQuery = _artistSearchQuery.trim();
    final bool enableArtistSearch = trimmedArtistQuery.length >= 2;

    final artistsAsync = enableArtistSearch
        ? ref.watch(
            getArtistsProvider(
              search: trimmedArtistQuery,
            ),
          )
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
            'Audio and metadata. Artwork will use the album cover.',
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

          // Text metadata
          UploadTextField(
            label: 'Track title',
            placeholder: 'Give this track a name',
            controller: _titleController,
            required: true,
          ),
          const SizedBox(height: 12),

// Track artists & roles
          Text(
            'Track artists & roles',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          if (_selectedArtists.isNotEmpty)
            Column(
              children: _selectedArtists.map((artist) {
                final displayName = artist.displayName?.isNotEmpty == true
                    ? artist.displayName!
                    : artist.name;
                final currentRole = _artistRoles[artist.id] ??
                    (_selectedArtists.first.id == artist.id
                        ? SongArtistRole.primary
                        : SongArtistRole.featured);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.03),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        child: Text(
                          (displayName.isNotEmpty ? displayName[0] : '?')
                              .toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
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
                              'Artist role',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<SongArtistRole>(
                          dropdownColor: const Color(0xFF111018),
                          value: currentRole,
                          items: SongArtistRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.value,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _artistRoles[artist.id] = value;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white54,
                        ),
                        onPressed: () => _onRemoveArtist(artist),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'No artists linked yet. Use the search below to attach them to this track.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

          const SizedBox(height: 14),

          Text(
            'Search & link artists',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: _artistSearchController,
            onChanged: (value) {
              setState(() {
                _artistSearchQuery = value;
              });
            },
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Search artist by name...',
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
            enableArtistSearch
                ? 'Type to search artists in your catalog.'
                : 'Type at least 2 characters to search artists.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),

          if (enableArtistSearch)
            artistsAsync.when(
              data: (artists) {
                final filtered = artists
                    .where(
                      (a) => !_selectedArtists.any((sel) => sel.id == a.id),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return Text(
                    'No artists found for "$trimmedArtistQuery".',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filtered.take(6).map((artist) {
                    final displayName = artist.displayName?.isNotEmpty == true
                        ? artist.displayName!
                        : artist.name;

                    return InkWell(
                      onTap: () => _onSelectArtist(artist),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayName,
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
