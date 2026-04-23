import 'package:client/features/auth/providers/current_user_notifier.dart';
import 'package:client/core/widgets/artify_bottom_nav.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/artist/view/pages/artist_studio_page.dart';
import 'package:client/features/home/view/pages/admin_page.dart';
import 'package:client/features/home/view/pages/library_page.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:client/core/widgets/profile_avatar_button.dart';
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

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isKeyboardOpen
                    ? _bottomNavHeight + 8
                    : _bottomNavHeight + _musicSlabPaddingBottom + 8,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutExpo,
                switchOutCurve: Curves.easeInExpo,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(safeIndex),
                  child: pages[safeIndex],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.topRight,
                child: ProfileAvatarButton(user: currentUser),
              ),
            ),
          ),
          if (!isKeyboardOpen)
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
