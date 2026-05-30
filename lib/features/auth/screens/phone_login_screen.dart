import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  // Local digits only (after +218) — user types 9-digit number
  final _localCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _localCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '+218${_localCtrl.text.trim()}';

  // Libyan mobile prefixes: 91/92/94 (Libyana), 21 (LTT)
  String? _validateLibyan(String? v) {
    final digits = v?.trim() ?? '';
    if (digits.length != 9) return 'Enter 9 digits after +218';
    final valid = RegExp(r'^(9[124]|21)\d{7}$').hasMatch(digits);
    if (!valid) {
      return 'Invalid Libyan number\n'
          'Must start with 91, 92, 94 or 21';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithPhone(_fullPhone);
      if (mounted) {
        context.push('/otp', extra: _fullPhone);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(56),

                // Logo mark
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌳', style: TextStyle(fontSize: 36)),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),

                const Gap(32),

                Text(
                  'مرحباً بك',
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),

                const Gap(4),

                Text(
                  'أدخل رقمك الليبي للمتابعة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const Gap(6),

                Text(
                  'Enter your Libyan phone number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                ).animate().fadeIn(delay: 200.ms),

                const Gap(40),

                // Phone field with +218 prefix locked
                TextFormField(
                  controller: _localCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: _validateLibyan,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    // Locked country prefix
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇱🇾', style: TextStyle(fontSize: 20)),
                          const Gap(6),
                          Text(
                            '+218',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    hintText: '91 XXX XXXX',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                    helperText:
                        'Libyan numbers only — 91, 92, 94 (Libyana) · 21 (LTT)',
                    helperStyle: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const Gap(8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/admin-login'),
                    child: Text(
                      'Admin / Auditor login',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const Gap(28),

                AppButton(
                  label: 'متابعة  ←',
                  onPressed: _localCtrl.text.length == 9 ? _submit : null,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                const Gap(20),

                // Trust indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TrustBadge(
                      icon: Icons.lock_outline_rounded,
                      label: 'Secure',
                    ),
                    const Gap(16),
                    _TrustBadge(
                      icon: Icons.verified_outlined,
                      label: 'Verified',
                    ),
                    const Gap(16),
                    _TrustBadge(
                      icon: Icons.family_restroom_rounded,
                      label: 'Family',
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const Gap(4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }
}
