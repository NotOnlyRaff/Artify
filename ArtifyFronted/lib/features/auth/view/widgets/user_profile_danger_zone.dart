import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileDangerZone extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onDelete;

  const UserProfileDangerZone({
    super.key,
    required this.isLoading,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Pallete.errorColor.withOpacity(0.05),
        border: Border.all(color: Pallete.errorColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Pallete.errorColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: GoogleFonts.plusJakartaSans(
                  color: Pallete.errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Once you delete your account, there is no going back. Please be certain.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isLoading ? null : onDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.errorColor.withOpacity(0.15),
                foregroundColor: Pallete.errorColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Pallete.errorColor.withOpacity(0.5),
                  ),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
