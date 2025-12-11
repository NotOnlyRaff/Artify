// lib/features/admin/view/pages/delete_artist_page.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
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
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF050509),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete artist',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${artist.displayName ?? artist.name}" from your catalog?\n\nThis action cannot be undone.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref
        .read(artistViewModelProvider.notifier)
        .deleteArtist(artistId: artist.id);
  }

  @override
  Widget build(BuildContext context) {
    // Listen stato delete/create/update
    ref.listen<AsyncValue?>(artistViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (data) {
          if (data is bool && data == true) {
            showSnackBar(context, 'Artist deleted successfully.');
          }
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {},
      );
    });

    final isLoading = ref
        .watch(artistViewModelProvider.select((val) => val?.isLoading == true));

    final artistsAsync = ref.watch(
      getArtistsProvider(
        search: _query.trim().isEmpty ? null : _query.trim(),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Artists',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.red.withOpacity(0.12),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
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
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remove artists from your Artify catalog.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search and tap an artist to delete it permanently.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: artistsAsync.when(
                      data: (artists) {
                        if (artists.isEmpty) {
                          return Center(
                            child: Text(
                              'No artists found.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: artists.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final artist = artists[index];
                            return _buildArtistTile(context, artist);
                          },
                        );
                      },
                      loading: () => const Center(child: Loader()),
                      error: (error, stack) => Center(
                        child: Text(
                          error.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay loading per delete
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: Loader(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // SEARCH BAR ---------------------------------------------------------------

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
      ),
      cursorColor: Pallete.gradient2,
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search artists by name or slug',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFF111018),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Pallete.gradient2,
                  Color(0xFF811F1A),
                ],
              ),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _query = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.16),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(
            color: Pallete.gradient2,
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  // TILE ARTISTA -------------------------------------------------------------

  Widget _buildArtistTile(BuildContext context, ArtistModel artist) {
    final title = artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;

    final subtitle = [
      if (artist.slug != null && artist.slug!.isNotEmpty) '@${artist.slug}',
      if (artist.country != null && artist.country!.isNotEmpty) artist.country!,
    ].join(' • ');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _confirmDelete(artist),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF24132A),
            child: Text(
              title.isNotEmpty ? title[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
          trailing: IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () => _confirmDelete(artist),
          ),
        ),
      ),
    );
  }
}
