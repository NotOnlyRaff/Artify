import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/cosmic_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicHeader extends StatelessWidget {
  final ArtistModel artist;

  const CosmicHeader({
    super.key,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = artist.displayName?.trim().isNotEmpty == true
        ? artist.displayName!.trim()
        : artist.name;

    final slug = artist.slug?.trim();
    final country = artist.country?.trim();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CosmicAvatar(
            displayName: displayName,
            imageUrl: artist.imageUrl,
            size: 104,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARTIST',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (slug != null && slug.isNotEmpty)
                      _MetaChip(
                        icon: Icons.alternate_email_rounded,
                        label: slug,
                      ),
                    if (country != null && country.isNotEmpty)
                      _MetaChip(
                        icon: Icons.public_rounded,
                        label: country,
                      ),
                    _MetaChip(
                      icon: Icons.music_note_rounded,
                      label:
                          '${artist.songs.length} track${artist.songs.length == 1 ? '' : 's'}',
                    ),
                    _MetaChip(
                      icon: Icons.album_rounded,
                      label:
                          '${artist.albums.length} release${artist.albums.length == 1 ? '' : 's'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
