import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;

  const SearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
        ),
        cursorColor: Pallete.gradient2,
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search tracks or artists',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFF111018),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Pallete.gradient2,
                    Color(0xFF811F1A),
                  ],
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.16),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(
              color: Pallete.gradient2,
              width: 1.4,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
