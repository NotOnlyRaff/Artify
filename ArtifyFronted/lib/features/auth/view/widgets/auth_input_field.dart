// lib/features/auth/view/widgets/auth_input_field.dart
import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  const AuthInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    required this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 13,
            ),
            prefixIcon: Icon(prefixIcon, color: Colors.white60, size: 20),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Pallete.gradient2, width: 1.4),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
