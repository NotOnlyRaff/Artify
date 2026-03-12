import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class UploadAlbumFormCard extends StatelessWidget {
  final Widget tabSwitcher;
  final Widget activeTab;

  const UploadAlbumFormCard({
    super.key,
    required this.tabSwitcher,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Pallete.cardColor.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Pallete.borderColor.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          tabSwitcher,
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: activeTab,
          ),
        ],
      ),
    );
  }
}
