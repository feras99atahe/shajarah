import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';

/// Email + password auth screen (sign in & sign up).
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل بريدك الإلكتروني';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$').hasMatch(v.trim())) {
      return 'بريد إلكتروني غير صحيح';
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

  String _friendlyError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (m.contains('already registered') || m.contains('user already registered')) {
      return 'هذا البريد مسجل بالفعل — سجل دخولك';
    }
    if (m.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً';
    }
    if (m.contains('user not found')) {
      return 'البريد غير مسجل — أنشئ حساباً أولاً';
    }
    if (m.contains('weak password')) return 'كلمة المرور ضعيفة جداً';
    if (m.contains('rate limit')) return 'حاول مرة أخرى بعد قليل';
    return msg;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (_isSignUp) {
        await ref.read(authNotifierProvider.notifier).signUp(email, password);

        // After sign-up Supabase may require email confirmation
        final user = supabase.auth.currentUser;
        if (user == null) {
          // Email confirmation is ON — let the user know
          if (mounted) {
            _showInfo(
              '📧  تم إرسال رسالة تأكيد إلى بريدك\n'
              'افتح الرابط في الإيميل ثم ارجع لتسجيل الدخول.',
            );
            setState(() => _isSignUp = false);
          }
          return;
        }
        await _navigateAfterAuth(supabase, user.id);
      } else {
        await ref.read(authNotifierProvider.notifier).signIn(email, password);
        final user = supabase.auth.currentUser;
        if (user == null) throw AuthException('حدث خطأ غير متوقع، حاول مجدداً');
        await _navigateAfterAuth(supabase, user.id);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e.message));
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateAfterAuth(SupabaseClient supabase, String userId) async {
    if (!mounted) return;
    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (!mounted) return;
    if (profile == null || profile['full_name'] == null) {
      context.go('/profile-setup');
    } else {
      context.go('/tree');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
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
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 1.8),
                  ),
                  child: const Center(
                    child: Text('🌳', style: TextStyle(fontSize: 38)),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.easeOutBack,
                    ),

                const Gap(30),

                // Title
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(_isSignUp),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSignUp ? 'إنشاء حساب' : 'تسجيل الدخول',
                        style: GoogleFonts.reemKufi(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _isSignUp
                            ? 'انضم إلى شجرة عائلتك'
                            : 'سجّل الدخول إلى شجرة عائلتك',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const Gap(36),

                // ── Email ────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                const Gap(14),

                // ── Password ─────────────────────────────────
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

                // ── Confirm password — sign-up only ──────────
                if (_isSignUp) ...[
                  const Gap(14),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    validator: _validateConfirm,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      hintText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.15),
                ],

                const Gap(8),

                // Admin link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/admin-login'),
                    child: Text(
                      'دخول المشرف',
                      style: TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ),
                ).animate().fadeIn(delay: 320.ms),

                const Gap(20),

                // ── Submit ───────────────────────────────────
                AppButton(
                  label: _isSignUp ? 'إنشاء الحساب' : 'دخول',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.2),

                const Gap(20),

                // ── Toggle sign-in / sign-up ─────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSignUp ? 'لديك حساب؟' : 'ليس لديك حساب؟',
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
                ).animate().fadeIn(delay: 440.ms),

                const Gap(32),

                // Trust badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TrustBadge(icon: Icons.lock_outline_rounded, label: 'آمن'),
                    const Gap(24),
                    _TrustBadge(icon: Icons.verified_outlined, label: 'موثوق'),
                    const Gap(24),
                    _TrustBadge(
                        icon: Icons.family_restroom_rounded, label: 'عائلي'),
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
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const Gap(5),
        Text(
          label,
          style: GoogleFonts.reemKufi(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
