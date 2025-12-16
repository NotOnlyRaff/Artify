// lib/features/home/admin/view/widgets/uploadAlbum/upload_album_details_tab.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/release_date_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailsTab extends StatelessWidget {
  final DateTime? releaseDate;
  final VoidCallback onPickReleaseDate;

  final TextEditingController labelController;
  final TextEditingController genreController;

  final List<String> albumTypeValues;
  final String? selectedAlbumType;
  final ValueChanged<String?> onAlbumTypeChanged;

  const DetailsTab({
    super.key,
    required this.releaseDate,
    required this.onPickReleaseDate,
    required this.labelController,
    required this.genreController,
    required this.albumTypeValues,
    required this.selectedAlbumType,
    required this.onAlbumTypeChanged,
  });

  String _displayAlbumType(String value) {
    switch (value) {
      case 'album':
        return 'Album';
      case 'single':
        return 'Single';
      case 'ep':
        return 'EP';
      case 'compilation':
        return 'Compilation';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        ReleaseDateField(
          releaseDate: releaseDate,
          onTap: onPickReleaseDate,
        ),
        const SizedBox(height: 22),

        const ArtifySectionTitle('Label & type'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Label',
          placeholder: 'Label or imprint (optional)',
          controller: labelController,
        ),
        const SizedBox(height: 12),
        Text(
          'Album type',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: albumTypeValues.map((value) {
            final selected = selectedAlbumType == value;
            final label = _displayAlbumType(value);

            return ChoiceChip(
              selected: selected,
              label: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white.withOpacity(0.04),
              selectedColor: Pallete.gradient2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected
                      ? Pallete.gradient2.withOpacity(0.9)
                      : Colors.white.withOpacity(0.16),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (v) {
                onAlbumTypeChanged(v ? value : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        const ArtifySectionTitle('Genre'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Genre',
          placeholder: 'Pop, Electronic, Indie...',
          controller: genreController,
        ),
      ],
    );
  }
}
