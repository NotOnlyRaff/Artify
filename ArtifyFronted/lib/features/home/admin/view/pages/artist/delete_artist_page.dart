import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/UploadArtist/delete_artist_search_bar.dart';
import 'package:client/features/home/admin/view/widgets/UploadArtist/delete_artist_tile.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteArtistPage extends ConsumerStatefulWidget {
  const DeleteArtistPage({super.key});

  @override
  ConsumerState<DeleteArtistPage> createState() => _DeleteArtistPageState();
}

class _DeleteArtistPageState extends ConsumerState<DeleteArtistPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(ArtistModel artist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF050509),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete artist',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        content: Text(
          'Are you sure you want to permanently delete "${artist.displayName ?? artist.name}"?\n\nThis action cannot be undone.',
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(artistViewModelProvider.notifier)
          .deleteArtist(artistId: artist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    _listenToViewModel();

    final isLoading = ref
        .watch(artistViewModelProvider.select((val) => val?.isLoading == true));
    final artistsAsync = ref.watch(getArtistsProvider());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderDescription(),
                  const SizedBox(height: 20),
                  DeleteArtistSearchBar(
                    controller: _searchController,
                    query: _query,
                    onChanged: (val) => setState(() => _query = val),
                    onClear: () => setState(() {
                      _query = '';
                      _searchController.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: artistsAsync.when(
                      data: (artists) => _buildArtistList(artists),
                      loading: () => const Center(child: Loader()),
                      error: (err, _) => Center(
                          child: Text(err.toString(),
                              style: const TextStyle(color: Colors.white))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  void _listenToViewModel() {
    ref.listen<AsyncValue?>(artistViewModelProvider, (prev, next) {
      if (next == null) return;
      next.when(
        data: (data) {
          if (data is bool && data == true)
            showSnackBar(context, 'Artist deleted successfully.');
        },
        error: (error, _) => showSnackBar(context, error.toString()),
        loading: () {},
      );
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context)),
      title: Row(
        children: [
          Text('Artists',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _buildDeleteBadge(),
        ],
      ),
    );
  }

  Widget _buildDeleteBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.red.withOpacity(0.12)),
      child: Text('Delete',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent)),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050509), Color(0xFF140813)],
        ),
      ),
    );
  }

  Widget _buildHeaderDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Remove artists from your Artify catalog.',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text('Search and tap an artist to delete it permanently.',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildArtistList(List<ArtistModel> artists) {
    final q = _query.trim().toLowerCase();
    final filtered = artists.where((a) {
      return a.name.toLowerCase().contains(q) ||
          (a.displayName?.toLowerCase().contains(q) ?? false) ||
          (a.slug?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
          child: Text('No artists found.',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54, fontSize: 14)));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => DeleteArtistTile(
        artist: filtered[index],
        onDelete: () => _confirmDelete(filtered[index]),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
          color: Colors.black.withOpacity(0.35),
          child: const Center(child: Loader())),
    );
  }
}
