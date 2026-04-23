import 'dart:ui';

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';

class ArtifyBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final UserRole role;
  final double height;

  const ArtifyBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.role,
    this.height = 68,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get canAccessStudio => role == UserRole.admin || role == UserRole.artist;

  List<BottomNavigationBarItem> _buildItems() {
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/home_unfilled.png',
          height: 24,
          color: Pallete.inactiveBottomBarItemColor,
        ),
        activeIcon: Image.asset(
          'assets/images/home_filled.png',
          height: 24,
          color: Pallete.whiteColor,
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/search_unfilled.png',
          height: 24,
          color: Pallete.inactiveBottomBarItemColor,
        ),
        activeIcon: Image.asset(
          'assets/images/search_filled.png',
          height: 24,
          color: Pallete.whiteColor,
        ),
        label: 'Search',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/library.png',
          height: 24,
          color: Pallete.inactiveBottomBarItemColor,
        ),
        activeIcon: Image.asset(
          'assets/images/library.png',
          height: 24,
          color: Pallete.whiteColor,
        ),
        label: 'Library',
      ),
    ];

    if (canAccessStudio) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(
            Icons.queue_music_outlined,
            size: 24,
            color: Pallete.inactiveBottomBarItemColor,
          ),
          activeIcon: Icon(
            Icons.queue_music_rounded,
            size: 24,
            color: Pallete.whiteColor,
          ),
          label: 'Studio',
        ),
      );
    }

    if (isAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(
            Icons.admin_panel_settings_outlined,
            size: 24,
            color: Pallete.inactiveBottomBarItemColor,
          ),
          activeIcon: Icon(
            Icons.admin_panel_settings,
            size: 24,
            color: Pallete.whiteColor,
          ),
          label: 'Admin',
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final safeIndex = selectedIndex >= items.length ? 0 : selectedIndex;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xE604050E),
                Color(0xE60A0E1A),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.32),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: height,
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                currentIndex: safeIndex,
                onTap: onItemSelected,
                selectedItemColor: Pallete.whiteColor,
                unselectedItemColor: Pallete.inactiveBottomBarItemColor,
                selectedFontSize: 12,
                unselectedFontSize: 11,
                showUnselectedLabels: true,
                items: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
