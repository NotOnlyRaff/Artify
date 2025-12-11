import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAlbumPage extends ConsumerWidget {
  const DeleteAlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ascolta esito delete
    ref.listen<AsyncValue?>(albumViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (_) {
          showSnackBar(context, 'Album deleted successfully.');
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {},
      );
    });

    final albumsAsync = ref.watch(getAllAlbumsProvider());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delete albums',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050509),
              Color(0xFF140813),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: albumsAsync.when(
              data: (albums) => _buildBody(context, ref, albums),
              loading: () => const Center(child: Loader()),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<AlbumModel> albums) {
    if (albums.isEmpty) {
      return Center(
        child: Text(
          'No albums found in the catalogue.\nCreate an album before trying to delete one.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select an album to remove from the system. This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.red[100],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final album = albums[index];
              return _buildAlbumTile(context, ref, album);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumTile(
      BuildContext context, WidgetRef ref, AlbumModel album) {
    final subtitleParts = <String>[];

    if (album.label != null && album.label!.isNotEmpty) {
      subtitleParts.add(album.label!);
    }
    if (album.releaseDate != null) {
      subtitleParts.add(album.releaseDate!.year.toString());
    }
    if (album.albumType != null && album.albumType!.isNotEmpty) {
      subtitleParts.add(album.albumType!.toUpperCase());
    }

    final subtitle =
        subtitleParts.isEmpty ? 'Album' : subtitleParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF811F1A),
                  Color(0xFF4B39EF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: album.coverUrl != null
                ? Image.network(
                    album.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.album_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.album_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_forever_rounded,
            color: Colors.redAccent,
            size: 22,
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF050509),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: Text(
                      'Delete album',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to permanently delete "${album.title}"?',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!confirm) return;

            await ref
                .read(albumViewModelProvider.notifier)
                .deleteAlbum(album.id);
          },
        ),
      ),
    );
  }
}
