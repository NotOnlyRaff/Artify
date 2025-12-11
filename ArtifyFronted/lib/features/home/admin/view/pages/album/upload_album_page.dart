import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/core/widgets/artify_section_title.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_text_field.dart';
import 'package:client/features/home/admin/view/widgets/uploadSong/upload_artwork_picker.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadAlbumPage extends ConsumerStatefulWidget {
  const UploadAlbumPage({super.key});

  @override
  ConsumerState<UploadAlbumPage> createState() => _UploadAlbumPageState();
}

/// Campo data rilascio (riusabile)
class UploadReleaseDateField extends StatelessWidget {
  final DateTime? releaseDate;
  final VoidCallback onTap;

  const UploadReleaseDateField({
    super.key,
    required this.releaseDate,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = releaseDate != null;
    final text = hasDate ? _formatDate(releaseDate!) : 'Select release date';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasDate
                ? Pallete.gradient2.withOpacity(0.9)
                : Colors.white.withOpacity(0.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Pallete.gradient2,
                    Color(0xFF811F1A),
                  ],
                ),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: hasDate ? Colors.white : Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadAlbumPageState extends ConsumerState<UploadAlbumPage> {
  // --- CONTROLLER TESTO ---
  final titleController = TextEditingController();
  final labelController = TextEditingController();
  final artistIdsController = TextEditingController();
  final songIdsController = TextEditingController();

  // --- RELEASE DATE ---
  DateTime? _releaseDate;

  // --- COVER PICKED (da dispositivo) ---
  PickedMedia? selectedCover;

  // --- ALBUM TYPE ---
  String? _selectedAlbumType; // 'album', 'single', 'ep', 'compilation'
  final List<String> _albumTypeValues = const [
    'album',
    'single',
    'ep',
    'compilation',
  ];

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    titleController.dispose();
    labelController.dispose();
    artistIdsController.dispose();
    songIdsController.dispose();
    super.dispose();
  }

  // ---------- PICKERS ----------

  Future<void> _selectCover() async {
    final picked = await pickImage();
    if (picked != null) {
      setState(() {
        selectedCover = picked;
      });
    }
  }

  Future<void> _pickReleaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Pallete.gradient2,
              surface: Color(0xFF050509),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _releaseDate = picked;
      });
    }
  }

  List<String> _parseIds(String raw) {
    return raw
        .split(RegExp(r'[,\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

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

  // ---------- SUBMIT ----------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final title = titleController.text.trim();
    final label = labelController.text.trim();
    final artistIdsRaw = artistIdsController.text.trim();
    final songIdsRaw = songIdsController.text.trim();

    if (title.isEmpty) {
      showSnackBar(context, 'Album title is required.');
      return;
    }

    final artistIds =
        artistIdsRaw.isEmpty ? <String>[] : _parseIds(artistIdsRaw);
    final songIds = songIdsRaw.isEmpty ? <String>[] : _parseIds(songIdsRaw);

    // TODO backend:
    // selectedCover contiene il file scelto dal dispositivo.
    // Quando aggiungi il supporto lato API,
    // potrai passarlo a AlbumViewModel / repository come fai per uploadSong.
    await ref.read(albumViewModelProvider.notifier).createAlbum(
          title: title,
          releaseDate: _releaseDate,
          label: label.isEmpty ? null : label,
          albumType: _selectedAlbumType, // album / single / ep / compilation
          coverUrl: null, // nessuna URL: la cover è locale (selectedCover)
          artistIds: artistIds,
          songIds: songIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    // LISTEN sullo stato del ViewModel (success/error)
    ref.listen<AsyncValue?>(albumViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (data) {
          showSnackBar(context, 'Album created successfully!');
          Navigator.pop(context);
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {},
      );
    });

    final isLoading = ref
        .watch(albumViewModelProvider.select((val) => val?.isLoading == true));

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
              'New album',
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
                color: Colors.white.withOpacity(0.08),
              ),
              child: Text(
                'Admin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
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
          // Glow
          Positioned(
            right: -80,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Pallete.gradient2.withOpacity(0.26),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(child: Loader())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 960), // web
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create a new album for your catalog.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Artwork, release and relations — all in one place.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color:
                                          Pallete.cardColor.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Pallete.borderColor
                                            .withOpacity(0.7),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.45),
                                          blurRadius: 26,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: isWide
                                        ? _buildWideLayout()
                                        : _buildNarrowLayout(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- Cover section comune ------------------------------------------

  Widget _buildCoverSection({bool center = true}) {
    final content = Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Album cover'),
        const SizedBox(height: 10),
        SizedBox(
          width: 160,
          child: UploadArtworkPicker(
            selectedImage: selectedCover,
            onTap: _selectCover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: square image, min 1000×1000 px.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );

    if (center) {
      return Center(child: content);
    }
    return content;
  }

  // ---------- Layouts -------------------------------------------------------

  Widget _buildWideLayout() {
    // Colonna sinistra: cover
    final coverColumn = SizedBox(
      width: 220,
      child: _buildCoverSection(center: false),
    );

    // Colonna centrale: basic info + release + type
    final basicColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Basic info'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Album title',
          placeholder: 'Give your release a name',
          controller: titleController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Label',
          placeholder: 'Label or imprint (optional)',
          controller: labelController,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        UploadReleaseDateField(
          releaseDate: _releaseDate,
          onTap: _pickReleaseDate,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Album type'),
        const SizedBox(height: 8),
        _buildAlbumTypeChips(),
      ],
    );

    // Colonna destra: relations
    final relationsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ArtifySectionTitle('Relations (optional)'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist IDs',
          placeholder: 'Comma or space separated IDs',
          controller: artistIdsController,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Song IDs',
          placeholder: 'Comma or space separated IDs',
          controller: songIdsController,
        ),
        const SizedBox(height: 6),
        Text(
          'Use internal IDs from your API. You can also link songs and artists later from the admin console.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        coverColumn,
        const SizedBox(width: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: basicColumn),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: relationsColumn),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoverSection(center: true),
        const SizedBox(height: 24),
        const ArtifySectionTitle('Basic info'),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Album title',
          placeholder: 'Give your release a name',
          controller: titleController,
          required: true,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Label',
          placeholder: 'Label or imprint (optional)',
          controller: labelController,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Release'),
        const SizedBox(height: 8),
        UploadReleaseDateField(
          releaseDate: _releaseDate,
          onTap: _pickReleaseDate,
        ),
        const SizedBox(height: 18),
        const ArtifySectionTitle('Album type'),
        const SizedBox(height: 8),
        _buildAlbumTypeChips(),
        const SizedBox(height: 22),
        const ArtifySectionTitle('Relations (optional)'),
        const SizedBox(height: 8),
        UploadTextField(
          label: 'Artist IDs',
          placeholder: 'Comma or space separated IDs',
          controller: artistIdsController,
        ),
        const SizedBox(height: 12),
        UploadTextField(
          label: 'Song IDs',
          placeholder: 'Comma or space separated IDs',
          controller: songIdsController,
        ),
        const SizedBox(height: 6),
        Text(
          'Use internal IDs from your API. You can also link songs and artists later from the admin console.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ---------- Album type chips ----------------------------------------------

  Widget _buildAlbumTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _albumTypeValues.map((value) {
        final selected = _selectedAlbumType == value;
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
            setState(() {
              _selectedAlbumType = v ? value : null;
            });
          },
        );
      }).toList(),
    );
  }
}
