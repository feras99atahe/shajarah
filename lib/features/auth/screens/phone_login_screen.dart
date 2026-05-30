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
  final _phoneCtrl = TextEditingController(text: '+966');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .signInWithPhone(_phoneCtrl.text.trim());
      if (mounted) {
        context.push('/otp', extra: _phoneCtrl.text.trim());
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(60),
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('🌳', style: TextStyle(fontSize: 38)),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const Gap(28),
                Text(
                  'مرحباً بك',
                  style: GoogleFonts.cairo(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                const Gap(6),
                Text(
                  'Welcome to Shajarah',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const Gap(8),
                Text(
                  'Enter your phone number to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ).animate().fadeIn(delay: 250.ms),
                const Gap(40),
                // Phone field
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[+\d\s]')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+966 5XX XXX XXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                const Gap(8),
                // Admin login link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/admin-login'),
                    child: const Text('Admin / Auditor? Login here'),
                  ),
                ).animate().fadeIn(delay: 350.ms),
                const Gap(32),
                AppButton(
                  label: 'Continue  →',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                const Gap(24),
                // Divider with terms
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
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
