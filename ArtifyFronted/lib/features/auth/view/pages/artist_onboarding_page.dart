import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/view/widgets/artist_onboarding_form_card.dart';
import 'package:client/features/auth/view/widgets/artist_onboarding_header.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class ArtistOnboardingPage extends ConsumerStatefulWidget {
  final String accountName;
  final String email;
  final String password;

  const ArtistOnboardingPage({
    super.key,
    required this.accountName,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<ArtistOnboardingPage> createState() =>
      _ArtistOnboardingPageState();
}

class _ArtistOnboardingPageState extends ConsumerState<ArtistOnboardingPage> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController artistNameController;
  late final TextEditingController displayNameController;
  late final TextEditingController slugController;
  final countryController = TextEditingController();
  final bioController = TextEditingController();

  PickedMedia? selectedImage;
  bool _isSubmitting = false;
  bool _slugManuallyEdited = false;

  final List<String> _countrySuggestions = const [
    'United States',
    'United Kingdom',
    'Italy',
    'France',
    'Germany',
    'Spain',
    'Brazil',
    'Mexico',
    'Japan',
    'South Korea',
  ];

  @override
  void initState() {
    super.initState();
    artistNameController = TextEditingController(text: widget.accountName);
    displayNameController = TextEditingController(text: widget.accountName);
    slugController = TextEditingController(
      text: _slugFromName(widget.accountName),
    );

    slugController.addListener(_trackSlugManualEdit);
  }

  @override
  void dispose() {
    slugController.removeListener(_trackSlugManualEdit);
    artistNameController.dispose();
    displayNameController.dispose();
    slugController.dispose();
    countryController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void _trackSlugManualEdit() {
    final generatedFromArtistName = _slugFromName(artistNameController.text);
    _slugManuallyEdited = slugController.text.trim() != generatedFromArtistName;
  }

  String _slugFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  void _onArtistNameChanged(String value) {
    if (_slugManuallyEdited) return;
    slugController.text = _slugFromName(value);
  }

  Future<void> _selectImage() async {
    final picked = await pickImage();
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        selectedImage = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!formKey.currentState!.validate()) {
      showSnackBar(context, 'Please complete the required fields.');
      return;
    }

    FocusScope.of(context).unfocus();

    final authVm = ref.read(authViewModelProvider.notifier);
    final artistVm = ref.read(artistViewModelProvider.notifier);

    final artistName = artistNameController.text.trim();
    final displayName = displayNameController.text.trim();
    final slugText = slugController.text.trim();
    final country = countryController.text.trim();
    final bio = bioController.text.trim();
    final finalSlug = slugText.isEmpty ? _slugFromName(artistName) : slugText;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final signupRes = await authVm.signUpUserResult(
        name: widget.accountName,
        email: widget.email,
        password: widget.password,
        isArtist: true,
      );

      if (!mounted) return;

      switch (signupRes) {
        case Left(value: final failure):
          showSnackBar(context, failure.message);
          return;
        case Right():
          break;
      }

      final loginRes = await authVm.loginForArtistOnboarding(
        email: widget.email,
        password: widget.password,
      );

      if (!mounted) return;

      late final String token;
      switch (loginRes) {
        case Left(value: final failure):
          showSnackBar(context, failure.message);
          return;
        case Right(value: final t):
          token = t;
      }

      String? imageUrl;
      if (selectedImage != null) {
        final imageRes = await artistVm.uploadArtistImageWithToken(
          image: selectedImage!,
          token: token,
        );

        if (!mounted) return;

        switch (imageRes) {
          case Left(value: final failure):
            showSnackBar(context, failure.message);
            return;
          case Right(value: final uploadedUrl):
            imageUrl = uploadedUrl;
        }
      }

      final createRes = await artistVm.createArtistResult(
        token: token,
        name: artistName,
        displayName: displayName.isEmpty ? null : displayName,
        slug: finalSlug.isEmpty ? null : finalSlug,
        imageUrl: imageUrl,
        bio: bio.isEmpty ? null : bio,
        country: country.isEmpty ? null : country,
      );

      if (!mounted) return;

      switch (createRes) {
        case Left(value: final failure):
          showSnackBar(context, failure.message);
          return;
        case Right():
          break;
      }

      await authVm.logout();

      if (!mounted) return;

      showSnackBar(
        context,
        'Artist account created successfully! Please login.',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistVmLoading = ref.watch(
      artistViewModelProvider.select((val) => val?.isLoading == true),
    );

    final isLoading = _isSubmitting || artistVmLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: Loader())
          : Container(
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
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ArtistOnboardingHeader(),
                          const SizedBox(height: 28),
                          ArtistOnboardingFormCard(
                            formKey: formKey,
                            artistNameController: artistNameController,
                            displayNameController: displayNameController,
                            slugController: slugController,
                            countryController: countryController,
                            bioController: bioController,
                            selectedImage: selectedImage,
                            onSelectImage: _selectImage,
                            onSubmit: _submit,
                            onArtistNameChanged: _onArtistNameChanged,
                            countrySuggestions: _countrySuggestions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
