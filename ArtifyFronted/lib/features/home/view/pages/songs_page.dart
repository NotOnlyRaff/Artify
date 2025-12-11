// lib/features/home/song/view/pages/songs_page.dart

import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/features/home/song/viewmodel/song_viewmodel.dart';
import 'package:client/features/home/song/widget/songPage/latest_today_section.dart';
import 'package:client/features/home/song/widget/songPage/recently_played_section.dart';
import 'package:client/features/home/song/widget/songPage/songs_header.dart';
import 'package:client/features/home/song/widget/songPage/songs_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SongsPage extends ConsumerWidget {
  const SongsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayed =
        ref.watch(songViewModelProvider.notifier).getRecentlyPlayedSongs();
    final currentSong = ref.watch(currentSongNotifierProvider);
    final currentUser = ref.watch(currentUserNotifierProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: currentSong == null
          ? const BoxDecoration(color: Colors.transparent)
          : const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF241A3B),
                  Colors.transparent,
                ],
                stops: [0.0, 0.4],
              ),
            ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SongsHeader(userName: currentUser?.name),
            const SizedBox(height: 24),
            if (recentlyPlayed.isNotEmpty) ...[
              const SongsSectionTitle(title: 'Recently played'),
              const SizedBox(height: 12),
              RecentlyPlayedSection(songs: recentlyPlayed),
              const SizedBox(height: 24),
            ],
            const SongsSectionTitle(title: 'Latest today'),
            const SizedBox(height: 12),
            const LatestTodaySection(),
          ],
        ),
      ),
    );
  }
}
