import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistSongEditPage extends ConsumerStatefulWidget {
  final ArtistModel studioArtist;
  final String songId;

  const ArtistSongEditPage({
    super.key,
    required this.studioArtist,
    required this.songId,
  });

  @override
  ConsumerState<ArtistSongEditPage> createState() => _ArtistSongEditPageState();
}

class _ArtistSongEditPageState extends ConsumerState<ArtistSongEditPage> {
  final _songNameController = TextEditingController();
  final _composerController = TextEditingController();
  final _composerSearchController = TextEditingController();
  final _producerController = TextEditingController();
  final _producerSearchController = TextEditingController();
  final _genreController = TextEditingController();
  final _moodController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _artistSearchController = TextEditingController();

  DateTime? _releaseDate;
  bool _seeded = false;
  bool _saving = false;

  String _artistSearchQuery = '';
  String _composerSearchQuery = '';
  String _producerSearchQuery = '';

  ArtistModel? _selectedComposerArtist;
  ArtistModel? _selectedProducerArtist;

  final List<ArtistModel> _selectedArtists = [];
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

  void _seedSong(SongModel song) {
    if (_seeded) return;

    _songNameController.text = song.songName;
    _genreController.text = song.genre ?? '';
    _moodController.text = song.mood ?? '';
    _lyricsController.text = song.lyrics ?? '';
    _releaseDate = song.releaseDate;

    final creditedArtists = <ArtistModel>[];
    for (final link in song.artists) {
      final artistId = link.artistId;
      if (artistId == null || artistId.isEmpty) continue;
      if (creditedArtists.any((artist) => artist.id == artistId)) continue;

      creditedArtists.add(
        ArtistModel(
          id: artistId,
          name: link.artistName ?? 'Unknown artist',
          displayName: link.artistName,
          imageUrl: link.artistImageUrl,
        ),
      );
      _artistRoles[artistId] = link.role;
    }

    if (!creditedArtists.any((artist) => artist.id == widget.studioArtist.id)) {
      creditedArtists.insert(0, widget.studioArtist);
    }

    _selectedArtists
      ..clear()
      ..addAll(creditedArtists);
    _artistRoles[widget.studioArtist.id] = SongArtistRole.primary;

    _selectedComposerArtist = _findArtistById(song.composerId);
    _selectedProducerArtist = _findArtistById(song.producerId);

    _composerController.text = _selectedComposerArtist != null
        ? _artistLabel(_selectedComposerArtist!)
        : (song.composerName ?? '');
    _producerController.text = _selectedProducerArtist != null
        ? _artistLabel(_selectedProducerArtist!)
        : (song.producerName ?? '');

    _seeded = true;
  }

  ArtistModel? _findArtistById(String? artistId) {
    if (artistId == null || artistId.isEmpty) return null;
    for (final artist in _selectedArtists) {
      if (artist.id == artistId) return artist;
    }
    if (widget.studioArtist.id == artistId) return widget.studioArtist;
    return null;
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
    setState(() => _selectedComposerArtist = null);
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
    setState(() => _selectedProducerArtist = null);
  }

  void _addArtist(ArtistModel artist) {
    if (_selectedArtists.any((item) => item.id == artist.id)) return;

    setState(() {
      _selectedArtists.add(artist);
      _artistRoles[artist.id] = SongArtistRole.featured;
    });
  }

  void _removeArtist(ArtistModel artist) {
    if (artist.id == widget.studioArtist.id) return;

    setState(() {
      _selectedArtists.removeWhere((item) => item.id == artist.id);
      _artistRoles.remove(artist.id);
    });
  }

  void _setArtistRole(ArtistModel artist, SongArtistRole role) {
    if (artist.id == widget.studioArtist.id) return;
    setState(() => _artistRoles[artist.id] = role);
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

  String _artistLabel(ArtistModel artist) {
    return artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (_songNameController.text.trim().isEmpty) {
      showSnackBar(context, 'Track title is required.');
      return;
    }
    if (_releaseDate == null) {
      showSnackBar(context, 'Release date is required.');
      return;
    }

    final composerName = _emptyToNull(_composerController.text);
    if (_selectedComposerArtist == null && composerName == null) {
      showSnackBar(context, 'Composer is required.');
      return;
    }

    setState(() => _saving = true);

    try {
      final orderedArtists = <ArtistModel>[
        widget.studioArtist,
        ..._selectedArtists
            .where((artist) => artist.id != widget.studioArtist.id),
      ];

      final artistLinks = orderedArtists
          .map(
            (artist) => SongArtistModel(
              artistId: artist.id,
              role: artist.id == widget.studioArtist.id
                  ? SongArtistRole.primary
                  : (_artistRoles[artist.id] ?? SongArtistRole.featured),
            ),
          )
          .toList(growable: false);

      await ref.read(songViewModelProvider.notifier).updateSong(
            songId: widget.songId,
            songName: _songNameController.text.trim(),
            releaseDate: _releaseDate!,
            composerId: _selectedComposerArtist?.id,
            composerName: composerName,
            producerId: _selectedProducerArtist?.id,
            producerName: _emptyToNull(_producerController.text),
            genre: _emptyToNull(_genreController.text),
            lyrics: _emptyToNull(_lyricsController.text),
            mood: _emptyToNull(_moodController.text),
            artistLinks: artistLinks,
          );

      final state = ref.read(songViewModelProvider);
      if (state?.hasError == true) {
        if (!mounted) return;
        showSnackBar(context, state!.error.toString());
        return;
      }

      ref.invalidate(getArtistProvider(widget.studioArtist.id));
      ref.invalidate(getSongProvider(widget.songId));
      ref.invalidate(getAllSongsProvider);
      ref.invalidate(getFavSongsProvider);

      if (!mounted) return;
      showSnackBar(context, 'Track updated successfully.');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(getSongProvider(widget.songId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Edit Track',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050509),
              Color(0xFF140813),
            ],
          ),
        ),
        child: songAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          data: (song) {
            _seedSong(song);

            final collaboratorsAsync = _artistSearchQuery.trim().length >= 2
                ? ref.watch(
                    getArtistsProvider(search: _artistSearchQuery.trim()))
                : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

            final composerResults = _composerSearchQuery.trim().length >= 2
                ? ref.watch(
                    getArtistsProvider(search: _composerSearchQuery.trim()))
                : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

            final producerResults = _producerSearchQuery.trim().length >= 2
                ? ref.watch(
                    getArtistsProvider(search: _producerSearchQuery.trim()))
                : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

            final linkedCredits = [
              _selectedComposerArtist,
              _selectedProducerArtist,
            ].whereType<ArtistModel>().length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StudioHeroCard(
                        icon: Icons.edit_note_rounded,
                        title: 'Refine track metadata',
                        subtitle:
                            'Update title, credits and artist links without rebuilding the release from scratch.',
                      ),
                      const SizedBox(height: 20),
                      StudioMetricsStrip(
                        metrics: [
                          StudioMetricData(
                            label: 'Current artists',
                            value: '${_selectedArtists.length}',
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
                            label: 'Album links',
                            value: '${song.albums.length}',
                            icon: Icons.album_rounded,
                            accentColor: const Color(0xFF8B5CF6),
                          ),
                          StudioMetricData(
                            label: 'Artwork',
                            value: song.thumbnailUrl?.isNotEmpty == true
                                ? 'Live'
                                : 'Missing',
                            icon: Icons.image_rounded,
                            accentColor: const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StudioSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StudioSectionTitle('Track identity'),
                            const SizedBox(height: 10),
                            const StudioInfoCallout(
                              title: 'Metadata-only editor',
                              body:
                                  'Audio master and artwork stay untouched here. This screen focuses on credits, release metadata and catalog consistency.',
                            ),
                            const SizedBox(height: 16),
                            if (song.thumbnailUrl?.isNotEmpty == true)
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  image: DecorationImage(
                                    image: NetworkImage(song.thumbnailUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (song.thumbnailUrl?.isNotEmpty == true)
                              const SizedBox(height: 16),
                            StudioTextField(
                              controller: _songNameController,
                              label: 'Track title',
                              hint: 'Insert the track name',
                              icon: Icons.music_note_rounded,
                            ),
                            const SizedBox(height: 14),
                            _StudioEditAdaptivePair(
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
                              title: 'Keep credits structured',
                              body:
                                  'A credit can stay manual or be linked to a real artist record. This keeps the UI readable while matching the backend song model.',
                            ),
                            const SizedBox(height: 16),
                            _StudioEditAdaptivePair(
                              left: StudioCreditSelectorCard(
                                title: 'Composer',
                                description:
                                    'Required. Link it to an internal artist or keep it as an external name.',
                                nameController: _composerController,
                                searchController: _composerSearchController,
                                searchQuery: _composerSearchQuery,
                                linkedArtist: _selectedComposerArtist,
                                searchResults: composerResults,
                                onSearchChanged: (value) {
                                  setState(() => _composerSearchQuery = value);
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
                                    'Optional. Useful when production credit should stay attached to a catalog artist.',
                                nameController: _producerController,
                                searchController: _producerSearchController,
                                searchQuery: _producerSearchQuery,
                                linkedArtist: _selectedProducerArtist,
                                searchResults: producerResults,
                                onSearchChanged: (value) {
                                  setState(() => _producerSearchQuery = value);
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
                                  '${_artistLabel(widget.studioArtist)} remains the main credited artist inside Artist Studio. Add or remove collaborators below when needed.',
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedArtists
                                  .map(
                                    (artist) => _SongEditorArtistChip(
                                      label: _artistLabel(artist),
                                      role: artist.id == widget.studioArtist.id
                                          ? SongArtistRole.primary
                                          : (_artistRoles[artist.id] ??
                                              SongArtistRole.featured),
                                      removable:
                                          artist.id != widget.studioArtist.id,
                                      onRemove:
                                          artist.id == widget.studioArtist.id
                                              ? null
                                              : () => _removeArtist(artist),
                                      onRoleChanged:
                                          artist.id == widget.studioArtist.id
                                              ? null
                                              : (role) =>
                                                  _setArtistRole(artist, role),
                                    ),
                                  )
                                  .toList(growable: false),
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
                            const SizedBox(height: 6),
                            Text(
                              _artistSearchQuery.trim().length >= 2
                                  ? 'Add collaborators from the catalog and control their release role.'
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
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                error: (error, _) => Text(
                                  error.toString(),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                data: (artists) {
                                  final candidates = artists.where((artist) {
                                    return !_selectedArtists
                                        .any((item) => item.id == artist.id);
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
                                                          artist.imageUrl!)
                                                      : null,
                                              child: artist.imageUrl == null ||
                                                      artist.imageUrl!.isEmpty
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
                                              style:
                                                  GoogleFonts.plusJakartaSans(
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
                                                  _addArtist(artist),
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
                      StudioPrimaryButton(
                        loading: _saving,
                        text: 'Save track changes',
                        icon: Icons.save_rounded,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StudioEditAdaptivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _StudioEditAdaptivePair({
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

class _SongEditorArtistChip extends StatelessWidget {
  final String label;
  final SongArtistRole role;
  final bool removable;
  final VoidCallback? onRemove;
  final ValueChanged<SongArtistRole>? onRoleChanged;

  const _SongEditorArtistChip({
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
            _SongEditorRolePill(label: _roleLabel(role))
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
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(growable: false);
              },
              child: _SongEditorRolePill(
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

class _SongEditorRolePill extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SongEditorRolePill({
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
