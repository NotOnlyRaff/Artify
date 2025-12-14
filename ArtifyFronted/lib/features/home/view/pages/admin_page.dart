import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';

// SONG admin
import 'package:client/features/home/admin/view/pages/song/upload_song_page.dart';
import 'package:client/features/home/admin/view/pages/song/delete_song_page.dart';

// ARTIST admin
import 'package:client/features/home/admin/view/pages/artist/upload_artist_page.dart';
import 'package:client/features/home/admin/view/pages/artist/delete_artist_page.dart';

// ALBUM admin
import 'package:client/features/home/admin/view/pages/album/upload_album_page.dart';
import 'package:client/features/home/admin/view/pages/album/delete_album_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(getAllSongsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildAdminBadge(),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                Text(
                  'Songs overview',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: songsAsync.when(
                    data: (songs) => _buildSongList(context, songs),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER -------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEF4444),
                Color(0xFF4B39EF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin console',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage songs, artists and albums.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.red.withOpacity(0.12),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 6),
          Text(
            'Admin mode • Changes affect the whole system',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.red[100],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // QUICK ACTIONS ------------------------------------------------------------
  // → 3 card (Songs, Artists, Albums) su un’unica riga, scrollabile orizzontalmente.

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 150, // altezza fissa per le card admin
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // SONGS
          SizedBox(
            width: 260,
            child: _AdminActionCard(
              title: 'Songs',
              subtitle: 'Create, delete & review tracks',
              icon: Icons.library_music_rounded,
              accent: Pallete.gradient2,
              actions: [
                _InlineActionButton(
                  label: 'Upload',
                  icon: Icons.add_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UploadSongPage(),
                      ),
                    );
                  },
                ),
                _InlineActionButton(
                  label: 'Delete',
                  icon: Icons.delete_rounded,
                  isDanger: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeleteSongPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ARTISTS
          SizedBox(
            width: 260,
            child: _AdminActionCard(
              title: 'Artists',
              subtitle: 'Create, edit & remove artists',
              icon: Icons.person_rounded,
              accent: const Color(0xFF22C55E),
              actions: [
                _InlineActionButton(
                  label: 'Add',
                  icon: Icons.person_add_alt_1_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UploadArtistPage(),
                      ),
                    );
                  },
                ),
                _InlineActionButton(
                  label: 'Delete',
                  icon: Icons.person_remove_rounded,
                  isDanger: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeleteArtistPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ALBUMS
          SizedBox(
            width: 260,
            child: _AdminActionCard(
              title: 'Albums',
              subtitle: 'Create, link & delete albums',
              icon: Icons.album_rounded,
              accent: const Color(0xFFF97316), // arancio caldo
              actions: [
                _InlineActionButton(
                  label: 'New album',
                  icon: Icons.add_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UploadAlbumPage(),
                      ),
                    );
                  },
                ),
                _InlineActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  isDanger: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeleteAlbumPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SONG LIST ----------------------------------------------------------------

  Widget _buildSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Text(
          'No songs found in the catalogue.\nUpload your first track from the Songs panel.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongTile(context, song);
      },
    );
  }

  Widget _buildSongTile(BuildContext context, SongModel song) {
    final artist = song.artists.isNotEmpty
        ? song.artists.map((a) => a.artistName).join(', ')
        : 'Unknown Artist';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            song.thumbnailUrl ??
                'https://via.placeholder.com/150?text=No+Image',
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
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
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
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
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white60,
            size: 20,
          ),
          onPressed: () {
            // TODO: bottom sheet admin:
            // - Edit song metadata
            // - Remove from catalogue
            // - View in library
          },
        ),
        onTap: () {
          // TODO: apri SongAdminDetailPage in futuro
        },
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_InlineActionButton> actions;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.28),
            const Color(0xFF050509),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // evita problemi con height non finita
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDanger;
  final VoidCallback onTap;

  const _InlineActionButton({
    required this.label,
    required this.icon,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = isDanger ? Colors.redAccent : Pallete.gradient2;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: baseColor.withOpacity(0.14),
          border: Border.all(
            color: baseColor.withOpacity(0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
