// lib/features/auth/view/widgets/artist_onboarding_form_card.dart
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/auth/view/widgets/artist_avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistOnboardingFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController artistNameController;
  final TextEditingController displayNameController;
  final TextEditingController slugController;
  final TextEditingController countryController;
  final TextEditingController bioController;
  final PickedMedia? selectedImage;
  final VoidCallback onSelectImage;
  final VoidCallback onSubmit;
  final ValueChanged<String> onArtistNameChanged;
  final List<String> countrySuggestions;

  const ArtistOnboardingFormCard({
    super.key,
    required this.formKey,
    required this.artistNameController,
    required this.displayNameController,
    required this.slugController,
    required this.countryController,
    required this.bioController,
    required this.selectedImage,
    required this.onSelectImage,
    required this.onSubmit,
    required this.onArtistNameChanged,
    required this.countrySuggestions,
  });

  @override
  Widget build(BuildContext context) {
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
            ArtistAvatarPicker(
              selectedImage: selectedImage,
              onSelectImage: onSelectImage,
            ),
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
              onChanged: onArtistNameChanged,
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
                  return countrySuggestions;
                }
                return countrySuggestions.where(
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
                onPressed: onSubmit,
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
