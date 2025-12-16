// lib/features/home/admin/view/widgets/uploadAlbum/upload_album_album_tab.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_artwork_picker.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AlbumTab extends ConsumerWidget {
  final dynamic selectedCover; // PickedMedia? ma evito l'import qui
  final VoidCallback onSelectCover;

  final TextEditingController titleController;

  final List<ArtistModel> selectedArtists;
  final ValueChanged<ArtistModel> onAddArtist;
  final ValueChanged<ArtistModel> onRemoveArtist;

  final TextEditingController artistSearchController;
  final String artistSearchQuery;
  final ValueChanged<String> onArtistQueryChanged;

  const AlbumTab({
    super.key,
    required this.selectedCover,
    required this.onSelectCover,
    required this.titleController,
    required this.selectedArtists,
    required this.onAddArtist,
    required this.onRemoveArtist,
    required this.artistSearchController,
    required this.artistSearchQuery,
    required this.onArtistQueryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmedQuery = artistSearchQuery.trim();
    final bool enableSearch = trimmedQuery.length >= 2;

    final artistsAsync = enableSearch
        ? ref.watch(
            getArtistsProvider(
              search: trimmedQuery,
            ),
          )
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Artwork'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final coverSize = maxWidth < 400
                ? 140.0
                : maxWidth < 700
                    ? 180.0
                    : 200.0;

            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: coverSize,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: UploadArtworkPicker(
                      selectedImage: selectedCover,
                      onTap: onSelectCover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const ArtifySectionTitle('Album title'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Title',
          placeholder: 'Give your release a name',
          controller: titleController,
          required: true,
        ),
        const SizedBox(height: 22),

        const ArtifySectionTitle('Main artist(s)'),
        const SizedBox(height: 8),

        // artisti selezionati
        if (selectedArtists.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: selectedArtists.map((artist) {
              final displayName =
                  artist.displayName?.isNotEmpty == true
                      ? artist.displayName!
                      : artist.name;

              return Chip(
                label: Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.white.withOpacity(0.06),
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                onDeleted: () => onRemoveArtist(artist),
              );
            }).toList(),
          )
        else
          Text(
            'No artists linked yet. Use the search below to attach them to this album.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),

        const SizedBox(height: 16),
        Text(
          'Search & add artists',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        // search field
        TextField(
          controller: artistSearchController,
          onChanged: onArtistQueryChanged,
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
          enableSearch
              ? 'Type to search artists in your catalog.'
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
                  .where((a) =>
                      !selectedArtists.any((sel) => sel.id == a.id))
                  .toList();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filtered.take(6).map((artist) {
                  final displayName =
                      artist.displayName?.isNotEmpty == true
                          ? artist.displayName!
                          : artist.name;

                  return InkWell(
                    onTap: () => onAddArtist(artist),
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
      ],
    );
  }
}
