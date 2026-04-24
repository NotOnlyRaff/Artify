// lib/features/home/song/widget/searchPage/search_filter_chips.dart
//
// Chip di filtro in cima alla search page. Permettono di restringere i
// risultati a una sola categoria (Songs/Artists/Albums) o mostrare tutto.

import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SearchFilter {
  all,
  songs,
  artists,
  albums;

  String get label {
    switch (this) {
      case SearchFilter.all:
        return 'All';
      case SearchFilter.songs:
        return 'Songs';
      case SearchFilter.artists:
        return 'Artists';
      case SearchFilter.albums:
        return 'Albums';
    }
  }
}

class SearchFilterChips extends StatelessWidget {
  final SearchFilter current;
  final ValueChanged<SearchFilter> onChanged;

  const SearchFilterChips({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: SearchFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = SearchFilter.values[index];
          final isActive = filter == current;
          return _FilterChip(
            label: filter.label,
            active: isActive,
            onTap: () => onChanged(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Pallete.gradient2,
                      Color(0xFF811F1A),
                    ],
                  )
                : null,
            color: active ? null : Colors.white.withOpacity(0.06),
            border: Border.all(
              color:
                  active ? Colors.transparent : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: active ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
