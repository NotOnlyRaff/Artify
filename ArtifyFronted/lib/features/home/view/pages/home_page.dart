import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/core/widgets/artify_bottom_nav.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/artist/view/pages/artist_studio_page.dart';
import 'package:client/features/home/view/pages/admin_page.dart';
import 'package:client/features/home/view/pages/library_page.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:client/features/auth/view/pages/user_profile_page.dart';
import 'package:client/features/home/view/widgets/music_slab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const double _bottomNavHeight = 68;
  static const double _musicSlabPaddingBottom = 12;

  List<Widget> _buildPages(UserRole role) {
    final pages = <Widget>[
      const SongsPage(),
      const SearchPage(),
      const LibraryPage(),
    ];

    if (role == UserRole.artist || role == UserRole.admin) {
      pages.add(const ArtistStudioPage());
    }

    if (role == UserRole.admin) {
      pages.add(const AdminPage());
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserNotifierProvider);
    final role = currentUser?.role ?? UserRole.user;

    final pages = _buildPages(role);
    final safeIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    if (safeIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = safeIndex;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        _ProfileAvatarButton(user: currentUser),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutExpo,
                      switchOutCurve: Curves.easeInExpo,
                      child: KeyedSubtree(
                        key: ValueKey<int>(safeIndex),
                        child: pages[safeIndex],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: _bottomNavHeight + _musicSlabPaddingBottom + 8,
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: _bottomNavHeight + _musicSlabPaddingBottom,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: MusicSlab(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ArtifyBottomNav(
        selectedIndex: safeIndex,
        height: _bottomNavHeight,
        role: role,
        onItemSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  final UserModel? user;

  const _ProfileAvatarButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(user?.name);
    final imageUrl = user?.image_url; // se nel tuo model è imageUrl, cambia qui

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UserProfilePage(),
          ),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient + initials fallback
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6D28D9),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // Immagine profilo se disponibile
            if (imageUrl != null && imageUrl.trim().isNotEmpty)
              ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox.shrink();
                  },
                ),
              ),

            // Border sopra l'immagine
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'
        .toUpperCase();
  }
}
