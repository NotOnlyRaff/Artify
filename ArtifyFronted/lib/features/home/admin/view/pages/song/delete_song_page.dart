import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteSongPage extends ConsumerStatefulWidget {
  const DeleteSongPage({super.key});

  @override
  ConsumerState<DeleteSongPage> createState() => _DeleteSongPageState();
}

class _DeleteSongPageState extends ConsumerState<DeleteSongPage> {
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF090612),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent.shade200,
                size: 32,
              ),
              const SizedBox(height: 14),
              Text(
                'Delete this track?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '“${song.songName}” by ${song.artists}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await ref
          .read(songViewModelProvider.notifier)
          .deleteSong(songId: song.id);

      // invalidiamo la lista per ricaricare le tracce
      ref.invalidate(getAllSongsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👇 QUI è il posto giusto per listen
    ref.listen<AsyncValue?>(songViewModelProvider, (prev, next) {
      if (next == null) return;

      next.when(
        data: (_) {
          showSnackBar(context, 'Song removed from Artify.');
        },
        error: (error, stack) {
          showSnackBar(context, error.toString());
        },
        loading: () {},
      );
    });

    final songsAsync = ref.watch(getAllSongsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Manage tracks',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
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
        child: songsAsync.when(
          data: (songs) {
            if (songs.isEmpty) {
              return Center(
                child: Text(
                  'No tracks in your library yet.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: songs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final song = songs[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Pallete.cardColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Pallete.borderColor.withOpacity(0.8),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        song.thumbnailUrl ??
                            'https://via.placeholder.com/150?text=No+Image',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      song.songName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      song.artists.isNotEmpty
                          ? song.artists.map((a) => a.artistName).join(', ')
                          : 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDelete(context, ref, song),
                    ),
                  ),
                );
              },
            );
          },
          error: (err, _) => Center(
            child: Text(
              err.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
