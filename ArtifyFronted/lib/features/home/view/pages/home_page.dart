import 'package:client/features/home/view/pages/admin_page.dart';
import 'package:client/features/home/view/pages/library_page.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:client/features/home/view/widgets/music_slab.dart';
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
      backgroundColor: Colors.black,
      extendBody: true,
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
          top: true,
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: pages[_selectedIndex],
                ),
              ),
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
