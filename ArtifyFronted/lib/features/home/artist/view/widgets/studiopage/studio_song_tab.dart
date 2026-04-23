import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
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
  final _composerSearchController = TextEditingController();
  final _producerController = TextEditingController();
  final _producerSearchController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _artistSearchController = TextEditingController();

  PickedMedia? _selectedAudio;
  PickedMedia? _selectedThumbnail;
  DateTime? _releaseDate;
  bool _submitting = false;

  String _artistSearchQuery = '';
  String _composerSearchQuery = '';
  String _producerSearchQuery = '';

  ArtistModel? _selectedComposerArtist;
  ArtistModel? _selectedProducerArtist;

  final List<ArtistModel> _selectedFeaturingArtists = [];
  final Map<String, SongArtistRole> _artistRoles = {};

  @override
  void dispose() {
    _songNameController.dispose();
    _composerController.dispose();
    _composerSearchController.dispose();
    _producerController.dispose();
    _producerSearchController.dispose();
    _genreController.dispose();
    _moodController.dispose();
    _lyricsController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final picked = await pickAudio();
    if (!mounted || picked == null) return;
    setState(() => _selectedAudio = picked);
  }

  Future<void> _pickThumbnail() async {
    final picked = await pickImage();
    if (!mounted || picked == null) return;
    setState(() => _selectedThumbnail = picked);
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
      _artistRoles[artist.id] = SongArtistRole.featured;
    });
  }

  void _removeFeaturingArtist(ArtistModel artist) {
    setState(() {
      _selectedFeaturingArtists.removeWhere((a) => a.id == artist.id);
      _artistRoles.remove(artist.id);
    });
  }

  void _setFeaturingRole(ArtistModel artist, SongArtistRole role) {
    setState(() {
      _artistRoles[artist.id] = role;
    });
  }

  void _selectComposerArtist(ArtistModel artist) {
    setState(() {
      _selectedComposerArtist = artist;
      _composerController.text = _artistLabel(artist);
      _composerSearchController.clear();
      _composerSearchQuery = '';
    });
  }

  void _clearComposerArtist() {
    setState(() {
      _selectedComposerArtist = null;
    });
  }

  void _selectProducerArtist(ArtistModel artist) {
    setState(() {
      _selectedProducerArtist = artist;
      _producerController.text = _artistLabel(artist);
      _producerSearchController.clear();
      _producerSearchQuery = '';
    });
  }

  void _clearProducerArtist() {
    setState(() {
      _selectedProducerArtist = null;
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

    final composerName = _emptyToNull(_composerController.text);
    if ((_selectedComposerArtist == null) && composerName == null) {
      showSnackBar(context, 'Composer is required.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final artistLinks = <SongArtistModel>[
        SongArtistModel(
          artistId: primaryArtist.id,
          role: SongArtistRole.primary,
        ),
        ..._selectedFeaturingArtists.map(
          (artist) => SongArtistModel(
            artistId: artist.id,
            role: _artistRoles[artist.id] ?? SongArtistRole.featured,
          ),
        ),
      ];

      await ref.read(songViewModelProvider.notifier).uploadSong(
            selectedAudio: _selectedAudio!,
            selectedThumbnail: _selectedThumbnail!,
            songName: _songNameController.text.trim(),
            releaseDate: _releaseDate!,
            composerId: _selectedComposerArtist?.id,
            composerName: composerName,
            producerId: _selectedProducerArtist?.id,
            producerName: _emptyToNull(_producerController.text),
            genre: _emptyToNull(_genreController.text),
            lyrics: _emptyToNull(_lyricsController.text),
            mood: _emptyToNull(_moodController.text),
            artistIds: artistLinks
                .map((link) => link.artistId)
                .whereType<String>()
                .toList(growable: false),
            artistLinks: artistLinks,
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
    _composerSearchController.clear();
    _producerController.clear();
    _producerSearchController.clear();
    _genreController.clear();
    _moodController.clear();
    _lyricsController.clear();
    _artistSearchController.clear();

    setState(() {
      _selectedAudio = null;
      _selectedThumbnail = null;
      _releaseDate = null;
      _artistSearchQuery = '';
      _composerSearchQuery = '';
      _producerSearchQuery = '';
      _selectedComposerArtist = null;
      _selectedProducerArtist = null;
      _selectedFeaturingArtists.clear();
      _artistRoles.clear();
    });
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _artistLabel(ArtistModel artist) {
    return artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;
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
                    'Build a track with stronger credits, cleaner metadata and real catalog links for composer, producer and collaborators.',
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
                    final collaboratorsAsync =
                        _artistSearchQuery.trim().length >= 2
                            ? ref.watch(
                                getArtistsProvider(
                                  search: _artistSearchQuery.trim(),
                                ),
                              )
                            : const AsyncValue<List<ArtistModel>>.data(
                                <ArtistModel>[],
                              );

                    final composerResults =
                        _composerSearchQuery.trim().length >= 2
                            ? ref.watch(
                                getArtistsProvider(
                                  search: _composerSearchQuery.trim(),
                                ),
                              )
                            : const AsyncValue<List<ArtistModel>>.data(
                                <ArtistModel>[],
                              );

                    final producerResults =
                        _producerSearchQuery.trim().length >= 2
                            ? ref.watch(
                                getArtistsProvider(
                                  search: _producerSearchQuery.trim(),
                                ),
                              )
                            : const AsyncValue<List<ArtistModel>>.data(
                                <ArtistModel>[],
                              );

                    final totalArtists = 1 + _selectedFeaturingArtists.length;
                    final linkedCredits = [
                      _selectedComposerArtist,
                      _selectedProducerArtist,
                    ].whereType<ArtistModel>().length;
                    final readyAssets = [
                      _selectedAudio,
                      _selectedThumbnail,
                    ].where((value) => value != null).length;

                    return Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          StudioMetricsStrip(
                            metrics: [
                              StudioMetricData(
                                label: 'Assets ready',
                                value: '$readyAssets/2',
                                icon: Icons.perm_media_rounded,
                                accentColor: const Color(0xFF8B5CF6),
                              ),
                              StudioMetricData(
                                label: 'Artists on track',
                                value: '$totalArtists',
                                icon: Icons.group_rounded,
                                accentColor: Pallete.accentCyan,
                              ),
                              StudioMetricData(
                                label: 'Linked credits',
                                value: '$linkedCredits/2',
                                icon: Icons.account_tree_rounded,
                                accentColor: const Color(0xFFF97316),
                              ),
                              StudioMetricData(
                                label: 'Release date',
                                value: _releaseDate == null ? 'Missing' : 'Set',
                                icon: Icons.event_available_rounded,
                                accentColor: const Color(0xFF22C55E),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          StudioSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const StudioSectionTitle('Media & identity'),
                                const SizedBox(height: 10),
                                const StudioInfoCallout(
                                  title: 'Core track payload',
                                  body:
                                      'Audio, artwork, title and release date are the hard requirements. Genre, mood and lyrics stay optional but help the catalog feel more complete.',
                                ),
                                const SizedBox(height: 16),
                                _StudioAdaptivePair(
                                  left: StudioMediaPickerCard(
                                    label: 'Audio master',
                                    value: _selectedAudio?.name,
                                    icon: Icons.audio_file_rounded,
                                    buttonText: 'Select audio',
                                    onTap: _pickAudio,
                                  ),
                                  right: StudioMediaPickerCard(
                                    label: 'Artwork',
                                    value: _selectedThumbnail?.name,
                                    icon: Icons.image_outlined,
                                    buttonText: 'Select image',
                                    onTap: _pickThumbnail,
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                _StudioAdaptivePair(
                                  left: StudioDateField(
                                    label: 'Release date',
                                    value: _releaseDate,
                                    onPick: _pickReleaseDate,
                                  ),
                                  right: StudioTextField(
                                    controller: _genreController,
                                    label: 'Genre',
                                    hint: 'Pop, indie, techno...',
                                    icon: Icons.graphic_eq_rounded,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                StudioTextField(
                                  controller: _moodController,
                                  label: 'Mood',
                                  hint: 'Dark, chill, energetic...',
                                  icon: Icons.auto_awesome_rounded,
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
                                const StudioSectionTitle('Composer & producer'),
                                const SizedBox(height: 10),
                                const StudioInfoCallout(
                                  title: 'Stronger credit binding',
                                  body:
                                      'Each credit can stay as free text or be linked to a real artist record. When linked, the upload sends both the visible name and the backend id.',
                                ),
                                const SizedBox(height: 16),
                                _StudioAdaptivePair(
                                  left: StudioCreditSelectorCard(
                                    title: 'Composer',
                                    description:
                                        'Required. Link the composer to an internal artist or keep it as an external name.',
                                    nameController: _composerController,
                                    searchController: _composerSearchController,
                                    searchQuery: _composerSearchQuery,
                                    linkedArtist: _selectedComposerArtist,
                                    searchResults: composerResults,
                                    onSearchChanged: (value) {
                                      setState(
                                        () => _composerSearchQuery = value,
                                      );
                                    },
                                    onSelectArtist: _selectComposerArtist,
                                    onClearLinkedArtist: _clearComposerArtist,
                                    icon: Icons.edit_note_rounded,
                                    nameLabel: 'Composer name',
                                    nameHint: 'Who composed the song?',
                                    searchLabel: 'Link composer to artist',
                                    searchHint: 'Search catalog artist',
                                    required: true,
                                  ),
                                  right: StudioCreditSelectorCard(
                                    title: 'Producer',
                                    description:
                                        'Optional. Use it when the producer deserves a proper catalog-level credit.',
                                    nameController: _producerController,
                                    searchController: _producerSearchController,
                                    searchQuery: _producerSearchQuery,
                                    linkedArtist: _selectedProducerArtist,
                                    searchResults: producerResults,
                                    onSearchChanged: (value) {
                                      setState(
                                        () => _producerSearchQuery = value,
                                      );
                                    },
                                    onSelectArtist: _selectProducerArtist,
                                    onClearLinkedArtist: _clearProducerArtist,
                                    icon: Icons.tune_rounded,
                                    nameLabel: 'Producer name',
                                    nameHint: 'Optional producer',
                                    searchLabel: 'Link producer to artist',
                                    searchHint: 'Search catalog artist',
                                  ),
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
                                  title: 'Primary artist locked',
                                  body:
                                      '${_artistLabel(primaryArtist)} is always the primary artist for this studio upload. Add collaborators below and adjust their role when needed.',
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _SelectedArtistChip(
                                      label: _artistLabel(primaryArtist),
                                      role: SongArtistRole.primary,
                                    ),
                                    ..._selectedFeaturingArtists.map(
                                      (artist) => _SelectedArtistChip(
                                        label: _artistLabel(artist),
                                        role: _artistRoles[artist.id] ??
                                            SongArtistRole.featured,
                                        removable: true,
                                        onRemove: () =>
                                            _removeFeaturingArtist(artist),
                                        onRoleChanged: (role) =>
                                            _setFeaturingRole(artist, role),
                                      ),
                                    ),
                                  ],
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
                                const SizedBox(height: 8),
                                Text(
                                  _artistSearchQuery.trim().length >= 2
                                      ? 'Add collaborators from your catalog and decide how they appear on the release.'
                                      : 'Type at least 2 characters to search artists.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                if (_artistSearchQuery.trim().length >= 2) ...[
                                  const SizedBox(height: 10),
                                  collaboratorsAsync.when(
                                    loading: () => const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (error, _) => Text(
                                      error.toString(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    data: (artists) {
                                      final candidates =
                                          artists.where((artist) {
                                        final isPrimary =
                                            artist.id == primaryArtist.id;
                                        final alreadySelected =
                                            _selectedFeaturingArtists.any(
                                          (a) => a.id == artist.id,
                                        );
                                        return !isPrimary && !alreadySelected;
                                      }).toList(growable: false);

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
                                                  backgroundImage:
                                                      artist.imageUrl != null &&
                                                              artist.imageUrl!
                                                                  .isNotEmpty
                                                          ? NetworkImage(
                                                              artist.imageUrl!,
                                                            )
                                                          : null,
                                                  child: artist.imageUrl ==
                                                              null ||
                                                          artist
                                                              .imageUrl!.isEmpty
                                                      ? Text(
                                                          _artistLabel(artist)
                                                              .characters
                                                              .first
                                                              .toUpperCase(),
                                                        )
                                                      : null,
                                                ),
                                                title: Text(
                                                  _artistLabel(artist),
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: artist.slug == null
                                                    ? null
                                                    : Text(
                                                        '@${artist.slug}',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                trailing: OutlinedButton(
                                                  onPressed: () =>
                                                      _addFeaturingArtist(
                                                          artist),
                                                  child: const Text('Add'),
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      );
                                    },
                                  ),
                                ],
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
                                Text(
                                  'Ready to push this release into the catalog?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'The upload will keep ${totalArtists == 1 ? '1 credited artist' : '$totalArtists credited artists'}, ${linkedCredits == 0 ? 'manual-only credits' : '$linkedCredits linked credit${linkedCredits == 1 ? '' : 's'}'} and all the metadata you set above.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
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

class _StudioAdaptivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _StudioAdaptivePair({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _SelectedArtistChip extends StatelessWidget {
  final String label;
  final SongArtistRole role;
  final bool removable;
  final VoidCallback? onRemove;
  final ValueChanged<SongArtistRole>? onRoleChanged;

  const _SelectedArtistChip({
    required this.label,
    required this.role,
    this.removable = false,
    this.onRemove,
    this.onRoleChanged,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          if (onRoleChanged == null)
            _RolePill(label: _roleLabel(role))
          else
            PopupMenuButton<SongArtistRole>(
              color: const Color(0xFF12121A),
              initialValue: role,
              tooltip: 'Change artist role',
              onSelected: onRoleChanged,
              itemBuilder: (context) {
                return const [
                  SongArtistRole.featured,
                  SongArtistRole.producer,
                  SongArtistRole.mixer,
                  SongArtistRole.writer,
                ]
                    .map(
                      (value) => PopupMenuItem<SongArtistRole>(
                        value: value,
                        child: Text(
                          _roleLabel(value),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(growable: false);
              },
              child: _RolePill(
                label: _roleLabel(role),
                trailing: const Icon(
                  Icons.unfold_more_rounded,
                  size: 14,
                  color: Colors.white70,
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

  static String _roleLabel(SongArtistRole role) {
    switch (role) {
      case SongArtistRole.primary:
        return 'PRIMARY';
      case SongArtistRole.featured:
        return 'FEATURED';
      case SongArtistRole.producer:
        return 'PRODUCER';
      case SongArtistRole.mixer:
        return 'MIXER';
      case SongArtistRole.writer:
        return 'WRITER';
    }
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _RolePill({
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Pallete.accentCyan.withOpacity(0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
