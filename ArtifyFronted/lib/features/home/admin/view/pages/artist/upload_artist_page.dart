import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/studio_badge.dart';
import 'package:client/features/home/admin/view/widgets/uploadArtist/artist_upload_layout.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class UploadArtistPage extends ConsumerStatefulWidget {
  const UploadArtistPage({super.key});

  @override
  ConsumerState<UploadArtistPage> createState() => _UploadArtistPageState();
}

class _UploadArtistPageState extends ConsumerState<UploadArtistPage> {
  // 1. STATE & CONTROLLERS
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  PickedMedia? selectedImage;

  @override
  void dispose() {
    for (var c in [
      _nameController,
      _displayNameController,
      _slugController,
      _countryController,
      _bioController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // 2. LOGIC METHODS
  void _generateSlug() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    _slugController.text = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }

  Future<void> _pickImg() async {
    final picked = await pickImage();
    if (picked != null) setState(() => selectedImage = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.trim().isEmpty) {
      return showSnackBar(context, 'Name is required.');
    }

    String? imageUrl;
    if (selectedImage != null) {
      final res = await ref
          .read(artistViewModelProvider.notifier)
          .uploadArtistImage(image: selectedImage!);
      if (!mounted) return;
      if (res is Left) {
        return showSnackBar(context, (res as Left).value.message);
      }
      imageUrl = (res as Right).value;
    }

    if (!mounted) return;
    await ref.read(artistViewModelProvider.notifier).createArtist(
          name: _nameController.text.trim(),
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          slug: _slugController.text.trim().isEmpty
              ? null
              : _slugController.text.trim(),
          imageUrl: imageUrl,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          country: _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
        );
  }

  // 3. BUILD (SKELETON ONLY)
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue?>(artistViewModelProvider, (prev, next) {
      next?.whenOrNull(
        data: (_) {
          showSnackBar(context, 'Artist created!');
          Navigator.pop(context);
        },
        error: (e, _) => showSnackBar(context, e.toString()),
      );
    });

    final isLoading = ref
        .watch(artistViewModelProvider.select((val) => val?.isLoading == true));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(children: [
          Text('New artist'),
          SizedBox(width: 8),
          StudioBadge(label: 'Admin')
        ]),
        actions: [
          IconButton(
              onPressed: isLoading ? null : _submit,
              icon: const Icon(Icons.check_rounded))
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF050509), Color(0xFF140813)])),
        child: SafeArea(
          child: isLoading
              ? const Center(child: Loader())
              : ArtistUploadLayout(
                  selectedImage: selectedImage,
                  onPickImage: _pickImg,
                  nameController: _nameController,
                  displayNameController: _displayNameController,
                  slugController: _slugController,
                  countryController: _countryController,
                  bioController: _bioController,
                  onGenerateSlug: _generateSlug,
                ),
        ),
      ),
    );
  }
}
