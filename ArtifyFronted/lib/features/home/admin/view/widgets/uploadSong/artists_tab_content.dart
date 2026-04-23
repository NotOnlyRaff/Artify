// lib/features/home/song/view/widgets/artists_tab_content.dart
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/models/song_artist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistsTabContent extends ConsumerWidget {
  final List<ArtistModel> selectedArtists;
  final Map<String, SongArtistRole> artistRoles;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ArtistModel> onSelectArtist;
  final ValueChanged<ArtistModel> onRemoveArtist;
  final void Function(String, SongArtistRole) onRoleChanged;
  final TextEditingController producerController;

  const ArtistsTabContent({
    super.key,
    required this.selectedArtists,
    required this.artistRoles,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSelectArtist,
    required this.onRemoveArtist,
    required this.onRoleChanged,
    required this.producerController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmedQuery = searchQuery.trim();
    final bool enableSearch = trimmedQuery.length >= 2;

    final artistsAsync = enableSearch
        ? ref.watch(getArtistsProvider(search: trimmedQuery))
        : const AsyncValue<List<ArtistModel>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Linked artists & roles'),
        const SizedBox(height: 8),
        if (selectedArtists.isNotEmpty)
          Column(
            children: selectedArtists.map((artist) {
              final displayName = artist.displayName?.isNotEmpty == true
                  ? artist.displayName!
                  : artist.name;
              final currentRole = artistRoles[artist.id] ??
                  (selectedArtists.first.id == artist.id
                      ? SongArtistRole.primary
                      : SongArtistRole.featured);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                          if (value != null) {
                            onRoleChanged(artist.id, value);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.white54),
                      onPressed: () => onRemoveArtist(artist),
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
        const SizedBox(height: 18),
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
          controller: searchController,
          onChanged: onSearchChanged,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search artist by name...',
            hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white54, fontSize: 13),
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
              borderSide:
                  const BorderSide(color: Pallete.gradient2, width: 1.2),
            ),
            suffixIcon: const Icon(Icons.search_rounded,
                size: 20, color: Colors.white54),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          enableSearch
              ? 'Type to search artists in your catalog.'
              : 'Type at least 2 characters to search artists.',
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        if (enableSearch)
          artistsAsync.when(
            data: (artists) {
              final filtered = artists
                  .where((a) => !selectedArtists.any((sel) => sel.id == a.id))
                  .toList();
              if (filtered.isEmpty) {
                return Text(
                  'No artists found for "$trimmedQuery".',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38, fontSize: 11),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: filtered.take(6).map((artist) {
                  final displayName = artist.displayName?.isNotEmpty == true
                      ? artist.displayName!
                      : artist.name;
                  return InkWell(
                    onTap: () => onSelectArtist(artist),
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
                            child: const Icon(Icons.person_rounded,
                                size: 16, color: Colors.white70),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.add_rounded,
                              size: 18, color: Colors.white70),
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
                    strokeWidth: 2, color: Pallete.gradient2),
              ),
            ),
            error: (e, _) => Text(
              e.toString(),
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.redAccent, fontSize: 11),
            ),
          ),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Production'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Producer',
          placeholder: 'Optional',
          controller: producerController,
        ),
      ],
    );
  }
}
