// lib/features/home/song/view/pages/songs_page.dart

import 'package:client/features/auth/providers/current_user_notifier.dart';
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
    final currentUser = ref.watch(currentUserNotifierProvider);

    // currentSong non serve più per il background
    // final currentSong = ref.watch(currentSongNotifierProvider);

    return SingleChildScrollView(
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
    );
  }
}
