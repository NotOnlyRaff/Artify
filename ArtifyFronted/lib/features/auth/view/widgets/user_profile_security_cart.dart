import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/auth/view/widgets/user_profile_shared.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileSecurityCard extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final bool passwordVisible;
  final bool isLoading;
  final VoidCallback onToggleVisibility;
  final VoidCallback onChangePassword;

  const UserProfileSecurityCard({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.passwordVisible,
    required this.isLoading,
    required this.onToggleVisibility,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileSectionTitle('Security'),
          const SizedBox(height: 14),
          ProfileTextField(
            controller: currentPasswordController,
            label: 'Current password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: !passwordVisible,
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                passwordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ProfileTextField(
            controller: newPasswordController,
            label: 'New password',
            hint: '••••••••',
            icon: Icons.lock_reset_rounded,
            obscureText: !passwordVisible,
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                passwordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Use a strong password with at least 8 characters. Your current password is required when changing your own credentials.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onChangePassword,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_reset_rounded),
              label: const Text('Change password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
