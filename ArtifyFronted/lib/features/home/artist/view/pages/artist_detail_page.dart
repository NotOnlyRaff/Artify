import 'dart:ui';

import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistDetailPage extends ConsumerWidget {
  final String artistId;

  const ArtistDetailPage({
    super.key,
    required this.artistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(getArtistProvider(artistId));

    return Container(
      // Sfondo “cosmico” per tutto lo screen
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF050509),
            Color(0xFF060317),
            Color(0xFF140832),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            'Artist profile',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              onPressed: () {
                // TODO: azioni extra (edit artist, share, ecc.)
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: artistAsync.when(
            data: (artist) => _ArtistDetailBody(artist: artist),
            loading: () => const Center(child: Loader()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtistDetailBody extends StatelessWidget {
  final ArtistModel artist;

  const _ArtistDetailBody({
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final songs = artist.songs;
    final albums = artist.albums;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CosmicHeader(artist: artist),
          const SizedBox(height: 26),
          _ArtistActionsRow(artist: artist),
          const SizedBox(height: 24),

          // Cosmic stats
          _CosmicStatsRow(artist: artist),
          const SizedBox(height: 28),

          // Top songs
          if (songs.isNotEmpty) ...[
            const _SectionTitle('Top songs'),
            const SizedBox(height: 10),
            ...songs.take(8).toList().asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SongRow(
                      index: entry.key + 1,
                      song: entry.value,
                      artistName: artist.displayName?.isNotEmpty == true
                          ? artist.displayName!
                          : artist.name,
                    ),
                  ),
                ),
            const SizedBox(height: 28),
          ],

          // Albums
          if (albums.isNotEmpty) ...[
            const _SectionTitle('Discography in orbit'),
            const SizedBox(height: 14),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return _AlbumCard(album: album);
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          // About / bio
          if ((artist.bio ?? '').trim().isNotEmpty) ...[
            const _SectionTitle('About this entity'),
            const SizedBox(height: 10),
            _AboutSection(artist: artist),
          ],
        ],
      ),
    );
  }
}

/// HEADER “COSMICO” -----------------------------------------------------------
class _CosmicHeader extends StatelessWidget {
  final ArtistModel artist;

  const _CosmicHeader({required this.artist});

  @override
  Widget build(BuildContext context) {
    final displayName = artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;

    final subtitleParts = <String>[];
    if (artist.slug != null && artist.slug!.isNotEmpty) {
      subtitleParts.add('@${artist.slug}');
    }
    if (artist.country != null && artist.country!.isNotEmpty) {
      subtitleParts.add(artist.country!);
    }
    final subtitle = subtitleParts.join(' • ');

    final songCount = artist.songs.length;
    final albumCount = artist.albums.length;

    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // Glow / nebulosa dietro
          Positioned.fill(
            child: CustomPaint(
              painter: _NebulaPainter(),
            ),
          ),

          // Piccoli “stars”
          const Positioned(
            top: 18,
            right: 26,
            child: _StarDot(size: 5),
          ),
          const Positioned(
            top: 60,
            left: 12,
            child: _StarDot(size: 3),
          ),
          const Positioned(
            bottom: 22,
            right: 80,
            child: _StarDot(size: 4),
          ),

          // Card glassmorphism
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 22,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _CosmicAvatar(
                          displayName: displayName, imageUrl: artist.imageUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (artist.slug != null &&
                                    artist.slug!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF60A5FA),
                                          Color(0xFFA855F7),
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.rocket_launch_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified entity',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _ChipStat(
                                  icon: Icons.music_note_rounded,
                                  label:
                                      '$songCount track${songCount == 1 ? '' : 's'} in orbit',
                                ),
                                _ChipStat(
                                  icon: Icons.album_rounded,
                                  label:
                                      '$albumCount album${albumCount == 1 ? '' : 's'} in catalog',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CosmicAvatar extends StatelessWidget {
  final String displayName;
  final String? imageUrl;

  const _CosmicAvatar({
    required this.displayName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    Widget avatarCore;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarCore = ClipOval(
        child: Image.network(
          imageUrl!,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(initial),
        ),
      );
    } else {
      avatarCore = _fallback(initial);
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF60A5FA),
            Color(0xFFA855F7),
            Color(0xFFF97316),
            Color(0xFF60A5FA),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF050509),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF60A5FA).withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: avatarCore,
      ),
    );
  }

  Widget _fallback(String initial) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF4B39EF),
            Color(0xFF18181B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StarDot extends StatelessWidget {
  final double size;

  const _StarDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE5E7EB),
      ),
    );
  }
}

/// Piccola nebulosa pitturata per lo sfondo header
class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.2, size.height * 0.1);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF8B5CF6),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 140));

    canvas.drawCircle(center, 140, paint);

    final center2 = Offset(size.width * 0.8, size.height * 0.8);
    final paint2 = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF22D3EE),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center2, radius: 160));
    canvas.drawCircle(center2, 160, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChipStat extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ChipStat({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.35),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// RIGA STATISTICHE -----------------------------------------------------------
class _CosmicStatsRow extends StatelessWidget {
  final ArtistModel artist;

  const _CosmicStatsRow({required this.artist});

  @override
  Widget build(BuildContext context) {
    final firstRelease = [
      ...artist.songs.map((s) => s.releaseDate),
      ...artist.albums.map((a) => a.releaseDate).whereType<DateTime>(),
    ];
    firstRelease.removeWhere((d) => d == null);

    String? sinceYear;
    if (firstRelease.isNotEmpty) {
      firstRelease.sort((a, b) => a!.compareTo(b!));
      sinceYear = firstRelease.first!.year.toString();
    }

    final totalTracks = artist.songs.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              _StatTile(
                label: 'Tracks in catalog',
                value: totalTracks.toString(),
              ),
              const SizedBox(width: 12),
              if (sinceYear != null)
                _StatTile(
                  label: 'Active since',
                  value: sinceYear,
                ),
              const Spacer(),
              if (artist.country != null && artist.country!.isNotEmpty)
                _StatTile(
                  label: 'Origin',
                  value: artist.country!,
                  alignRight: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _StatTile({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// ACTIONS --------------------------------------------------------------------
class _ArtistActionsRow extends StatelessWidget {
  final ArtistModel artist;

  const _ArtistActionsRow({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Play
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: integra col player (play tutta la discografia / top songs)
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              'Play artist',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.gradient2,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Radio / shuffle
        ElevatedButton(
          onPressed: () {
            // TODO: shuffle discografia
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.07),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Icon(Icons.shuffle_rounded, size: 20),
        ),
      ],
    );
  }
}

/// SECTION TITLE --------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFA855F7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// SONG ROW -------------------------------------------------------------------
class _SongRow extends StatelessWidget {
  final int index;
  final SongModel song;
  final String artistName;

  const _SongRow({
    required this.index,
    required this.song,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final title = song.songName.isNotEmpty ? song.songName : 'Untitled track';
    final durationLabel = song.durationSeconds != null
        ? _formatDuration(song.durationSeconds!)
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // TODO: integra col currentSongNotifier e player
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.02),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                index.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song.thumbnailUrl ??
                    'https://via.placeholder.com/150?text=Track',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4B39EF),
                        Color(0xFF111827),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (durationLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                durationLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: Colors.white54,
              ),
              onPressed: () {
                // TODO: sheet con azioni (add to playlist, fav, share, ecc.)
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

// ALBUM CARD -----------------------------------------------------------------
class _AlbumCard extends StatelessWidget {
  final AlbumModel album;

  const _AlbumCard({
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final year = album.releaseDate?.year.toString();
    final subtitleParts = <String>[];

    if (album.albumType != null && album.albumType!.isNotEmpty) {
      final t = album.albumType!;
      subtitleParts.add('${t[0].toUpperCase()}${t.substring(1)}');
    }
    if (year != null) {
      subtitleParts.add(year);
    }
    if (album.label != null && album.label!.isNotEmpty) {
      subtitleParts.add(album.label!);
    }
    final subtitle = subtitleParts.join(' • ');

    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: naviga a AlbumDetailPage se/quando esisterà
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      album.coverUrl ??
                          'https://via.placeholder.com/300?text=Album',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4B39EF),
                              Color(0xFF111827),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.album_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    // gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.45),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Icon(
                          Icons.album_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ABOUT SECTION --------------------------------------------------------------
class _AboutSection extends StatelessWidget {
  final ArtistModel artist;

  const _AboutSection({
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final bio = (artist.bio ?? '').trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            bio,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
