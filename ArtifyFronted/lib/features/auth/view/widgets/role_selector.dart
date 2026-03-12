// lib/features/auth/view/widgets/role_selector.dart
import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelector extends StatelessWidget {
  final bool isArtist;
  final ValueChanged<bool> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.isArtist,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account type',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _roleCard(
              title: 'Listener',
              subtitle: 'Just listen',
              icon: Icons.headphones_rounded,
              selected: !isArtist,
              onTap: () => onRoleChanged(false),
            ),
            const SizedBox(width: 12),
            _roleCard(
              title: 'Artist',
              subtitle: 'Upload music',
              icon: Icons.mic_rounded,
              selected: isArtist,
              onTap: () => onRoleChanged(true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? Pallete.primary : Colors.white.withOpacity(0.08),
              width: selected ? 1.3 : 1,
            ),
            gradient: selected
                ? const LinearGradient(
                    colors: [Pallete.gradient1, Pallete.gradient2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.white.withOpacity(0.02),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Pallete.primary.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
