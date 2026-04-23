import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/view/widgets/user_profile_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileHeroCard extends StatelessWidget {
  final UserModel user;
  final bool isLoading;
  final VoidCallback onAvatarTap;

  const UserProfileHeroCard({
    super.key,
    required this.user,
    required this.isLoading,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = buildUserInitials(user.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Pallete.surfacePrimary.withOpacity(0.76),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Pallete.primary.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isLoading ? null : onAvatarTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: user.image_url == null
                        ? const LinearGradient(
                            colors: [
                              Pallete.gradient1,
                              Pallete.gradient2,
                              Pallete.gradient3,
                            ],
                          )
                        : null,
                    image: user.image_url != null
                        ? DecorationImage(
                            image: NetworkImage(user.image_url!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                    ),
                  ),
                  child: user.image_url == null
                      ? Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Pallete.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RoleChip(role: user.role),
                    if (user.artistId?.isNotEmpty == true) const ArtistChip(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
