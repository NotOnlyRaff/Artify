import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicAvatar extends StatelessWidget {
  final String displayName;
  final String? imageUrl;

  const CosmicAvatar({required this.displayName, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFF60A5FA),
            Color(0xFFA855F7),
            Color(0xFFF97316),
            Color(0xFF60A5FA),
          ],
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                width: 86,
                height: 86,
                fit: BoxFit.cover,
              )
            : _fallback(initial),
      ),
    );
  }

  Widget _fallback(String initial) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF4B39EF),
            Color(0xFF18181B),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
