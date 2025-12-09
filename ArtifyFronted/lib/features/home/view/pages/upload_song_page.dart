import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/custom_field.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/view/widgets/audio_wave.dart';
import 'package:client/features/home/viewmodel/home_viewmodel.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadSongPage extends ConsumerStatefulWidget {
  const UploadSongPage({super.key});

  @override
  ConsumerState<UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends ConsumerState<UploadSongPage> {
  final songNameController = TextEditingController();
  final artistController = TextEditingController();
  Color selectedColor = Pallete.cardColor;

  PickedMedia? selectedImage;
  PickedMedia? selectedAudio;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  void selectAudio() async {
    final pickedAudio = await pickAudio();
    if (pickedAudio != null) {
      setState(() {
        selectedAudio = pickedAudio;
      });
    }
  }

  void selectImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      setState(() {
        selectedImage = pickedImage;
      });
    }
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate() ||
        selectedAudio == null ||
        selectedImage == null) {
      showSnackBar(context, 'Please fill all fields and select files.');
      return;
    }

    final audioFile = selectedAudio;
    final imageFile = selectedImage;

    if (audioFile == null || imageFile == null) {
      showSnackBar(context, 'Errore nella selezione dei file, riprova.');
      return;
    }

    // Qui delego tutto al ViewModel: hex e token li recupera lui
    await ref.read(homeViewModelProvider.notifier).uploadSong(
          selectedAudio: audioFile,
          selectedThumbnail: imageFile,
          songName: songNameController.text.trim(),
          artist: artistController.text.trim(),
          hexCode: selectedColor.value.toRadixString(16).padLeft(8, '0'),
          token: '', // il token lo prende il ViewModel
        );
  }

  @override
  void dispose() {
    songNameController.dispose();
    artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambi di stato del viewmodel
    ref.listen<AsyncValue?>(homeViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (data) {
          // Upload riuscito
          showSnackBar(context, 'Song uploaded successfully!');
          Navigator.pop(context); // torna alla Home (pop dello screen)
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {
          // niente, il loader lo gestiamo già con isLoading
        },
      );
    });
    final isLoading = ref
        .watch(homeViewModelProvider.select((val) => val?.isLoading == true));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New track',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _submit,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
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
            child: isLoading
                ? const Center(child: Loader())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sottotitolo
                          Text(
                            'Upload a new song to your Artify library.',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Card principale
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Pallete.cardColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Pallete.borderColor.withOpacity(0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Artwork
                                _sectionTitle('Artwork'),
                                const SizedBox(height: 8),
                                _buildArtworkPicker(),
                                const SizedBox(height: 22),

                                // Audio file
                                _sectionTitle('Audio file'),
                                const SizedBox(height: 8),
                                _buildAudioPicker(),
                                const SizedBox(height: 22),

                                // Track details
                                _sectionTitle('Track details'),
                                const SizedBox(height: 12),
                                CustomField(
                                  hintText: 'Artist',
                                  controller: artistController,
                                ),
                                const SizedBox(height: 16),
                                CustomField(
                                  hintText: 'Song name',
                                  controller: songNameController,
                                ),
                                const SizedBox(height: 22),

                                // Accent color
                                _sectionTitle('Accent color'),
                                const SizedBox(height: 8),
                                _buildColorPicker(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- WIDGET DI SUPPORTO ----------

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildArtworkPicker() {
    return GestureDetector(
      onTap: selectImage,
      child: selectedImage != null
          ? SizedBox(
              height: 170,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: kIsWeb && selectedImage!.bytes != null
                    ? Image.memory(
                        selectedImage!.bytes!,
                        fit: BoxFit.cover,
                      )
                    : (selectedImage!.asFile != null
                        ? Image.file(
                            selectedImage!.asFile!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Pallete.borderColor,
                          )),
              ),
            )
          : DottedBorder(
              color: Pallete.borderColor,
              radius: const Radius.circular(14),
              borderType: BorderType.RRect,
              dashPattern: const [10, 4],
              strokeCap: StrokeCap.round,
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to select artwork',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommended: 1:1 ratio, at least 1000x1000 px',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAudioPicker() {
    if (selectedAudio == null) {
      return GestureDetector(
        onTap: selectAudio,
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
              onPressed: selectAudio,
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

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
                onPressed: selectAudio,
                child: const Text('Change'),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildColorPicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.02),
        border: Border.all(
          color: Pallete.borderColor.withOpacity(0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedColor,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '#${rgbToHex(selectedColor).toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ColorPicker(
            pickersEnabled: const {
              ColorPickerType.wheel: true,
            },
            color: selectedColor,
            onColorChanged: (Color color) {
              setState(() {
                selectedColor = color;
              });
            },
            width: 20,
            height: 20,
            borderRadius: 8,
            wheelSquarePadding: 8,
          ),
        ],
      ),
    );
  }
}
