import 'package:client/features/auth/models/user_model.dart';
import 'package:client/features/auth/view/widgets/user_profile_shared.dart';
import 'package:flutter/material.dart';

class UserProfileAccountInfoCard extends StatelessWidget {
  final UserModel user;

  const UserProfileAccountInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileSectionTitle('Account metadata'),
          const SizedBox(height: 14),
          ProfileInfoRow('Role', user.role.name.toUpperCase()),
          ProfileInfoRow(
            'Artist ID',
            user.artistId?.isNotEmpty == true
                ? user.artistId!
                : 'No linked artist profile',
          ),
          ProfileInfoRow('Favorites', '${user.favorites.length} saved tracks'),
        ],
      ),
    );
  }
}
