import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class ArtifyBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final double height;

  const ArtifyBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.height = 68,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050509),
            Color(0xFF120A1B),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 24,
            offset: const Offset(0, -8),
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
            currentIndex: selectedIndex,
            onTap: onItemSelected,
            selectedItemColor: Pallete.whiteColor,
            unselectedItemColor: Pallete.inactiveBottomBarItemColor,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            showUnselectedLabels: true,
            items: [
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
              BottomNavigationBarItem(
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
            ],
          ),
        ),
      ),
    );
  }
}
