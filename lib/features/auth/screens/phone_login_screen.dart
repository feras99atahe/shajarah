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
  final _formKey = GlobalKey<FormState>();
  final _localCtrl = TextEditingController();      // digits after +218
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSignUp = false;     // toggle between sign-in and sign-up
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _localCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '+218${_localCtrl.text.trim()}';

  String? _validatePhone(String? v) {
    final d = v?.trim() ?? '';
    if (d.length != 9) return 'أدخل 9 أرقام بعد +218';
    if (!RegExp(r'^(9[124]|21)\d{7}$').hasMatch(d)) {
      return 'رقم ليبي غير صحيح\n(يبدأ بـ 91 أو 92 أو 94 أو 21)';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await ref.read(authNotifierProvider.notifier).signUpWithPhone(
              _fullPhone,
              _passwordCtrl.text,
            );
      } else {
        await ref.read(authNotifierProvider.notifier).signInWithPhone(
              _fullPhone,
              _passwordCtrl.text,
            );
      }

      if (!mounted) return;

      // Check profile completeness
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final supabase = ref.read(supabaseProvider);
        final profile = await supabase
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (mounted) {
          if (profile == null || profile['full_name'] == null) {
            context.go('/profile-setup');
          } else {
            context.go('/tree');
          }
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = _friendlyError(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    if (m.contains('already registered')) return 'هذا الرقم مسجل بالفعل — سجل دخولك';
    if (m.contains('user not found')) return 'الرقم غير مسجل — أنشئ حساباً أولاً';
    if (m.contains('weak password')) return 'كلمة المرور ضعيفة جداً';
    return msg;
  }

  void _toggle() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      _passwordCtrl.clear();
      _confirmCtrl.clear();
    });
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
                const Gap(52),

                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌳', style: TextStyle(fontSize: 36)),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.easeOutBack,
                    ),

                const Gap(30),

                // Title — switches between sign-in / sign-up
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_isSignUp),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSignUp ? 'إنشاء حساب' : 'تسجيل الدخول',
                        style: GoogleFonts.cairo(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _isSignUp
                            ? 'Create your Shajarah account'
                            : 'Sign in to your family tree',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const Gap(36),

                // ── Phone field ──────────────────────────────
                TextFormField(
                  controller: _localCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: _validatePhone,
                  onChanged: (_) => setState(() {}),
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    hintText: '91 XXX XXXX',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                    helperText: '91 / 92 / 94 (Libyana) · 21 (LTT)',
                    helperStyle: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                const Gap(14),

                // ── Password field ───────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePass,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ).animate().fadeIn(delay: 270.ms).slideY(begin: 0.15),

                // ── Confirm password — only on sign-up ───────
                if (_isSignUp) ...[
                  const Gap(14),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    validator: _validateConfirm,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      hintText: 'Confirm password',
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.15),
                ],

                const Gap(10),

                // Admin link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/admin-login'),
                    child: Text(
                      'دخول المشرف / Admin login',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 340.ms),

                const Gap(24),

                // ── Submit button ────────────────────────────
                AppButton(
                  label: _isSignUp ? 'إنشاء الحساب' : 'دخول',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const Gap(20),

                // ── Toggle sign-in / sign-up ─────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSignUp
                            ? 'لديك حساب بالفعل؟'
                            : 'ليس لديك حساب؟',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      TextButton(
                        onPressed: _toggle,
                        child: Text(
                          _isSignUp ? 'سجل دخولك' : 'أنشئ حساباً',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 480.ms),

                const Gap(28),

                // Trust badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TrustBadge(
                      icon: Icons.lock_outline_rounded,
                      label: 'آمن',
                    ),
                    const Gap(20),
                    _TrustBadge(
                      icon: Icons.no_sim_outlined,
                      label: 'بدون رمز',
                    ),
                    const Gap(20),
                    _TrustBadge(
                      icon: Icons.family_restroom_rounded,
                      label: 'عائلي',
                    ),
                  ],
                ).animate().fadeIn(delay: 560.ms),

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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const Gap(5),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
