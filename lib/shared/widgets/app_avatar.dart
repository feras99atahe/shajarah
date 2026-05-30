import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String gender;
  final double size;
  final bool isDeceased;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    required this.gender,
    this.size = 48,
    this.isDeceased = false,
    this.onTap,
  });

  Color get _bgColor {
    if (isDeceased) return AppColors.deceasedLight;
    return gender == 'male' ? AppColors.maleLight : AppColors.femaleLight;
  }

  Color get _iconColor {
    if (isDeceased) return AppColors.deceased;
    return gender == 'male' ? AppColors.male : AppColors.female;
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor,
          border: Border.all(
            color: isDeceased ? AppColors.deceased : _iconColor,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initialsWidget(),
                errorWidget: (_, __, ___) => _initialsWidget(),
              )
            : _initialsWidget(),
      ),
    );
  }

  Widget _initialsWidget() => Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: _iconColor,
          ),
        ),
      );
}
