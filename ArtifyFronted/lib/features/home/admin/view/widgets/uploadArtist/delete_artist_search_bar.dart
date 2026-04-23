import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteArtistSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final Voidparam onClear;

  const DeleteArtistSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
      cursorColor: Pallete.gradient2,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search artists by name or slug',
        hintStyle:
            GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF111018),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: _buildPrefixIcon(),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: query.isNotEmpty ? _buildClearButton() : null,
        enabledBorder: _buildBorder(Colors.white.withOpacity(0.16)),
        focusedBorder: _buildBorder(Pallete.gradient2, width: 1.4),
        border: _buildBorder(Colors.transparent),
      ),
    );
  }

  Widget _buildPrefixIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Pallete.gradient2, Color(0xFF811F1A)],
          ),
        ),
        child: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
      onPressed: onClear,
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

typedef Voidparam = void Function();
