import 'package:client/core/utils.dart';
import 'package:client/core/widgets/artify_audio_picker.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_artwork_picker.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_lyrics_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:flutter/material.dart';

class TrackTabContent extends StatelessWidget {
  final PickedMedia? selectedImage;
  final PickedMedia? selectedAudio;
  final VoidCallback onSelectImage;
  final VoidCallback onSelectAudio;
  final TextEditingController songNameController;
  final TextEditingController lyricsController;

  const TrackTabContent({
    super.key,
    required this.selectedImage,
    required this.selectedAudio,
    required this.onSelectImage,
    required this.onSelectAudio,
    required this.songNameController,
    required this.lyricsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Artwork & audio'),
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
                      selectedImage: selectedImage,
                      onTap: onSelectImage,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ArtifyAudioPicker(
          selectedAudio: selectedAudio,
          onTapSelectAudio: onSelectAudio,
        ),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Track basics'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Song title',
          placeholder: 'Give your track a name',
          controller: songNameController,
          required: true,
        ),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Lyrics'),
        const SizedBox(height: 8),
        UploadLyricsField(controller: lyricsController),
      ],
    );
  }
}
