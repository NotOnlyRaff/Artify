import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionChips extends StatelessWidget {
  final String label;
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const SuggestionChips({
    super.key,
    required this.label,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: suggestions
              .map((s) => GestureDetector(
                    onTap: () => onTap(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withOpacity(0.03),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
