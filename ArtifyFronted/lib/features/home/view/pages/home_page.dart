import 'package:client/features/home/view/widgets/music_slab.dart';
import 'package:client/features/home/view/pages/admin_page.dart';
import 'package:client/features/home/view/pages/library_page.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:client/core/widgets/artify_bottom_nav.dart';
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

  final pages = const [
    SongsPage(),
    SearchPage(),
    LibraryPage(),
    AdminPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // importantissimo: niente colore che “sporca” lo sfondo
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [

          // 🪐 CONTENUTO DELLE PAGINE
          Positioned.fill(
            child: Column(
              children: [
                // contenuto principale dentro SafeArea
                Expanded(
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutExpo,
                      switchOutCurve: Curves.easeInExpo,
                      child: pages[_selectedIndex],
                    ),
                  ),
                ),

                // spazio riservato al MusicSlab + nav bar
                const SizedBox(
                  height: _bottomNavHeight + _musicSlabPaddingBottom + 8,
                ),
              ],
            ),
          ),

          // 🎵 MUSIC SLAB SEMPRE SOPRA, NON TOCCA LO SFONDO
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

      // 🚀 BOTTOM NAV
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
