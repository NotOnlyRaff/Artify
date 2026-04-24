import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(SongModel song) async {
    final artistNames = song.artists
        .map((artist) => artist.artistName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

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
                artistNames.isEmpty
                    ? song.songName
                    : '"${song.songName}" by $artistNames',
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
      ref.invalidate(getAllSongsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue?>(songViewModelProvider, (previous, next) {
      if (next == null) return;
      next.when(
        data: (_) => showSnackBar(context, 'Song removed from Artify.'),
        error: (error, _) => showSnackBar(context, error.toString()),
        loading: () {},
      );
    });

    final isLoading = ref.watch(
        songViewModelProvider.select((value) => value?.isLoading == true));
    final songsAsync = ref.watch(getAllSongsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delete tracks',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF050509), Color(0xFF140813)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search the catalog and remove tracks you no longer want to keep.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deleting a song is permanent and also removes it from album link flows.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by title or artist...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: Pallete.gradient2,
                          width: 1.2,
                        ),
                      ),
                      suffixIcon: _query.trim().isEmpty
                          ? const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: Colors.white54,
                            )
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: songsAsync.when(
                      data: (songs) => _SongList(
                        songs: songs,
                        query: _query,
                        onDelete: _confirmDelete,
                      ),
                      loading: () => const Center(child: Loader()),
                      error: (error, _) => Center(
                        child: Text(
                          error.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(child: Loader()),
              ),
            ),
        ],
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  final List<SongModel> songs;
  final String query;
  final ValueChanged<SongModel> onDelete;

  const _SongList({
    required this.songs,
    required this.query,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim().toLowerCase();
    final filtered = songs.where((song) {
      if (trimmedQuery.isEmpty) return true;

      final titleMatch = song.songName.toLowerCase().contains(trimmedQuery);
      final artistMatch = song.artists.any(
        (artist) =>
            (artist.artistName ?? '').toLowerCase().contains(trimmedQuery),
      );

      return titleMatch || artistMatch;
    }).toList(growable: false);

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No tracks found.',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final song = filtered[index];
        final subtitle = song.artists
            .map((artist) => artist.artistName)
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .join(', ');

        return Container(
          decoration: BoxDecoration(
            color: Pallete.cardColor.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Pallete.borderColor.withOpacity(0.8)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: song.thumbnailUrl != null
                  ? Image.network(
                      song.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _SongPlaceholder(),
                    )
                  : const _SongPlaceholder(),
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
              subtitle.isEmpty ? 'Unknown artist' : subtitle,
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
              onPressed: () => onDelete(song),
            ),
          ),
        );
      },
    );
  }
}

class _SongPlaceholder extends StatelessWidget {
  const _SongPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF811F1A), Color(0xFF4B39EF)],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
