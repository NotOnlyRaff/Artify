import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicStatsRow extends StatelessWidget {
  final int trackCount;
  final String? activeSince;
  final String? origin;

  const CosmicStatsRow(
      {required this.trackCount, this.activeSince, this.origin});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            _StatTile(label: 'Tracks in catalog', value: trackCount.toString()),
            if (activeSince != null)
              _StatTile(label: 'Active since', value: activeSince!),
            if (origin != null) _StatTile(label: 'Origin', value: origin!),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style:
              GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
