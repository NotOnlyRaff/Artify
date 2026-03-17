import 'package:client/core/utils.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/home/album/model/album_model.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:client/features/home/artist/view/widgets/studiopage/artist_studio_shared.dart';
import 'package:client/features/home/artist/viewmodel/artist_viewmodel.dart';
import 'package:client/features/home/song/model/song_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (picked != null) {
      setState(() => _newArtistImage = picked);
    }
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
        final uploadRes =
            await ref.read(artistViewModelProvider.notifier).uploadArtistImage(
                  image: _newArtistImage!,
                );

        switch (uploadRes) {
          case Left(value: final failure):
            showSnackBar(context, failure.message);
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

      final state = ref.read(artistViewModelProvider);
      if (state?.hasError == true) {
        showSnackBar(context, state!.error.toString());
        return;
      }

      ref.invalidate(getArtistProvider(artist.id));
      showSnackBar(context, 'Artist profile updated successfully.');
      setState(() => _newArtistImage = null);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String body,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF140813),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          content: Text(
            body,
            style: GoogleFonts.plusJakartaSans(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
                    'Update public artist metadata, artwork and review your catalog from one place.',
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
                    child: Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
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
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: artist.imageUrl != null &&
                                                artist.imageUrl!.isNotEmpty
                                            ? DecorationImage(
                                                image:
                                                    NetworkImage(artist.imageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                        gradient: artist.imageUrl == null
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF6D28D9),
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFFEC4899),
                                                ],
                                              )
                                            : null,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: artist.imageUrl == null
                                          ? Center(
                                              child: Text(
                                                (artist.displayName ??
                                                        artist.name)
                                                    .characters
                                                    .first
                                                    .toUpperCase(),
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            artist.displayName ?? artist.name,
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            artist.slug == null
                                                ? 'No public slug yet'
                                                : '@${artist.slug}',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: _pickArtistImage,
                                            icon: const Icon(
                                                Icons.camera_alt_rounded),
                                            label: Text(
                                              _newArtistImage == null
                                                  ? 'Change image'
                                                  : _newArtistImage!.name,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StudioTextField(
                                        controller: _displayNameController,
                                        label: 'Display name',
                                        hint: 'Public artist name',
                                        icon: Icons.badge_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StudioTextField(
                                        controller: _slugController,
                                        label: 'Slug',
                                        hint: 'artist-public-slug',
                                        icon:
                                            Icons.alternate_email_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                StudioTextField(
                                  controller: _countryController,
                                  label: 'Country',
                                  hint: 'Optional country',
                                  icon: Icons.public_rounded,
                                ),
                                const SizedBox(height: 14),
                                StudioTextField(
                                  controller: _bioController,
                                  label: 'Bio',
                                  hint:
                                      'Write a concise artist bio or positioning statement',
                                  icon: Icons.notes_rounded,
                                  minLines: 5,
                                  maxLines: 8,
                                ),
                                const SizedBox(height: 20),
                                StudioPrimaryButton(
                                  loading: _saving,
                                  text: 'Save artist profile',
                                  icon: Icons.save_outlined,
                                  onPressed: () => _saveProfile(artist),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        StudioSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StudioSectionTitle('Catalog overview'),
                              const SizedBox(height: 12),
                              const StudioInfoCallout(
                                title: 'Catalog management',
                                body:
                                    'From here you can review the artist songs and albums already attached to the profile. Delete actions are now wired to the existing song and album viewmodels.',
                              ),
                              const SizedBox(height: 18),
                              _CatalogListSection(
                                title: 'Songs',
                                emptyLabel:
                                    'No songs found for this artist yet.',
                                itemCount: artist.songs.length,
                                itemBuilder: (_, index) {
                                  final song = artist.songs[index];
                                  return _SongCatalogTile(
                                    song: song,
                                    onDelete: widget.onDeleteSong == null
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await _confirmDelete(
                                              title: 'Delete song?',
                                              body:
                                                  'This will permanently remove "${song.songName}" from the catalog.',
                                            );

                                            if (!confirmed) return;
                                            await widget.onDeleteSong!(song.id);
                                          },
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              _CatalogListSection(
                                title: 'Albums',
                                emptyLabel:
                                    'No albums found for this artist yet.',
                                itemCount: artist.albums.length,
                                itemBuilder: (_, index) {
                                  final album = artist.albums[index];
                                  return _AlbumCatalogTile(
                                    album: album,
                                    onDelete: widget.onDeleteAlbum == null
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await _confirmDelete(
                                              title: 'Delete album?',
                                              body:
                                                  'This will permanently remove "${album.title}" from the catalog.',
                                            );

                                            if (!confirmed) return;
                                            await widget.onDeleteAlbum!(
                                                album.id);
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
          Text(
            emptyLabel,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 12.5,
            ),
          )
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

class _SongCatalogTile extends StatelessWidget {
  final SongModel song;
  final Future<void> Function()? onDelete;

  const _SongCatalogTile({
    required this.song,
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
              image: song.thumbnailUrl != null && song.thumbnailUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(song.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.white.withOpacity(0.05),
            ),
            child: song.thumbnailUrl == null
                ? const Icon(Icons.music_note_rounded, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              song.songName,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
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

class _AlbumCatalogTile extends StatelessWidget {
  final AlbumModel album;
  final Future<void> Function()? onDelete;

  const _AlbumCatalogTile({
    required this.album,
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
              image: album.coverUrl != null && album.coverUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(album.coverUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.white.withOpacity(0.05),
            ),
            child: album.coverUrl == null
                ? const Icon(Icons.album_rounded, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              album.title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
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