import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteArtistTile extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback onDelete;

  const DeleteArtistTile({
    super.key,
    required this.artist,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;
    final subtitle = [
      if (artist.slug != null && artist.slug!.isNotEmpty) '@${artist.slug}',
      if (artist.country != null && artist.country!.isNotEmpty) artist.country!,
    ].join(' • ');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onDelete,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF24132A),
            child: Text(
              title.isNotEmpty ? title[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70, fontSize: 12),
                ),
          trailing: const Icon(Icons.delete_outline_rounded,
              color: Colors.redAccent, size: 20),
        ),
      ),
    );
  }
}
