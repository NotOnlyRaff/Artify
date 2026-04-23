import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class UserProfileActionsRow extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onLogout;

  const UserProfileActionsRow({
    super.key,
    required this.isLoading,
    required this.onSave,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSave,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
