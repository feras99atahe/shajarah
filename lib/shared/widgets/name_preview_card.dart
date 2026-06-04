import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Live full-name preview — the signature four-part-name moment.
/// Drop it above the name fields on profile_setup_screen / add_member_screen.
/// Feed it the current text of your four controllers; it composes the full
/// nasab line and shows a smart auto-link hint when enough parts are present.
///
/// Example:
///   NamePreviewCard(
///     name: _nameCtrl.text,
///     father: _fatherCtrl.text,
///     grandfather: _grandfatherCtrl.text,
///     family: _familyCtrl.text,
///     autoLinkHint: 'سيُربط تلقائيًا بـ عبدالله محمد الحسن',
///   )
/// Rebuild it as the user types (e.g. wrap fields in a Form + setState, or
/// drive from your controllers with addListener).
class NamePreviewCard extends StatelessWidget {
  final String name;
  final String father;
  final String grandfather;
  final String family;
  final String? autoLinkHint;
  final String label;

  const NamePreviewCard({
    super.key,
    required this.name,
    this.father = '',
    this.grandfather = '',
    this.family = '',
    this.autoLinkHint,
    this.label = 'اسمك الكامل',
  });

  String get _fullName {
    final parts =
        [name, father, grandfather, family].where((p) => p.trim().isNotEmpty);
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final full = _fullName;
    final empty = full.isEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: empty ? AppColors.surfaceVariant : AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: empty
            ? null
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: empty
                  ? AppColors.textTertiary
                  : AppColors.textOnPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            empty ? 'اكتب اسمك الرباعي…' : full,
            style: GoogleFonts.reemKufi(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: empty ? AppColors.textTertiary : AppColors.textOnPrimary,
            ),
          ),
          if (!empty && autoLinkHint != null && autoLinkHint!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.accentLight),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      autoLinkHint!,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
