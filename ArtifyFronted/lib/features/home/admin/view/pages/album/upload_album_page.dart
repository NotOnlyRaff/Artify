// lib/features/home/admin/view/pages/album/upload_album_page.dart

import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/studio_badge.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/album_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/details_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/tracks_tab.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/studio_background.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/upload_album_form_card.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/upload_album_header.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/upload_album_tab_switcher.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:client/features/home/song/model/song_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:google_fonts/google_fonts.dart';

class UploadAlbumPage extends ConsumerStatefulWidget {
  const UploadAlbumPage({super.key});

  @override
  ConsumerState<UploadAlbumPage> createState() => _UploadAlbumPageState();
}

class _UploadAlbumPageState extends ConsumerState<UploadAlbumPage> {
  int _currentTabIndex = 0;
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  final _titleController = TextEditingController();
  final _labelController = TextEditingController();
  final _genreController = TextEditingController();
  final _artistSearchController = TextEditingController();
  final _trackSearchController = TextEditingController();

  // --- STATE DATA ---
  final List<ArtistModel> _selectedArtists = [];
  final List<AlbumTrackEntry> _tracks = [];
  DateTime? _releaseDate;
  String? _selectedAlbumType;
  PickedMedia? _selectedCover;
  String _artistSearchQuery = '';
  String _trackSearchQuery = '';

  final List<String> _albumTypeValues = const [
    'album',
    'single',
    'ep',
    'compilation'
  ];

  @override
  void dispose() {
    for (var c in [
      _titleController,
      _labelController,
      _genreController,
      _artistSearchController,
      _trackSearchController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ───────────── LOGICA SUBMIT ─────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_titleController.text.trim().isEmpty) {
      setState(() => _currentTabIndex = 0);
      showSnackBar(context, 'Album title is required.');
      return;
    }
    if (_tracks.isEmpty) {
      setState(() => _currentTabIndex = 1);
      showSnackBar(context, 'Add at least one track.');
      return;
    }

    String? coverUrl;
    if (_selectedCover != null) {
      final res = await ref
          .read(albumViewModelProvider.notifier)
          .uploadAlbumCover(cover: _selectedCover!);
      if (!mounted) return;
      if (res is Left) {
        showSnackBar(context, (res as Left).value.message);
        return;
      }
      coverUrl = (res as Right).value;
    }

    final artistIds = _selectedArtists.map((a) => a.id).toList();
    final newSongs = _tracks.where((t) => t.local != null).map((entry) {
      final t = entry.local!;
      return SongModel(
        id: 'local-${t.localId}',
        songName: t.title,
        songUrl: t.songUrl,
        releaseDate: _releaseDate,
        composerName: t.composer,
        genre: t.genre ?? _genreController.text,
        artists: (t.artistIds.isNotEmpty ? t.artistIds : artistIds)
            .map((id) => SongArtistModel(
                artistId: id,
                role: t.artistRoles[id] ?? SongArtistRole.primary))
            .toList(),
      );
    }).toList();

    await ref.read(albumViewModelProvider.notifier).createAlbum(
          title: _titleController.text.trim(),
          releaseDate: _releaseDate,
          label: _labelController.text.trim(),
          albumType: _selectedAlbumType,
          genre: _genreController.text.trim(),
          coverUrl: coverUrl,
          artistIds: artistIds,
          songIds: _tracks
              .where((t) => t.existingSong != null)
              .map((e) => e.existingSong!.id)
              .toList(),
          newSongs: newSongs,
        );
  }

  // ───────────── BUILD ─────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue?>(albumViewModelProvider, (prev, next) {
      next?.whenOrNull(
        data: (_) {
          showSnackBar(context, 'Album created successfully!');
          Navigator.pop(context);
        },
        error: (error, _) => showSnackBar(context, error.toString()),
      );
    });

    final isLoading = ref
        .watch(albumViewModelProvider.select((val) => val?.isLoading == true));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isLoading),
      body: Stack(
        children: [
          const StudioBackground(),
          SafeArea(
            child:
                isLoading ? const Center(child: Loader()) : _buildMainLayout(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isLoading) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context)),
      title: Row(
        children: [
          Text('New album',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const StudioBadge(),
        ],
      ),
      actions: [
        IconButton(
            onPressed: isLoading ? null : _submit,
            icon: const Icon(Icons.check_rounded)),
      ],
    );
  }

  Widget _buildMainLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UploadAlbumHeader(),
                const SizedBox(height: 24),
                UploadAlbumFormCard(
                  tabSwitcher: UploadAlbumTabSwitcher(
                    currentIndex: _currentTabIndex,
                    onTabSelected: (index) =>
                        setState(() => _currentTabIndex = index),
                  ),
                  activeTab: _buildActiveTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_currentTabIndex) {
      case 0:
        return AlbumTab(
          key: const ValueKey('tab-album'),
          selectedCover: _selectedCover,
          onSelectCover: () async {
            final picked = await pickImage();
            if (picked != null) setState(() => _selectedCover = picked);
          },
          titleController: _titleController,
          selectedArtists: _selectedArtists,
          onAddArtist: (a) => setState(() => _selectedArtists.add(a)),
          onRemoveArtist: (a) => setState(() => _selectedArtists.remove(a)),
          artistSearchController: _artistSearchController,
          artistSearchQuery: _artistSearchQuery,
          onArtistQueryChanged: (val) =>
              setState(() => _artistSearchQuery = val),
        );
      case 1:
        return TracksTab(
          key: const ValueKey('tab-tracks'),
          tracks: _tracks,
          onAddExistingTrack: (s) =>
              setState(() => _tracks.add(AlbumTrackEntry.existing(s))),
          onAddLocalTrack: (t) =>
              setState(() => _tracks.add(AlbumTrackEntry.local(t))),
          onRemoveTrack: (e) => setState(() => _tracks.remove(e)),
          onMoveTrack: (f, t) =>
              setState(() => _tracks.insert(t, _tracks.removeAt(f))),
          trackSearchController: _trackSearchController,
          trackSearchQuery: _trackSearchQuery,
          onTrackQueryChanged: (val) => setState(() => _trackSearchQuery = val),
        );
      default:
        return DetailsTab(
          key: const ValueKey('tab-details'),
          releaseDate: _releaseDate,
          onPickReleaseDate: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _releaseDate ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(DateTime.now().year + 5),
            );
            if (picked != null) setState(() => _releaseDate = picked);
          },
          labelController: _labelController,
          genreController: _genreController,
          albumTypeValues: _albumTypeValues,
          selectedAlbumType: _selectedAlbumType,
          onAlbumTypeChanged: (val) => setState(() => _selectedAlbumType = val),
        );
    }
  }
}
