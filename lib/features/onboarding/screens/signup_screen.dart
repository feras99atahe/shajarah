import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../claims/providers/claim_provider.dart';

/// Unified auth screen — sign up or log in (toggled by [login]).
class SignupScreen extends ConsumerStatefulWidget {
  final bool login;
  const SignupScreen({super.key, this.login = false});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _login = widget.login;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (!email.contains('@') || pass.length < 6) {
      _toast('أدخل بريدًا صحيحًا وكلمة مرور لا تقل عن ٦ أحرف');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = ref.read(authNotifierProvider.notifier);
      if (_login) {
        await auth.signIn(email, pass);
        final user = ref.read(supabaseProvider).auth.currentUser;
        if (user == null) throw const AuthException('تعذّر تسجيل الدخول');
        // Returning user → tree if they have a family, pending screen if a
        // claim awaits approval, else finish setup.
        final familyId = await ref.read(userFamilyIdProvider.future);
        if (familyId != null) {
          if (mounted) context.go('/tree');
        } else {
          final claim = await ref.read(myClaimProvider.future);
          if (mounted) {
            context.go(claim != null && claim.status == 'pending' ? '/pending' : '/name-entry');
          }
        }
      } else {
        await auth.signUp(email, pass);
        final user = ref.read(supabaseProvider).auth.currentUser;
        if (user == null) {
          // Supabase has "Confirm email" enabled → no session yet. Not an error.
          if (mounted) {
            _info('📧 أرسلنا رابط تأكيد إلى بريدك. افتح الرابط ثم سجّل الدخول.');
            setState(() => _login = true);
          }
          return;
        }
        if (mounted) context.go('/name-entry');
      }
    } on AuthException catch (e) {
      _toast(_friendly(e.message));
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(String m) {
    m = m.toLowerCase();
    if (m.contains('already')) return 'هذا البريد مسجّل — سجّل الدخول بدلًا من ذلك';
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'البريد أو كلمة المرور غير صحيحة';
    }
    if (m.contains('weak')) return 'كلمة المرور ضعيفة جدًا';
    if (m.contains('email not confirmed')) return 'يرجى تأكيد بريدك الإلكتروني أولًا';
    return m;
  }

  void _toast(String msg) => _snack(msg, AppColors.danger);
  void _info(String msg) => _snack(msg, AppColors.primary);

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.right),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: _login ? null : 0,
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryButton(_login ? 'تسجيل الدخول' : 'متابعة', loading: _loading, onPressed: _submit),
        const SizedBox(height: 12),
        // mode toggle
        GestureDetector(
          onTap: () => setState(() => _login = !_login),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: _login ? 'ليس لديك حساب؟ ' : 'لديك حساب؟ ',
                style: ui(size: 13.5, color: AppColors.muted),
              ),
              TextSpan(
                text: _login ? 'أنشئ حسابًا' : 'تسجيل الدخول',
                style: ui(size: 13.5, weight: FontWeight.w700, color: AppColors.primary),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
        ),
      ]),
      child: ListView(children: [
        // back to welcome
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: RoundButton('back', onTap: () => context.go('/welcome')),
        ),
        const SizedBox(height: 18),
        Text(_login ? 'تسجيل الدخول' : 'أنشئ حسابك', style: brand(size: 28, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          _login
              ? 'أدخل بريدك وكلمة المرور للعودة إلى شجرتك.'
              : 'بريدك وكلمة المرور يحفظان شجرتك ويؤكّدان هويتك.',
          style: ui(size: 15, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 26),
        AppField(label: 'البريد الإلكتروني', controller: _email, hint: 'example@email.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        AppField(label: 'كلمة المرور', controller: _password, hint: '••••••', obscure: true),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text('عائلتك مغلقة بالكامل — لا يراها سوى أفرادها الموثّقين.',
                  style: ui(size: 13, color: AppColors.muted, height: 1.6)),
            ),
          ]),
        ),
      ]),
    );
  }
}
