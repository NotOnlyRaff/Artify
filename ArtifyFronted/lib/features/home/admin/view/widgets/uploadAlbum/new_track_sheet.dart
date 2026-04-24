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
  final _artistSearchController = TextEditingController();

  PickedMedia? _audio;
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
    if (picked != null && mounted) {
      setState(() => _audio = picked);
    }
  }

  void _selectArtist(ArtistModel artist) {
    if (_selectedArtists.any((item) => item.id == artist.id)) return;

    setState(() {
      _selectedArtists.add(artist);
      _artistRoles[artist.id] = _selectedArtists.length == 1
          ? SongArtistRole.primary
          : SongArtistRole.featured;
    });
  }

  void _removeArtist(ArtistModel artist) {
    setState(() {
      _selectedArtists.removeWhere((item) => item.id == artist.id);
      _artistRoles.remove(artist.id);

      if (_selectedArtists.isNotEmpty &&
          !_artistRoles.containsKey(_selectedArtists.first.id)) {
        _artistRoles[_selectedArtists.first.id] = SongArtistRole.primary;
      }
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

    widget.onCreated(
      AlbumTrackLocal(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        composer: composer,
        audio: _audio!,
        genre: genre.isEmpty ? null : genre,
        mood: mood.isEmpty ? null : mood,
        lyrics: lyrics.isEmpty ? null : lyrics,
        artistIds: _selectedArtists.map((artist) => artist.id).toList(),
        artistRoles: Map<String, SongArtistRole>.from(_artistRoles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = _artistSearchQuery.trim();
    final enableSearch = trimmedQuery.length >= 2;
    final artistsAsync = enableSearch
        ? ref.watch(getArtistsProvider(search: trimmedQuery))
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

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
            'This draft will be uploaded as a real song right before the album is created.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ArtifyAudioPicker(
            selectedAudio: _audio,
            onTapSelectAudio: _pickAudio,
          ),
          const SizedBox(height: 18),
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
          Row(
            children: [
              Expanded(
                child: UploadTextField(
                  label: 'Genre',
                  placeholder: 'Pop, Electronic, Indie...',
                  controller: _genreController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UploadTextField(
                  label: 'Mood',
                  placeholder: 'Chill, Dark, Upbeat...',
                  controller: _moodController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          UploadLyricsField(controller: _lyricsController),
          const SizedBox(height: 20),
          Text(
            'Track artists & roles',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedArtists.isEmpty)
            Text(
              'Optional: link artists now if this track needs explicit credits different from the album defaults.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 11,
                height: 1.4,
              ),
            )
          else
            Column(
              children: _selectedArtists.map((artist) {
                final label = artist.displayName?.isNotEmpty == true
                    ? artist.displayName!
                    : artist.name;
                final role = _artistRoles[artist.id] ??
                    (_selectedArtists.first.id == artist.id
                        ? SongArtistRole.primary
                        : SongArtistRole.featured);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.03),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        child: Text(
                          label.isNotEmpty ? label[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
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
                      DropdownButtonHideUnderline(
                        child: DropdownButton<SongArtistRole>(
                          dropdownColor: const Color(0xFF111018),
                          value: role,
                          items: SongArtistRole.values.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.value,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _artistRoles[artist.id] = value);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white54,
                        ),
                        onPressed: () => _removeArtist(artist),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _artistSearchController,
            onChanged: (value) => setState(() => _artistSearchQuery = value),
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
                borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
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
                ? 'Search artists in your catalog and attach them to this draft.'
                : 'Type at least 2 characters to search artists.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (enableSearch)
            artistsAsync.when(
              data: (artists) {
                final filtered = artists
                    .where(
                      (artist) =>
                          !_selectedArtists.any((item) => item.id == artist.id),
                    )
                    .take(6)
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return Text(
                    'No artists found for "$trimmedQuery".',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  );
                }

                return Column(
                  children: filtered.map((artist) {
                    final label = artist.displayName?.isNotEmpty == true
                        ? artist.displayName!
                        : artist.name;

                    return InkWell(
                      onTap: () => _selectArtist(artist),
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
                                label,
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
                  }).toList(growable: false),
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
          const SizedBox(height: 20),
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
