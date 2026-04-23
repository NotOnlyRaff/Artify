// lib/features/home/song/view/widgets/upload_audio_picker.dart

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart'; // PickedMedia
import 'package:client/features/home/view/widgets/audio_wave.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtifyAudioPicker extends StatelessWidget {
  final PickedMedia? selectedAudio;
  final VoidCallback onTapSelectAudio;

  const ArtifyAudioPicker({
    super.key,
    required this.selectedAudio,
    required this.onTapSelectAudio,
  });

  @override
  Widget build(BuildContext context) {
    // Nessun audio selezionato
    if (selectedAudio == null) {
      return GestureDetector(
        onTap: onTapSelectAudio,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.02),
            border: Border.all(
              color: Pallete.borderColor.withOpacity(0.9),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.audiotrack_rounded,
                color: Pallete.gradient2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose audio file',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                'Browse',
                style: GoogleFonts.plusJakartaSans(
                  color: Pallete.gradient2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Web
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.02),
          border: Border.all(
            color: Pallete.borderColor.withOpacity(0.9),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.audiotrack_rounded,
              color: Pallete.gradient2,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedAudio!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: onTapSelectAudio,
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    // Mobile / desktop con filePath
    if (selectedAudio!.filePath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AudioWave(path: selectedAudio!.filePath!),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedAudio!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: onTapSelectAudio,
                child: const Text('Change'),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
