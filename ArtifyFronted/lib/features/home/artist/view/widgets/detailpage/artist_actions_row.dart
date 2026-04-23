import 'dart:math';

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/detailpage/artist_song_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistActionsRow extends ConsumerStatefulWidget {
  final ArtistModel artist;

  const ArtistActionsRow({super.key, required this.artist});

  @override
  ConsumerState<ArtistActionsRow> createState() => _ArtistActionsRowState();
}

class _ArtistActionsRowState extends ConsumerState<ArtistActionsRow> {
  bool _loadingPlay = false;
  bool _loadingShuffle = false;

  Future<void> _playRef(ArtistSongRef songRef, {bool isShuffle = false}) async {
    if (isShuffle) {
      setState(() => _loadingShuffle = true);
    } else {
      setState(() => _loadingPlay = true);
    }

    try {
      await playArtistSongRef(
        context: context,
        ref: ref,
        songRef: songRef,
        queueRefs: widget.artist.songs,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingPlay = false;
          _loadingShuffle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.artist.songs;
    final hasSongs = songs.isNotEmpty;
    final isLoading = _loadingPlay || _loadingShuffle;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                hasSongs && !isLoading ? () => _playRef(songs.first) : null,
            icon: _loadingPlay
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              'Play top track',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.gradient2,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withOpacity(0.08),
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: hasSongs && !isLoading
              ? () {
                  final randomRef = songs[Random().nextInt(songs.length)];
                  _playRef(randomRef, isShuffle: true);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.08),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withOpacity(0.05),
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: _loadingShuffle
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
              : const Icon(Icons.shuffle_rounded, size: 20),
        ),
      ],
    );
  }
}
