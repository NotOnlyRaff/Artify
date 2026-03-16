import 'package:client/features/auth/view/widgets/user_profile_shared.dart';
import 'package:flutter/material.dart';

class UserProfileFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;

  const UserProfileFormCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCardShell(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileSectionTitle('Profile details'),
            const SizedBox(height: 14),
            ProfileTextField(
              controller: nameController,
              label: 'Display name',
              hint: 'Your public name',
              icon: Icons.person_outline_rounded,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            ProfileTextField(
              controller: emailController,
              label: 'Email',
              hint: 'you@artify.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}
