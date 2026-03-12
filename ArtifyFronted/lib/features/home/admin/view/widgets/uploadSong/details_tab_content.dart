import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_release_date_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailsTabContent extends StatelessWidget {
  final DateTime? releaseDate;
  final VoidCallback onPickReleaseDate;
  final TextEditingController genreController;
  final TextEditingController moodController;

  const DetailsTabContent({
    super.key,
    required this.releaseDate,
    required this.onPickReleaseDate,
    required this.genreController,
    required this.moodController,
  });

  @override
  Widget build(BuildContext context) {
    const genreSuggestions = [
      'Pop',
      'Hip-hop',
      'R&B',
      'Electronic',
      'Indie',
      'Lo-fi',
      'Rock'
    ];
    const moodSuggestions = [
      'Chill',
      'Upbeat',
      'Dark',
      'Dreamy',
      'Aggressive',
      'Romantic'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        UploadReleaseDateField(
          releaseDate: releaseDate,
          onTap: onPickReleaseDate,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Metadata'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Genre',
          placeholder: 'Pop, Electronic, Indie...',
          controller: genreController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Quick genres',
          suggestions: genreSuggestions,
          onTap: (g) => genreController.text = g,
        ),
        const SizedBox(height: 14),
        UploadTextField(
          label: 'Mood',
          placeholder: 'Chill, Dark, Upbeat...',
          controller: moodController,
        ),
        const SizedBox(height: 6),
        _buildSuggestionChips(
          label: 'Suggested moods',
          suggestions: moodSuggestions,
          onTap: (m) => moodController.text = m,
        ),
      ],
    );
  }

  Widget _buildSuggestionChips({
    required String label,
    required List<String> suggestions,
    required ValueChanged<String> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: suggestions.map((s) {
            return GestureDetector(
              onTap: () => onTap(s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.03),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
