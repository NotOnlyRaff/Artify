import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

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
  }

  @override
  void dispose() {
    artistNameController.dispose();
    displayNameController.dispose();
    slugController.dispose();
    countryController.dispose();
    bioController.dispose();
    super.dispose();
  }

  String _slugFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\\s-]'), '')
        .replaceAll(RegExp(r'\\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<void> _selectImage() async {
    final picked = await pickImage();
    if (picked != null) {
      setState(() {
        selectedImage = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) {
      showSnackBar(context, 'Please complete the required fields.');
      return;
    }

    FocusScope.of(context).unfocus();

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
      // 1) signup artista
      await ref.read(authViewModelProvider.notifier).signUpUser(
            name: widget.accountName,
            email: widget.email,
            password: widget.password,
            isArtist: true,
          );

      final signupState = ref.read(authViewModelProvider);
      if (signupState.hasError || signupState.valueOrNull == null) {
        if (!mounted) return;
        showSnackBar(
          context,
          signupState.error?.toString() ?? 'Signup failed.',
        );
        return;
      }

      // 2) login tecnico per ottenere token e current user
      await ref.read(authViewModelProvider.notifier).loginUser(
            email: widget.email,
            password: widget.password,
          );

      final loginState = ref.read(authViewModelProvider);
      if (loginState.hasError || loginState.valueOrNull == null) {
        if (!mounted) return;
        showSnackBar(
          context,
          loginState.error?.toString() ?? 'Login after signup failed.',
        );
        return;
      }

      // 3) upload immagine opzionale
      String? imageUrl;
      if (selectedImage != null) {
        final imageRes = await ref
            .read(artistViewModelProvider.notifier)
            .uploadArtistImage(image: selectedImage!);

        switch (imageRes) {
          case Left(value: final failure):
            if (!mounted) return;
            showSnackBar(context, failure.message);
            return;
          case Right(value: final uploadedUrl):
            imageUrl = uploadedUrl;
        }
      }

      // 4) create artist
      await ref.read(artistViewModelProvider.notifier).createArtist(
            name: artistName,
            displayName: displayName.isEmpty ? null : displayName,
            slug: finalSlug.isEmpty ? null : finalSlug,
            imageUrl: imageUrl,
            bio: bio.isEmpty ? null : bio,
            country: country.isEmpty ? null : country,
          );

      final artistState = ref.read(artistViewModelProvider);
      if (artistState?.hasError == true) {
        if (!mounted) return;
        showSnackBar(
          context,
          artistState!.error.toString(),
        );
        return;
      }

      // 5) logout e redirect a login
      await ref.read(authViewModelProvider.notifier).logout();

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
    final artistVmLoading = ref
        .watch(artistViewModelProvider.select((val) => val?.isLoading == true));

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
                  colors: [Color(0xFF050509), Color(0xFF140813)],
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
                          _buildHeader(context),
                          const SizedBox(height: 28),
                          _buildFormCard(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Pallete.gradient1,
                    Pallete.gradient2,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Pallete.primary.withOpacity(0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_external_on_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artist setup',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'Shape your public identity',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Create your artist profile\nbefore entering Artify.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This profile will define how listeners discover your sound, image and identity.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Pallete.surfacePrimary.withOpacity(0.72),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Pallete.primary.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarPicker(),
            const SizedBox(height: 22),
            _fieldLabel('Artist name'),
            const SizedBox(height: 8),
            _textField(
              controller: artistNameController,
              hintText: 'Your artist name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Artist name is required'
                  : null,
              onChanged: (value) {
                if (slugController.text.trim().isEmpty ||
                    slugController.text.trim() ==
                        _slugFromName(displayNameController.text)) {
                  slugController.text = _slugFromName(value);
                }
              },
            ),
            const SizedBox(height: 18),
            _fieldLabel('Display name'),
            const SizedBox(height: 8),
            _textField(
              controller: displayNameController,
              hintText: 'Public display name',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Slug'),
            const SizedBox(height: 8),
            _textField(
              controller: slugController,
              hintText: 'your-artist-slug',
              prefixIcon: Icons.link_rounded,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Country'),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.trim().isEmpty) {
                  return _countrySuggestions;
                }
                return _countrySuggestions.where(
                  (country) => country.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                );
              },
              onSelected: (value) {
                countryController.text = value;
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                textEditingController.text = countryController.text;
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    hintText: 'Choose your country',
                    prefixIcon: Icons.public_rounded,
                  ),
                  onChanged: (value) {
                    countryController.text = value;
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            _fieldLabel('Bio'),
            const SizedBox(height: 8),
            TextFormField(
              controller: bioController,
              minLines: 4,
              maxLines: 5,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: _inputDecoration(
                hintText:
                    'Tell listeners who you are, what you create, and your vibe...',
                prefixIcon: Icons.auto_awesome_outlined,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ).copyWith(
                  backgroundColor:
                      WidgetStateProperty.resolveWith((states) => null),
                  elevation: WidgetStateProperty.all(8),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Pallete.gradient1,
                        Pallete.gradient2,
                        Pallete.gradient3,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Create artist profile',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _selectImage,
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
                gradient: selectedImage == null
                    ? const LinearGradient(
                        colors: [
                          Pallete.gradient1,
                          Pallete.gradient2,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: selectedImage?.bytes != null
                    ? DecorationImage(
                        image: MemoryImage(selectedImage!.bytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: selectedImage == null ? null : Colors.white12,
              ),
              child: selectedImage == null
                  ? const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.white,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              'Add profile image',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white38,
        fontSize: 13,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: Colors.white60,
              size: 20,
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(
          color: Pallete.gradient2,
          width: 1.4,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 1.2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
    );
  }
}
