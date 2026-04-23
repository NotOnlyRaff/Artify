import 'dart:ui';

import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTitle extends StatelessWidget {
  final String label;

  const SectionTitle(
    this.label, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFA855F7).withOpacity(0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.035),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  final ArtistModel artist;

  const AboutSection({
    super.key,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final bio = (artist.bio ?? '').trim();
    final country = (artist.country ?? '').trim();
    final slug = (artist.slug ?? '').trim();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty)
            Text(
              bio,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          if (bio.isNotEmpty && (country.isNotEmpty || slug.isNotEmpty))
            const SizedBox(height: 14),
          if (country.isNotEmpty || slug.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (country.isNotEmpty)
                  _MiniFactChip(
                    icon: Icons.public_rounded,
                    label: country,
                  ),
                if (slug.isNotEmpty)
                  _MiniFactChip(
                    icon: Icons.alternate_email_rounded,
                    label: slug,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class SectionPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const SectionPlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: Colors.white54,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white60,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFactChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniFactChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
