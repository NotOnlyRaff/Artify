import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/artist/model/artist_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class StudioHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const StudioHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Pallete.surfacePrimary.withOpacity(0.75),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Pallete.primary.withOpacity(0.16),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Pallete.gradient1, Pallete.gradient2],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudioSectionCard extends StatelessWidget {
  final Widget child;

  const StudioSectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class StudioSectionTitle extends StatelessWidget {
  final String text;

  const StudioSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class StudioMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const StudioMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}

class StudioMetricsStrip extends StatelessWidget {
  final List<StudioMetricData> metrics;

  const StudioMetricsStrip({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        final spacing = 12.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _StudioMetricTile(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _StudioMetricTile extends StatelessWidget {
  final StudioMetricData metric;

  const _StudioMetricTile({
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.035),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: metric.accentColor.withOpacity(0.14),
              border: Border.all(
                color: metric.accentColor.withOpacity(0.22),
              ),
            ),
            child: Icon(
              metric.icon,
              color: metric.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.label,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudioCreditSelectorCard extends StatelessWidget {
  final String title;
  final String description;
  final TextEditingController nameController;
  final TextEditingController searchController;
  final String searchQuery;
  final ArtistModel? linkedArtist;
  final AsyncValue<List<ArtistModel>> searchResults;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ArtistModel> onSelectArtist;
  final VoidCallback onClearLinkedArtist;
  final IconData icon;
  final String nameLabel;
  final String nameHint;
  final String searchLabel;
  final String searchHint;
  final bool required;

  const StudioCreditSelectorCard({
    super.key,
    required this.title,
    required this.description,
    required this.nameController,
    required this.searchController,
    required this.searchQuery,
    required this.linkedArtist,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onSelectArtist,
    required this.onClearLinkedArtist,
    required this.icon,
    required this.nameLabel,
    required this.nameHint,
    required this.searchLabel,
    required this.searchHint,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = searchQuery.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.06),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: linkedArtist == null
                      ? Colors.white.withOpacity(0.06)
                      : Pallete.accentCyan.withOpacity(0.16),
                ),
                child: Text(
                  linkedArtist == null
                      ? (required ? 'REQUIRED' : 'MANUAL')
                      : 'LINKED',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StudioTextField(
            controller: nameController,
            label: nameLabel,
            hint: nameHint,
            icon: icon,
          ),
          if (linkedArtist != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Pallete.accentCyan.withOpacity(0.08),
                border: Border.all(
                  color: Pallete.accentCyan.withOpacity(0.14),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: linkedArtist!.imageUrl != null &&
                            linkedArtist!.imageUrl!.isNotEmpty
                        ? NetworkImage(linkedArtist!.imageUrl!)
                        : null,
                    child: linkedArtist!.imageUrl == null ||
                            linkedArtist!.imageUrl!.isEmpty
                        ? Text(
                            _artistLabel(linkedArtist!)
                                .characters
                                .first
                                .toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _artistLabel(linkedArtist!),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Linked to catalog artist id',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClearLinkedArtist,
                    icon: const Icon(
                      Icons.link_off_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          StudioTextField(
            controller: searchController,
            label: searchLabel,
            hint: searchHint,
            icon: Icons.person_search_rounded,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 6),
          Text(
            trimmedQuery.length >= 2
                ? 'Search in your catalog to bind this credit to a real artist.'
                : 'Type at least 2 characters to search artists.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          if (trimmedQuery.length >= 2) ...[
            const SizedBox(height: 10),
            searchResults.when(
              data: (artists) {
                final filtered = artists
                    .where((artist) => artist.id != linkedArtist?.id)
                    .take(5)
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return Text(
                    'No artists found for "$trimmedQuery".',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  );
                }

                return Column(
                  children: filtered
                      .map(
                        (artist) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: artist.imageUrl != null &&
                                    artist.imageUrl!.isNotEmpty
                                ? NetworkImage(artist.imageUrl!)
                                : null,
                            child: artist.imageUrl == null ||
                                    artist.imageUrl!.isEmpty
                                ? Text(
                                    _artistLabel(artist)
                                        .characters
                                        .first
                                        .toUpperCase(),
                                  )
                                : null,
                          ),
                          title: Text(
                            _artistLabel(artist),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: artist.slug == null
                              ? null
                              : Text(
                                  '@${artist.slug}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                          trailing: OutlinedButton(
                            onPressed: () => onSelectArtist(artist),
                            child: const Text('Link'),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Text(
                error.toString(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.redAccent,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _artistLabel(ArtistModel artist) {
    return artist.displayName?.isNotEmpty == true
        ? artist.displayName!
        : artist.name;
  }
}

class StudioTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool expands;
  final int? minLines;
  final int? maxLines;

  const StudioTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.validator,
    this.onChanged,
    this.expands = false,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      minLines: expands ? null : minLines,
      maxLines: expands ? null : maxLines,
      expands: expands,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _studioInputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }
}

class StudioDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const StudioDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _studioInputDecoration(
          label: label,
          hint: 'Pick a date',
          icon: Icons.calendar_month_rounded,
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}',
          style: GoogleFonts.plusJakartaSans(
            color: value == null ? Colors.white38 : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class StudioDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const StudioDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _studioInputDecoration(
        label: label,
        hint: '',
        icon: Icons.category_outlined,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Pallete.surfaceSecondary,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class StudioMediaPickerCard extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final Widget? preview;

  const StudioMediaPickerCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.buttonText,
    required this.onTap,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview != null) ...[
            preview!,
            const SizedBox(height: 14),
          ],
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value ?? 'No file selected',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudioPrimaryButton extends StatelessWidget {
  final bool loading;
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const StudioPrimaryButton({
    super.key,
    required this.loading,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Pallete.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class StudioInfoCallout extends StatelessWidget {
  final String title;
  final String body;

  const StudioInfoCallout({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Pallete.accentCyan.withOpacity(0.08),
        border: Border.all(
          color: Pallete.accentCyan.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Pallete.accentCyan,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _studioInputDecoration({
  required String label,
  required String hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.plusJakartaSans(color: Colors.white70),
    hintStyle: GoogleFonts.plusJakartaSans(
      color: Colors.white38,
      fontSize: 13,
    ),
    filled: true,
    fillColor: Colors.white.withOpacity(0.03),
    prefixIcon: icon == null
        ? null
        : Icon(
            icon,
            color: Colors.white60,
            size: 20,
          ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Pallete.gradient2, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Pallete.errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Pallete.errorColor, width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
  );
}
