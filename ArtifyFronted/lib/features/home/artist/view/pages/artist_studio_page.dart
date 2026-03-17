import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/studio_album_tab.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/studio_profile_tab.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/studio_song_tab.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/album/viewmodel/album_viewmodel.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistStudioPage extends ConsumerStatefulWidget {
  const ArtistStudioPage({super.key});

  @override
  ConsumerState<ArtistStudioPage> createState() => _ArtistStudioPageState();
}

class _ArtistStudioPageState extends ConsumerState<ArtistStudioPage> {
  final TextEditingController _adminArtistIdController =
      TextEditingController();

  @override
  void dispose() {
    _adminArtistIdController.dispose();
    super.dispose();
  }

  String? _resolveArtistId(UserModel currentUser) {
    if (currentUser.role == UserRole.admin) {
      final target = _adminArtistIdController.text.trim();
      return target.isEmpty ? null : target;
    }
    return currentUser.artistId;
  }

  Future<void> _deleteSong(String songId) async {
    await ref.read(songViewModelProvider.notifier).deleteSong(songId: songId);

    final state = ref.read(songViewModelProvider);
    if (state?.hasError == true) {
      if (!mounted) return;
      showSnackBar(context, state!.error.toString());
      return;
    }

    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser != null) {
      final artistId = _resolveArtistId(currentUser);
      if (artistId != null) {
        ref.invalidate(getArtistProvider(artistId));
      }
    }

    ref.invalidate(getAllSongsProvider);

    if (!mounted) return;
    showSnackBar(context, 'Song deleted successfully.');
  }

  Future<void> _deleteAlbum(String albumId) async {
    await ref.read(albumViewModelProvider.notifier).deleteAlbum(albumId);

    final state = ref.read(albumViewModelProvider);
    if (state?.hasError == true) {
      if (!mounted) return;
      showSnackBar(context, state!.error.toString());
      return;
    }

    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser != null) {
      final artistId = _resolveArtistId(currentUser);
      if (artistId != null) {
        ref.invalidate(getArtistProvider(artistId));
      }
    }

    ref.invalidate(getAllAlbumsProvider);

    if (!mounted) return;
    showSnackBar(context, 'Album deleted successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserNotifierProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Loader()),
      );
    }

    final role = currentUser.role;
    final isUserOnly = role == UserRole.user;
    final resolvedArtistId = _resolveArtistId(currentUser);

    final targetArtistAsync = resolvedArtistId == null
        ? null
        : ref.watch(getArtistProvider(resolvedArtistId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Artist Studio',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Pallete.gradient1,
                        Pallete.gradient2,
                        Pallete.gradient3,
                      ],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.library_music_rounded),
                      text: 'Songs',
                    ),
                    Tab(
                      icon: Icon(Icons.album_rounded),
                      text: 'Albums',
                    ),
                    Tab(
                      icon: Icon(Icons.manage_accounts_rounded),
                      text: 'Artist profile',
                    ),
                  ],
                ),
              ),
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
          child: isUserOnly
              ? const _StudioForbiddenState()
              : Column(
                  children: [
                    if (role == UserRole.admin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 920),
                            child: StudioSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const StudioSectionTitle(
                                      'Admin target artist'),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Pick the artist entity you want to manage. All uploads and edits below will be applied to that artist.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: StudioTextField(
                                          controller: _adminArtistIdController,
                                          label: 'Target artist id',
                                          hint: 'Paste the artist id',
                                          icon: Icons
                                              .admin_panel_settings_outlined,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        height: 54,
                                        child: OutlinedButton.icon(
                                          onPressed: () => setState(() {}),
                                          icon:
                                              const Icon(Icons.refresh_rounded),
                                          label: const Text('Load'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          StudioSongTab(
                            currentUser: currentUser,
                            resolvedArtistId: resolvedArtistId,
                            targetArtistAsync: targetArtistAsync,
                          ),
                          StudioAlbumTab(
                            currentUser: currentUser,
                            resolvedArtistId: resolvedArtistId,
                            targetArtistAsync: targetArtistAsync,
                          ),
                          StudioProfileTab(
                            currentUser: currentUser,
                            resolvedArtistId: resolvedArtistId,
                            targetArtistAsync: targetArtistAsync,
                            onDeleteSong: _deleteSong,
                            onDeleteAlbum: _deleteAlbum,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StudioForbiddenState extends StatelessWidget {
  const _StudioForbiddenState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Pallete.surfacePrimary.withOpacity(0.78),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Pallete.primary.withOpacity(0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Studio access unavailable',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This area is reserved for artists and admins. Listener accounts cannot publish or manage catalog content.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}