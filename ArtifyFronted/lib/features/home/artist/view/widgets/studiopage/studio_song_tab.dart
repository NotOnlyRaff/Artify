import 'package:client/core/utils.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class StudioSongTab extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final String? resolvedArtistId;
  final AsyncValue<ArtistModel>? targetArtistAsync;

  const StudioSongTab({
    super.key,
    required this.currentUser,
    required this.resolvedArtistId,
    required this.targetArtistAsync,
  });

  @override
  ConsumerState<StudioSongTab> createState() => _StudioSongTabState();
}

class _StudioSongTabState extends ConsumerState<StudioSongTab> {
  final _formKey = GlobalKey<FormState>();

  final _songNameController = TextEditingController();
  final _composerController = TextEditingController();
  final _producerController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _artistSearchController = TextEditingController();

  PickedMedia? _selectedAudio;
  PickedMedia? _selectedThumbnail;
  DateTime? _releaseDate;
  bool _submitting = false;
  String _artistSearchQuery = '';

  final List<ArtistModel> _selectedFeaturingArtists = [];

  @override
  void dispose() {
    _songNameController.dispose();
    _composerController.dispose();
    _producerController.dispose();
    _genreController.dispose();
    _moodController.dispose();
    _lyricsController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final picked = await pickAudio();
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedAudio = picked);
    }
  }

  Future<void> _pickThumbnail() async {
    final picked = await pickImage();
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedThumbnail = picked);
    }
  }

  Future<void> _pickReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() => _releaseDate = picked);
    }
  }

  void _addFeaturingArtist(ArtistModel artist) {
    if (_selectedFeaturingArtists.any((a) => a.id == artist.id)) return;

    setState(() {
      _selectedFeaturingArtists.add(artist);
    });
  }

  void _removeFeaturingArtist(ArtistModel artist) {
    setState(() {
      _selectedFeaturingArtists.removeWhere((a) => a.id == artist.id);
    });
  }

  Future<void> _submit(ArtistModel primaryArtist) async {
    if (!_formKey.currentState!.validate()) {
      showSnackBar(context, 'Complete the track form first.');
      return;
    }

    if (_selectedAudio == null) {
      showSnackBar(context, 'Select an audio file.');
      return;
    }

    if (_selectedThumbnail == null) {
      showSnackBar(context, 'Select a thumbnail image.');
      return;
    }

    if (_releaseDate == null) {
      showSnackBar(context, 'Select a release date.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final artistIds = <String>[
        primaryArtist.id,
        ..._selectedFeaturingArtists.map((artist) => artist.id),
      ];

      await ref.read(songViewModelProvider.notifier).uploadSong(
            selectedAudio: _selectedAudio!,
            selectedThumbnail: _selectedThumbnail!,
            songName: _songNameController.text.trim(),
            releaseDate: _releaseDate!,
            composerName: _composerController.text.trim(),
            producerName: _emptyToNull(_producerController.text),
            genre: _emptyToNull(_genreController.text),
            lyrics: _emptyToNull(_lyricsController.text),
            mood: _emptyToNull(_moodController.text),
            artistIds: artistIds,
          );

      final state = ref.read(songViewModelProvider);

      if (state?.hasError == true) {
        showSnackBar(context, state!.error.toString());
        return;
      }

      showSnackBar(context, 'Track uploaded successfully.');
      _clearForm();
      ref.invalidate(getArtistProvider(primaryArtist.id));
      ref.invalidate(getArtistsProvider());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _clearForm() {
    _songNameController.clear();
    _composerController.clear();
    _producerController.clear();
    _genreController.clear();
    _moodController.clear();
    _lyricsController.clear();
    _artistSearchController.clear();

    setState(() {
      _selectedAudio = null;
      _selectedThumbnail = null;
      _releaseDate = null;
      _artistSearchQuery = '';
      _selectedFeaturingArtists.clear();
    });
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final targetArtistAsync = widget.targetArtistAsync;
    final resolvedArtistId = widget.resolvedArtistId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StudioHeroCard(
                icon: Icons.multitrack_audio_rounded,
                title: 'Release a new track',
                subtitle:
                    'Upload audio, artwork and metadata. Primary artist is fixed to the studio target; additional artists can be attached as featuring/collaborators.',
              ),
              const SizedBox(height: 20),
              if (resolvedArtistId == null)
                const StudioSectionCard(
                  child: Text(
                    'Select or load an artist first before uploading a track.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else if (targetArtistAsync == null)
                const SizedBox.shrink()
              else
                targetArtistAsync.when(
                  loading: () => const StudioSectionCard(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => StudioSectionCard(
                    child: Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  data: (primaryArtist) {
                    final artistsSearchAsync = ref.watch(
                      getArtistsProvider(search: _artistSearchQuery),
                    );

                    return Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          StudioSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const StudioSectionTitle('Media'),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StudioMediaPickerCard(
                                        label: 'Audio file',
                                        value: _selectedAudio?.name,
                                        icon: Icons.audio_file_rounded,
                                        buttonText: 'Select audio',
                                        onTap: _pickAudio,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StudioMediaPickerCard(
                                        label: 'Artwork',
                                        value: _selectedThumbnail?.name,
                                        icon: Icons.image_outlined,
                                        buttonText: 'Select image',
                                        onTap: _pickThumbnail,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          StudioSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const StudioSectionTitle('Song metadata'),
                                const SizedBox(height: 14),
                                StudioTextField(
                                  controller: _songNameController,
                                  label: 'Track title',
                                  hint: 'Insert the track name',
                                  icon: Icons.music_note_rounded,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Track title is required'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StudioTextField(
                                        controller: _composerController,
                                        label: 'Composer',
                                        hint: 'Who composed the song?',
                                        icon: Icons.edit_note_rounded,
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? 'Composer is required'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StudioTextField(
                                        controller: _producerController,
                                        label: 'Producer',
                                        hint: 'Optional',
                                        icon: Icons.tune_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StudioTextField(
                                        controller: _genreController,
                                        label: 'Genre',
                                        hint: 'Pop, indie, techno...',
                                        icon: Icons.graphic_eq_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StudioTextField(
                                        controller: _moodController,
                                        label: 'Mood',
                                        hint: 'Dark, chill, energetic...',
                                        icon: Icons.auto_awesome_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                StudioDateField(
                                  label: 'Release date',
                                  value: _releaseDate,
                                  onPick: _pickReleaseDate,
                                ),
                                const SizedBox(height: 14),
                                StudioTextField(
                                  controller: _lyricsController,
                                  label: 'Lyrics / notes',
                                  hint: 'Optional lyrics or notes',
                                  icon: Icons.lyrics_outlined,
                                  minLines: 5,
                                  maxLines: 7,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          StudioSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const StudioSectionTitle('Artist credits'),
                                const SizedBox(height: 10),
                                StudioInfoCallout(
                                  title: 'Primary artist',
                                  body:
                                      '${primaryArtist.displayName ?? primaryArtist.name} is locked as the primary artist for this studio upload. Additional artists below are attached as collaborators/featuring.',
                                ),
                                const SizedBox(height: 16),
                                _SelectedArtistChip(
                                  label:
                                      primaryArtist.displayName ?? primaryArtist.name,
                                  roleLabel: 'PRIMARY',
                                  removable: false,
                                ),
                                const SizedBox(height: 16),
                                StudioTextField(
                                  controller: _artistSearchController,
                                  label: 'Search collaborators',
                                  hint: 'Search artist by name',
                                  icon: Icons.person_search_rounded,
                                  onChanged: (value) {
                                    setState(() => _artistSearchQuery = value);
                                  },
                                ),
                                const SizedBox(height: 14),
                                ..._selectedFeaturingArtists.map(
                                  (artist) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _SelectedArtistChip(
                                      label:
                                          artist.displayName ?? artist.name,
                                      roleLabel: 'FEATURED',
                                      removable: true,
                                      onRemove: () =>
                                          _removeFeaturingArtist(artist),
                                    ),
                                  ),
                                ),
                                if (_selectedFeaturingArtists.isNotEmpty)
                                  const SizedBox(height: 10),
                                artistsSearchAsync.when(
                                  loading: () => const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  error: (error, _) => Text(
                                    error.toString(),
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  data: (artists) {
                                    final candidates = artists.where((artist) {
                                      final isPrimary =
                                          artist.id == primaryArtist.id;
                                      final alreadySelected =
                                          _selectedFeaturingArtists.any(
                                              (a) => a.id == artist.id);
                                      return !isPrimary && !alreadySelected;
                                    }).toList();

                                    if (_artistSearchQuery.trim().isEmpty) {
                                      return Text(
                                        'Search for artists to add a featuring.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white54,
                                          fontSize: 12.5,
                                        ),
                                      );
                                    }

                                    if (candidates.isEmpty) {
                                      return Text(
                                        'No artists found for "${_artistSearchQuery.trim()}".',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white54,
                                          fontSize: 12.5,
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: candidates
                                          .map(
                                            (artist) => ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                backgroundImage: artist.imageUrl !=
                                                            null &&
                                                        artist.imageUrl!.isNotEmpty
                                                    ? NetworkImage(
                                                        artist.imageUrl!)
                                                    : null,
                                                child: artist.imageUrl == null
                                                    ? Text(
                                                        (artist.displayName ??
                                                                artist.name)
                                                            .characters
                                                            .first
                                                            .toUpperCase(),
                                                      )
                                                    : null,
                                              ),
                                              title: Text(
                                                artist.displayName ?? artist.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: artist.slug == null
                                                  ? null
                                                  : Text(
                                                      '@${artist.slug}',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                        color: Colors.white54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                              trailing: OutlinedButton(
                                                onPressed: () =>
                                                    _addFeaturingArtist(artist),
                                                child: const Text('Add'),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          StudioSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const StudioSectionTitle('Publish'),
                                const SizedBox(height: 10),
                                const StudioInfoCallout(
                                  title: 'Featuring model',
                                  body:
                                      'This studio UI mirrors the admin upload flow. Primary artist is sent first, featuring artists follow in the payload order. If you want explicit role persistence, the upload API should also accept artist roles.',
                                ),
                                const SizedBox(height: 18),
                                StudioPrimaryButton(
                                  loading: _submitting,
                                  text: 'Upload track',
                                  icon: Icons.cloud_upload_rounded,
                                  onPressed: () => _submit(primaryArtist),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedArtistChip extends StatelessWidget {
  final String label;
  final String roleLabel;
  final bool removable;
  final VoidCallback? onRemove;

  const _SelectedArtistChip({
    required this.label,
    required this.roleLabel,
    required this.removable,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.08),
            ),
            child: Text(
              roleLabel,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (removable) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}