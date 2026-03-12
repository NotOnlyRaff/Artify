// lib/features/home/admin/view/pages/album/delete_album_page.dart

import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/delete_album_tile.dart';
import 'package:client/features/home/admin/view/widgets/uploadAlbum/studio_background.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAlbumPage extends ConsumerWidget {
  const DeleteAlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listeners per l'esito della cancellazione
    ref.listen<AsyncValue?>(albumViewModelProvider, (prev, next) {
      next?.whenOrNull(
        data: (_) => showSnackBar(context, 'Album deleted successfully.'),
        error: (error, _) => showSnackBar(context, error.toString()),
      );
    });

    final albumsAsync = ref.watch(getAllAlbumsProvider());

    return Scaffold(
      extendBodyBehindAppBar: true,
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
              fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          const StudioBackground(), // Riutilizzo dello sfondo comune
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: albumsAsync.when(
                data: (albums) => _buildList(context, ref, albums),
                loading: () => const Center(child: Loader()),
                error: (e, _) => _buildError(e.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<AlbumModel> albums) {
    if (albums.isEmpty) {
      return Center(
        child: Text(
          'No albums found in the catalogue.',
          textAlign: TextAlign.center,
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select an album to remove. This action is permanent.',
          style:
              GoogleFonts.plusJakartaSans(color: Colors.red[100], fontSize: 12),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final album = albums[index];
              return DeleteAlbumTile(
                album: album,
                onDelete: () => _confirmDeletion(context, ref, album),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeletion(
      BuildContext context, WidgetRef ref, AlbumModel album) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF050509),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete album',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: Text('Permanently delete "${album.title}"?',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(albumViewModelProvider.notifier).deleteAlbum(album.id);
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(message,
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13)),
    );
  }
}
