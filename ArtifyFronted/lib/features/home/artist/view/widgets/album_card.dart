// ALBUM CARD -----------------------------------------------------------------
import 'package:client/features/home/album/model/album_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlbumCard extends StatelessWidget {
  final AlbumModel album;

  const AlbumCard({
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final year = album.releaseDate?.year.toString();
    final subtitleParts = <String>[];

    if (album.albumType != null && album.albumType!.isNotEmpty) {
      final t = album.albumType!;
      subtitleParts.add('${t[0].toUpperCase()}${t.substring(1)}');
    }
    if (year != null) {
      subtitleParts.add(year);
    }
    if (album.label != null && album.label!.isNotEmpty) {
      subtitleParts.add(album.label!);
    }
    final subtitle = subtitleParts.join(' • ');

    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: naviga a AlbumDetailPage se/quando esisterà
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      album.coverUrl ??
                          'https://via.placeholder.com/300?text=Album',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4B39EF),
                              Color(0xFF111827),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.album_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    // gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.45),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Icon(
                          Icons.album_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
