import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// Labelled text field matching the design's `Field`. Live (editable) when a
/// [controller] is given; otherwise renders the static [value].
class AppField extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final TextEditingController? controller;
  final Widget? badge;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const AppField({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.controller,
    this.badge,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final filled = (controller?.text.isNotEmpty ?? (value ?? '').isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: ui(size: 12.5, weight: FontWeight.w600, color: AppColors.muted)),
          if (badge != null) ...[const SizedBox(width: 6), badge!],
        ]),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: filled ? AppColors.primary : AppColors.line, width: 1.5),
          ),
          child: controller == null
              ? Text(
                  (value == null || value!.isEmpty) ? (hint ?? '') : value!,
                  style: ui(
                      size: 16,
                      weight: filled ? FontWeight.w600 : FontWeight.w400,
                      color: filled ? AppColors.ink : AppColors.faint),
                )
              : TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  autofocus: autofocus,
                  onChanged: onChanged,
                  style: ui(size: 16, weight: FontWeight.w600, color: AppColors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: ui(size: 16, color: AppColors.faint),
                  ),
                ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const SearchField({super.key, required this.hint, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        Icon(AppIcons.of('search'), size: 19, color: AppColors.faint),
        const SizedBox(width: 9),
        Expanded(
          child: controller == null
              ? Text(hint, style: ui(size: 14.5, color: AppColors.faint))
              : TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: ui(size: 14.5, color: AppColors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: ui(size: 14.5, color: AppColors.faint),
                  ),
                ),
        ),
      ]),
    );
  }
}

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const AppToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: value ? AppColors.primary : AppColors.line),
        ),
        child: Align(
          alignment:
              value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}
