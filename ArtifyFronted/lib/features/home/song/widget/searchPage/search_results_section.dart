import 'package:client/features/home/artist/view/pages/artist_detail_page.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchResultsSection extends StatelessWidget {
  final List<SongModel> songs;
  final List<ArtistModel> artists;
  final List<AlbumModel> albums;
  final String query;

  const SearchResultsSection({
    super.key,
    required this.songs,
    required this.artists,
    required this.albums,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();

    // SONGS: filtro locale su titolo + artisti
    final songMatches = songs.where((song) {
      final titleMatch = song.songName.toLowerCase().contains(q);

      final artistMatch = song.artists.any(
        (a) => a.artistName?.toLowerCase().contains(q) == true,
      );

      return titleMatch || artistMatch;
    }).toList();

    // ARTISTS: se il backend usa già search, sarà comunque un sottoinsieme
    final artistMatches = artists.where((artist) {
      final name = artist.name.toLowerCase();
      final display = (artist.displayName ?? '').toLowerCase();
      return name.contains(q) || display.contains(q);
    }).toList();

    // ALBUMS: filtro locale su title + label
    final albumMatches = albums.where((album) {
      final title = album.title.toLowerCase();
      final label = (album.label ?? '').toLowerCase();
      return title.contains(q) || label.contains(q);
    }).toList();

    final hasAnyResult = songMatches.isNotEmpty ||
        artistMatches.isNotEmpty ||
        albumMatches.isNotEmpty;

    if (!hasAnyResult) {
      return Center(
        child: Text(
          'No results found for "$query".',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        if (songMatches.isNotEmpty) ...[
          const _SectionTitle('Songs'),
          const SizedBox(height: 8),
          ...songMatches.map((s) => _SongResultTile(song: s)),
          const SizedBox(height: 24),
        ],
        if (artistMatches.isNotEmpty) ...[
          const _SectionTitle('Artists'),
          const SizedBox(height: 8),
          ...artistMatches.map((a) => _ArtistResultTile(artist: a)),
          const SizedBox(height: 24),
        ],
        if (albumMatches.isNotEmpty) ...[
          const _SectionTitle('Albums'),
          const SizedBox(height: 8),
          ...albumMatches.map((a) => _AlbumResultTile(album: a)),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// SONG TILE -----------------------------------------------------------------
class _SongResultTile extends StatelessWidget {
  final SongModel song;

  const _SongResultTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final artist = song.artists.isNotEmpty
        ? song.artists.map((a) => a.artistName).join(', ')
        : 'Unknown artist';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            song.thumbnailUrl ??
                'https://via.placeholder.com/150?text=No+Image',
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF811F1A),
                    Color(0xFF4B39EF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        title: Text(
          song.songName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white70,
        ),
        onTap: () {
          // TODO: apri player / dettaglio canzone
        },
      ),
    );
  }
}

/// ARTIST TILE ---------------------------------------------------------------
class _ArtistResultTile extends StatelessWidget {
  final ArtistModel artist;

  const _ArtistResultTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    final displayName = artist.displayName ?? artist.name;
    final subtitle = artist.country ?? 'Artist';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.06),
            backgroundImage:
                artist.imageUrl != null ? NetworkImage(artist.imageUrl!) : null,
            child: artist.imageUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white70,
                  )
                : null,
          ),
          title: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.white54,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArtistDetailPage(artistId: artist.id),
              ),
            );
          }),
    );
  }
}

/// ALBUM TILE ----------------------------------------------------------------
class _AlbumResultTile extends StatelessWidget {
  final AlbumModel album;

  const _AlbumResultTile({required this.album});

  @override
  Widget build(BuildContext context) {
    final year = album.releaseDate?.year.toString();
    final type = album.albumType ?? 'Album';
    final subtitle = [
      type[0].toUpperCase() + type.substring(1),
      if (year != null) year,
      if (album.label != null && album.label!.isNotEmpty) album.label!,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            album.coverUrl ?? 'https://via.placeholder.com/150?text=Album',
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 46,
              height: 46,
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
                Icons.album_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        title: Text(
          album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.white54,
        ),
        onTap: () {
          // TODO: apri pagina dettaglio album
        },
      ),
    );
  }
}
