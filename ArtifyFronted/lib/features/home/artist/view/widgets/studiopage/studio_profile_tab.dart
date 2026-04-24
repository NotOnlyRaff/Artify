import 'package:client/core/utils.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/pages/artist_album_edit_page.dart';
import 'package:client/features/home/artist/view/pages/artist_song_edit_page.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

/// FIX: rimossi import di SongModel e AlbumModel — non più necessari.
/// Le tile del catalogo ora usano ArtistSongRef e ArtistAlbumRef
/// (i tipi reali di artist.songs e artist.albums dopo la migrazione del model).

class StudioProfileTab extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final String? resolvedArtistId;
  final AsyncValue<ArtistModel>? targetArtistAsync;
  final Future<void> Function(String songId)? onDeleteSong;
  final Future<void> Function(String albumId)? onDeleteAlbum;

  const StudioProfileTab({
    super.key,
    required this.currentUser,
    required this.resolvedArtistId,
    required this.targetArtistAsync,
    required this.onDeleteSong,
    required this.onDeleteAlbum,
  });

  @override
  ConsumerState<StudioProfileTab> createState() => _StudioProfileTabState();
}

class _StudioProfileTabState extends ConsumerState<StudioProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();

  bool _seeded = false;
  bool _saving = false;
  PickedMedia? _newArtistImage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _slugController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _seedFromArtist(ArtistModel artist) {
    if (_seeded) return;
    _displayNameController.text = artist.displayName ?? '';
    _slugController.text = artist.slug ?? '';
    _countryController.text = artist.country ?? '';
    _bioController.text = artist.bio ?? '';
    _seeded = true;
  }

  Future<void> _pickArtistImage() async {
    final picked = await pickImage();
    if (!mounted) return;
    if (picked != null) setState(() => _newArtistImage = picked);
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _saveProfile(ArtistModel artist) async {
    if (!_formKey.currentState!.validate()) {
      showSnackBar(context, 'Complete the artist profile form first.');
      return;
    }

    setState(() => _saving = true);

    try {
      String? newImageUrl = artist.imageUrl;

      if (_newArtistImage != null) {
        final uploadRes = await ref
            .read(artistViewModelProvider.notifier)
            .uploadArtistImage(image: _newArtistImage!);

        switch (uploadRes) {
          case Left(value: final failure):
            if (mounted) showSnackBar(context, failure.message);
            return;
          case Right(value: final uploadedUrl):
            newImageUrl = uploadedUrl;
        }
      }

      await ref.read(artistViewModelProvider.notifier).updateArtist(
            artistId: artist.id,
            displayName: _emptyToNull(_displayNameController.text),
            slug: _emptyToNull(_slugController.text),
            imageUrl: newImageUrl,
            bio: _emptyToNull(_bioController.text),
            country: _emptyToNull(_countryController.text),
          );

      if (!mounted) return;

      final state = ref.read(artistViewModelProvider);
      if (state?.hasError == true) {
        showSnackBar(context, state!.error.toString());
        return;
      }

      ref.invalidate(getArtistProvider(artist.id));
      showSnackBar(context, 'Artist profile updated successfully.');
      setState(() => _newArtistImage = null);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDelete(
      {required String title, required String body}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF140813),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        content: Text(body,
            style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final targetArtistAsync = widget.targetArtistAsync;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StudioHeroCard(
                icon: Icons.manage_accounts_rounded,
                title: 'Manage artist identity',
                subtitle:
                    'Update public artist metadata, artwork and review your catalog.',
              ),
              const SizedBox(height: 20),
              if (widget.resolvedArtistId == null)
                const StudioSectionCard(
                  child: Text(
                    'Select or load an artist first.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else if (targetArtistAsync == null)
                const SizedBox.shrink()
              else
                targetArtistAsync.when(
                  loading: () => const StudioSectionCard(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => StudioSectionCard(
                    child: Text(error.toString(),
                        style: const TextStyle(color: Colors.white70)),
                  ),
                  data: (artist) {
                    _seedFromArtist(artist);

                    return Column(
                      children: [
                        StudioSectionCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const StudioSectionTitle(
                                    'Artist public profile'),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: _pickArtistImage,
                                      child: Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: artist.imageUrl != null &&
                                                  artist.imageUrl!.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      artist.imageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: Colors.white.withOpacity(0.07),
                                        ),
                                        child: artist.imageUrl == null
                                            ? const Icon(
                                                Icons.camera_alt_rounded,
                                                color: Colors.white38)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          StudioTextField(
                                            controller: _displayNameController,
                                            label: 'Display name',
                                            hint: 'Stage name (optional)',
                                            icon: Icons.person_rounded,
                                          ),
                                          const SizedBox(height: 10),
                                          StudioTextField(
                                            controller: _slugController,
                                            label: 'Slug',
                                            hint: 'artist-slug',
                                            icon: Icons.link_rounded,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                StudioTextField(
                                  controller: _countryController,
                                  label: 'Country',
                                  hint: 'Italy, USA...',
                                  icon: Icons.flag_rounded,
                                ),
                                const SizedBox(height: 10),
                                StudioTextField(
                                  controller: _bioController,
                                  label: 'Bio',
                                  hint: 'Describe the artist...',
                                  icon: Icons.info_outline_rounded,
                                ),
                                const SizedBox(height: 18),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: _saving
                                        ? null
                                        : () => _saveProfile(artist),
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Icon(Icons.save_rounded,
                                            size: 18),
                                    label: const Text('Save profile'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        StudioSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StudioSectionTitle('Catalog'),
                              const SizedBox(height: 14),

                              // FIX: artist.songs è List<ArtistSongRef>.
                              // _SongCatalogTile aggiornato per accettare ArtistSongRef.
                              _CatalogListSection(
                                title: 'Songs',
                                emptyLabel:
                                    'No songs found for this artist yet.',
                                itemCount: artist.songs.length,
                                itemBuilder: (_, index) {
                                  final songRef = artist.songs[index];
                                  return _SongCatalogTile(
                                    songRef: songRef,
                                    onEdit: () async {
                                      await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => ArtistSongEditPage(
                                            studioArtist: artist,
                                            songId: songRef.songId,
                                          ),
                                        ),
                                      );
                                    },
                                    onDelete: widget.onDeleteSong == null
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await _confirmDelete(
                                              title: 'Delete song?',
                                              body:
                                                  'This will permanently remove "${songRef.songName}" from the catalog.',
                                            );
                                            if (!confirmed) return;
                                            await widget
                                                .onDeleteSong!(songRef.songId);
                                          },
                                  );
                                },
                              ),
                              const SizedBox(height: 18),

                              // FIX: artist.albums è List<ArtistAlbumRef>.
                              // _AlbumCatalogTile aggiornato per accettare ArtistAlbumRef.
                              _CatalogListSection(
                                title: 'Albums',
                                emptyLabel:
                                    'No albums found for this artist yet.',
                                itemCount: artist.albums.length,
                                itemBuilder: (_, index) {
                                  final albumRef = artist.albums[index];
                                  return _AlbumCatalogTile(
                                    albumRef: albumRef,
                                    onEdit: () async {
                                      await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => ArtistAlbumEditPage(
                                            studioArtist: artist,
                                            albumId: albumRef.albumId,
                                          ),
                                        ),
                                      );
                                    },
                                    onDelete: widget.onDeleteAlbum == null
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await _confirmDelete(
                                              title: 'Delete album?',
                                              body:
                                                  'This will permanently remove "${albumRef.title}" from the catalog.',
                                            );
                                            if (!confirmed) return;
                                            await widget.onDeleteAlbum!(
                                                albumRef.albumId);
                                          },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogListSection extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _CatalogListSection({
    required this.title,
    required this.emptyLabel,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (itemCount == 0)
          Text(emptyLabel,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60, fontSize: 12.5))
        else
          ListView.separated(
            itemCount: itemCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: itemBuilder,
          ),
      ],
    );
  }
}

/// FIX: accetta ArtistSongRef invece di SongModel.
/// I campi necessari per la tile (nome, thumbnail, id) sono presenti in ArtistSongRef.
class _SongCatalogTile extends StatelessWidget {
  final ArtistSongRef songRef;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  const _SongCatalogTile({
    required this.songRef,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: songRef.thumbnailUrl?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(songRef.thumbnailUrl!),
                      fit: BoxFit.cover)
                  : null,
              color: Colors.white.withOpacity(0.05),
            ),
            child: songRef.thumbnailUrl == null
                ? const Icon(Icons.music_note_rounded, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              songRef.songName ?? 'Unknown track',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit track',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete track',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}

/// FIX: accetta ArtistAlbumRef invece di AlbumModel.
/// I campi necessari per la tile (titolo, cover, id) sono presenti in ArtistAlbumRef.
class _AlbumCatalogTile extends StatelessWidget {
  final ArtistAlbumRef albumRef;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  const _AlbumCatalogTile({
    required this.albumRef,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: albumRef.coverUrl?.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(albumRef.coverUrl!),
                      fit: BoxFit.cover)
                  : null,
              color: Colors.white.withOpacity(0.05),
            ),
            child: albumRef.coverUrl == null
                ? const Icon(Icons.album_rounded, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              albumRef.title ?? 'Unknown album',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit album',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete album',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}
