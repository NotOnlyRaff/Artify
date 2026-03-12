import 'package:client/features/home/album/model/album_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAlbumTile extends StatelessWidget {
  final AlbumModel album;
  final VoidCallback onDelete;

  const DeleteAlbumTile({
    super.key,
    required this.album,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (album.label?.isNotEmpty ?? false) subtitleParts.add(album.label!);
    if (album.releaseDate != null)
      subtitleParts.add(album.releaseDate!.year.toString());
    if (album.albumType?.isNotEmpty ?? false)
      subtitleParts.add(album.albumType!.toUpperCase());

    final subtitle =
        subtitleParts.isEmpty ? 'Album' : subtitleParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _buildCover(),
        title: Text(
          album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
        ),
        trailing: IconButton(
          icon:
              const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF811F1A), Color(0xFF4B39EF)],
          ),
        ),
        child: album.coverUrl != null
            ? Image.network(album.coverUrl!, fit: BoxFit.cover)
            : const Icon(Icons.album_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
