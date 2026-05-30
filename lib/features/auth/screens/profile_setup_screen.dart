import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _familyNameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _createNew = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _familyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final supabase = ref.read(supabaseProvider);

      String? familyId;

      if (_createNew) {
        // Create new family
        final family = await supabase
            .from('families')
            .insert({
              'name': _familyNameCtrl.text.trim(),
              'created_by': user.id,
            })
            .select()
            .single();
        familyId = family['id'] as String;
      }

      await ref.read(authNotifierProvider.notifier).upsertProfile(
            userId: user.id,
            fullName: _nameCtrl.text.trim(),
            phone: user.phone,
            familyId: familyId,
          );

      if (mounted) context.go('/tree');
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
                const Gap(48),
                Text(
                  'إعداد ملفك الشخصي',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2),
                Text(
                  'Setup Your Profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ).animate().fadeIn(delay: 100.ms),
                const Gap(32),
                AppTextField(
                  label: 'Full name',
                  controller: _nameCtrl,
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Required',
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                const Gap(12),
                AppTextField(
                  label: 'الاسم الكامل (Arabic)',
                  controller: _nameArCtrl,
                  textDirection: TextDirection.rtl,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                const Gap(32),
                // Family section
                Text(
                  'Family',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 250.ms),
                const Gap(12),
                // Toggle create vs join
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _createNew = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _createNew
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Create family',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _createNew
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _createNew = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_createNew
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Join family',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !_createNew
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
                const Gap(12),
                if (_createNew)
                  AppTextField(
                    label: 'Family name',
                    controller: _familyNameCtrl,
                    validator: _createNew
                        ? (v) => v != null && v.trim().isNotEmpty
                            ? null
                            : 'Required'
                        : null,
                  ).animate().fadeIn().slideY(begin: 0.2)
                else
                  AppTextField(
                    label: 'Family code / invite link',
                    controller: _familyNameCtrl,
                  ).animate().fadeIn().slideY(begin: 0.2),
                const Gap(40),
                AppButton(
                  label: 'Get Started',
                  onPressed: _save,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
