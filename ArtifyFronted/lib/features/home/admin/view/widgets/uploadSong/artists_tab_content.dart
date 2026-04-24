import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
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

  final TextEditingController composerController;
  final TextEditingController composerSearchController;
  final String composerSearchQuery;
  final ArtistModel? linkedComposerArtist;
  final ValueChanged<String> onComposerSearchChanged;
  final ValueChanged<ArtistModel> onSelectComposerArtist;
  final VoidCallback onClearLinkedComposerArtist;

  final TextEditingController producerController;
  final TextEditingController producerSearchController;
  final String producerSearchQuery;
  final ArtistModel? linkedProducerArtist;
  final ValueChanged<String> onProducerSearchChanged;
  final ValueChanged<ArtistModel> onSelectProducerArtist;
  final VoidCallback onClearLinkedProducerArtist;

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
    required this.composerController,
    required this.composerSearchController,
    required this.composerSearchQuery,
    required this.linkedComposerArtist,
    required this.onComposerSearchChanged,
    required this.onSelectComposerArtist,
    required this.onClearLinkedComposerArtist,
    required this.producerController,
    required this.producerSearchController,
    required this.producerSearchQuery,
    required this.linkedProducerArtist,
    required this.onProducerSearchChanged,
    required this.onSelectProducerArtist,
    required this.onClearLinkedProducerArtist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmedArtistQuery = searchQuery.trim();
    final enableArtistSearch = trimmedArtistQuery.length >= 2;

    final artistResults = enableArtistSearch
        ? ref.watch(getArtistsProvider(search: trimmedArtistQuery))
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

    final composerResults = composerSearchQuery.trim().length >= 2
        ? ref.watch(getArtistsProvider(search: composerSearchQuery.trim()))
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

    final producerResults = producerSearchQuery.trim().length >= 2
        ? ref.watch(getArtistsProvider(search: producerSearchQuery.trim()))
        : const AsyncValue<List<ArtistModel>>.data(<ArtistModel>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Linked artists & roles'),
        const SizedBox(height: 8),
        if (selectedArtists.isEmpty)
          Text(
            'Link one or more artists to define who performs on this track.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          )
        else
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
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
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
                        displayName,
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
                        }).toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            onRoleChanged(artist.id, value);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => onRemoveArtist(artist),
                    ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
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
          enableArtistSearch
              ? 'Search artists in your catalog and attach them to this track.'
              : 'Type at least 2 characters to search artists.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        if (enableArtistSearch)
          artistResults.when(
            data: (artists) {
              final filtered = artists
                  .where(
                    (artist) => !selectedArtists
                        .any((selected) => selected.id == artist.id),
                  )
                  .take(6)
                  .toList(growable: false);

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
                children: filtered.map((artist) {
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
        const SizedBox(height: 24),
        const ArtifySectionTitle('Credits'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final composerCard = StudioCreditSelectorCard(
              title: 'Composer',
              description:
                  'Required. Keep a display name and optionally bind the credit to an existing artist.',
              nameController: composerController,
              searchController: composerSearchController,
              searchQuery: composerSearchQuery,
              linkedArtist: linkedComposerArtist,
              searchResults: composerResults,
              onSearchChanged: onComposerSearchChanged,
              onSelectArtist: onSelectComposerArtist,
              onClearLinkedArtist: onClearLinkedComposerArtist,
              icon: Icons.edit_note_rounded,
              nameLabel: 'Composer name',
              nameHint: 'Who wrote this track?',
              searchLabel: 'Link composer to artist',
              searchHint: 'Search catalog artist',
              required: true,
            );

            final producerCard = StudioCreditSelectorCard(
              title: 'Producer',
              description:
                  'Optional. Link the producer to a catalog artist when you want a proper relational credit.',
              nameController: producerController,
              searchController: producerSearchController,
              searchQuery: producerSearchQuery,
              linkedArtist: linkedProducerArtist,
              searchResults: producerResults,
              onSearchChanged: onProducerSearchChanged,
              onSelectArtist: onSelectProducerArtist,
              onClearLinkedArtist: onClearLinkedProducerArtist,
              icon: Icons.tune_rounded,
              nameLabel: 'Producer name',
              nameHint: 'Optional producer',
              searchLabel: 'Link producer to artist',
              searchHint: 'Search catalog artist',
            );

            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  composerCard,
                  const SizedBox(height: 12),
                  producerCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: composerCard),
                const SizedBox(width: 12),
                Expanded(child: producerCard),
              ],
            );
          },
        ),
      ],
    );
  }
}
