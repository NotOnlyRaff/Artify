import 'package:client/features/home/view/widgets/music_slab.dart';
import 'package:client/features/home/view/pages/admin_page.dart';
import 'package:client/features/home/view/pages/library_page.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:client/core/widgets/artify_bottom_nav.dart';
import 'package:client/features/home/view/widgets/space_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import nuovo sfondo
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const double _bottomNavHeight = 68;
  static const double _musicSlabPaddingBottom = 12;

  final pages = const [
    SongsPage(),
    SearchPage(),
    LibraryPage(),
    AdminPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 🌌 NUOVO BACKGROUND DINAMICO
          const Positioned.fill(child: SpaceBackground()),

          // 🪐 CONTENT + MUSIC SLAB + NAV
          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              child: Stack(
                children: [
                  // page content
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutExpo,
                      switchOutCurve: Curves.easeInExpo,
                      child: pages[_selectedIndex],
                    ),
                  ),

                  // music slab fisso
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _bottomNavHeight + _musicSlabPaddingBottom,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: MusicSlab(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // bottom navigation
      bottomNavigationBar: ArtifyBottomNav(
        selectedIndex: _selectedIndex,
        height: _bottomNavHeight,
        onItemSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
    );
  }
}
