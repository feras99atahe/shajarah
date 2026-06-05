import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

/// Dedicated admin entrance — separate from the member app.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
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
      _toast('أدخل بيانات صحيحة');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signIn(email, pass);
      if (ref.read(supabaseProvider).auth.currentUser == null) {
        throw const AuthException('تعذّر تسجيل الدخول');
      }
      ref.invalidate(userRoleProvider);
      final role = await ref.read(userRoleProvider.future);
      if (!mounted) return;
      if (role == 'admin') {
        context.go('/admin');
      } else {
        await ref.read(authNotifierProvider.notifier).signOut();
        _toast('هذا الحساب ليس مشرفًا');
      }
    } on AuthException catch (e) {
      _toast(e.message.toLowerCase().contains('invalid') ? 'البريد أو كلمة المرور غير صحيحة' : e.message);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, textAlign: TextAlign.right),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primaryDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: Icon(AppIcons.of('back'), color: AppColors.primaryInk),
                  onPressed: () => context.go('/welcome'),
                ),
              ),
              const Spacer(),
              Container(
                width: 84, height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(Icons.shield_outlined, size: 40, color: AppColors.primaryInk),
              ),
              const SizedBox(height: 20),
              Text('دخول المشرف', style: brand(size: 26, weight: FontWeight.w600, color: AppColors.primaryInk)),
              const SizedBox(height: 6),
              Text('منطقة الإدارة — للمشرفين المعتمدين فقط.',
                  style: ui(size: 14, color: AppColors.primaryInk.withValues(alpha: 0.7)), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              _DarkField(controller: _email, label: 'البريد الإلكتروني', hint: 'admin@email.com'),
              const SizedBox(height: 14),
              _DarkField(controller: _password, label: 'كلمة المرور', hint: '••••••', obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryInk,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    textStyle: ui(size: 16, weight: FontWeight.w700),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primaryInk))
                      : const Text('دخول'),
                ),
              ),
              const Spacer(flex: 2),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  const _DarkField({required this.controller, required this.label, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: ui(size: 12.5, weight: FontWeight.w600, color: AppColors.primaryInk.withValues(alpha: 0.75))),
      const SizedBox(height: 7),
      Container(
        height: 52,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.primaryInk.withValues(alpha: 0.2)),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: ui(size: 16, weight: FontWeight.w600, color: AppColors.primaryInk),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: ui(size: 15, color: AppColors.primaryInk.withValues(alpha: 0.4)),
          ),
        ),
      ),
    ]);
  }
}
