import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileCardShell extends StatelessWidget {
  final Widget child;

  const ProfileCardShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  final String text;

  const ProfileSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      style: GoogleFonts.plusJakartaSans(
        color: enabled ? Colors.white : Colors.white54,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.white70),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.white60, size: 20) : null,
        suffixIcon: suffixIcon,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.03)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Pallete.gradient2, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Pallete.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Pallete.errorColor, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white60,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleChip extends StatelessWidget {
  final UserRole role;

  const RoleChip({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ArtistChip extends StatelessWidget {
  const ArtistChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Pallete.accentCyan.withOpacity(0.14),
      ),
      child: Text(
        'ARTIST PROFILE',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String buildUserInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'U';

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.characters.take(1).toString().toUpperCase();
  }

  return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'
      .toUpperCase();
}
