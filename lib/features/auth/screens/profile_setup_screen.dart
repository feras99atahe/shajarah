import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../tree/providers/tree_provider.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ── Family ────────────────────────────────────────────────────────────────
  bool _createNew = true;
  final _groupNameCtrl = TextEditingController(); // family group name

  // ── Paternal four-part name ───────────────────────────────────────────────
  final _firstNameCtrl       = TextEditingController();
  final _fatherNameCtrl      = TextEditingController();
  final _grandfatherNameCtrl = TextEditingController();
  final _familyNameCtrl      = TextEditingController(); // tribe / last name

  // ── Location ──────────────────────────────────────────────────────────────
  final _cityCtrl = TextEditingController();

  // ── Gender ────────────────────────────────────────────────────────────────
  String _gender = 'male';

  // ── Maternal (optional) ───────────────────────────────────────────────────
  bool _showMaternal = false;
  final _motherFirstCtrl       = TextEditingController();
  final _motherFatherCtrl      = TextEditingController();
  final _motherGrandfatherCtrl = TextEditingController();
  final _motherFamilyCtrl      = TextEditingController();

  // ── Birth details (optional) ──────────────────────────────────────────────
  DateTime? _birthDate;
  bool _showBirthDate = false;

  @override
  void dispose() {
    for (final c in [
      _groupNameCtrl, _firstNameCtrl, _fatherNameCtrl, _grandfatherNameCtrl,
      _familyNameCtrl, _cityCtrl, _motherFirstCtrl, _motherFatherCtrl,
      _motherGrandfatherCtrl, _motherFamilyCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String? _req(String? v) =>
      v != null && v.trim().isNotEmpty ? null : 'Required';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final fullName =
          '${_firstNameCtrl.text.trim()} ${_fatherNameCtrl.text.trim()} '
          '${_grandfatherNameCtrl.text.trim()} ${_familyNameCtrl.text.trim()}';

      // ── Step 1: Create or join family ─────────────────────────────────────
      if (_createNew) {
        await supabase.rpc('setup_profile', params: {
          'p_family_name': _groupNameCtrl.text.trim(),
          'p_full_name': fullName,
        });
      } else {
        await supabase.rpc('join_family_by_name', params: {
          'p_family_name': _groupNameCtrl.text.trim(),
          'p_full_name': fullName,
        });
      }

      // ── Step 2: Get the newly assigned family_id ──────────────────────────
      final user = ref.read(currentUserProvider)!;
      final profileData = await supabase
          .from('user_profiles')
          .select('family_id')
          .eq('id', user.id)
          .single();
      final familyId = profileData['family_id'] as String;

      // ── Step 3: Create the user's tree member ─────────────────────────────
      final member = await ref.read(treeNotifierProvider.notifier).addMember(
            familyId: familyId,
            firstName: _firstNameCtrl.text.trim(),
            fatherName: _fatherNameCtrl.text.trim(),
            grandfatherName: _grandfatherNameCtrl.text.trim(),
            familyName: _familyNameCtrl.text.trim(),
            motherFirstName: _motherFirstCtrl.text.trim().isEmpty
                ? null : _motherFirstCtrl.text.trim(),
            motherFatherName: _motherFatherCtrl.text.trim().isEmpty
                ? null : _motherFatherCtrl.text.trim(),
            motherGrandfatherName: _motherGrandfatherCtrl.text.trim().isEmpty
                ? null : _motherGrandfatherCtrl.text.trim(),
            motherFamilyName: _motherFamilyCtrl.text.trim().isEmpty
                ? null : _motherFamilyCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            gender: _gender,
            birthDate: _birthDate,
            showBirthDate: _showBirthDate,
          );

      // ── Step 4: Link this user account to their tree member ───────────────
      await ref.read(treeNotifierProvider.notifier).linkUserToMember(member.id);

      if (mounted) context.go('/tree');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const Gap(40),

              // Title
              Text(
                'إعداد ملفك الشخصي',
                style: GoogleFonts.reemKufi(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn().slideX(begin: -0.2),
              Text(
                'أكمل بياناتك للانضمام إلى الشجرة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ).animate().fadeIn(delay: 80.ms),

              const Gap(32),

              // ── FAMILY ─────────────────────────────────────────────────────
              _SectionLabel('العائلة'),
              const Gap(12),
              _FamilyToggle(
                createNew: _createNew,
                onChanged: (v) => setState(() => _createNew = v),
              ).animate().fadeIn(delay: 120.ms),
              const Gap(12),
              AppTextField(
                label: _createNew ? 'اسم العائلة *' : 'اسم العائلة للانضمام *',
                hint: _createNew ? 'مثال: عائلة الحسن' : 'أدخل اسم العائلة بالضبط',
                controller: _groupNameCtrl,
                prefix: const Icon(Icons.family_restroom_rounded),
                validator: _req,
              ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.15),

              const Gap(32),

              // ── GENDER ─────────────────────────────────────────────────────
              _SectionLabel('الجنس'),
              const Gap(10),
              Row(children: [
                _GenderChip(
                  label: 'ذكر ♂',
                  selected: _gender == 'male',
                  color: AppColors.male,
                  bg: AppColors.maleLight,
                  onTap: () => setState(() => _gender = 'male'),
                ),
                const Gap(12),
                _GenderChip(
                  label: 'أنثى ♀',
                  selected: _gender == 'female',
                  color: AppColors.female,
                  bg: AppColors.femaleLight,
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ]).animate().fadeIn(delay: 160.ms),

              const Gap(32),

              // ── PATERNAL NAME ──────────────────────────────────────────────
              _SectionLabel('اسمك الرباعي'),
              const Gap(4),
              Text(
                'الاسم · اسم الأب · اسم الجد · العائلة (القبيلة)',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const Gap(12),
              AppTextField(
                label: 'الاسم الأول *',
                controller: _firstNameCtrl,
                validator: _req,
              ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
              const Gap(10),
              AppTextField(
                label: 'اسم الأب *',
                controller: _fatherNameCtrl,
                validator: _req,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const Gap(10),
              AppTextField(
                label: 'اسم الجد *',
                controller: _grandfatherNameCtrl,
                validator: _req,
              ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),
              const Gap(10),
              AppTextField(
                label: 'اسم العائلة / القبيلة *',
                hint: 'مثال: الحسن',
                controller: _familyNameCtrl,
                validator: _req,
              ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.1),

              const Gap(32),

              // ── CITY ───────────────────────────────────────────────────────
              _SectionLabel('المدينة'),
              const Gap(4),
              Text(
                'تُستخدم لتحديد نطاق البحث وتجنّب تداخل الأسماء بين المناطق.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const Gap(12),
              AppTextField(
                label: 'المدينة *',
                hint: 'مثال: طرابلس',
                controller: _cityCtrl,
                prefix: const Icon(Icons.location_city_outlined),
                validator: _req,
              ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.1),

              const Gap(32),

              // ── MATERNAL NAME (optional) ───────────────────────────────────
              _SectionLabel('اسم الأم'),
              const Gap(4),
              Text(
                'مخفي عن الآخرين إلا إذا كانت بينك وبينهم صلة قرابة موثّقة.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const Gap(10),
              _ExpandToggle(
                label: _showMaternal
                    ? 'إخفاء حقول الأم'
                    : 'إضافة اسم الأم (اختياري)',
                expanded: _showMaternal,
                onTap: () => setState(() => _showMaternal = !_showMaternal),
              ).animate().fadeIn(delay: 280.ms),
              if (_showMaternal) ...[
                const Gap(10),
                AppTextField(
                  label: 'اسم الأم الأول',
                  controller: _motherFirstCtrl,
                ).animate().fadeIn().slideY(begin: 0.1),
                const Gap(10),
                AppTextField(
                  label: 'اسم والد الأم',
                  controller: _motherFatherCtrl,
                ).animate().fadeIn(delay: 30.ms).slideY(begin: 0.1),
                const Gap(10),
                AppTextField(
                  label: 'اسم جد الأم',
                  controller: _motherGrandfatherCtrl,
                ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.1),
                const Gap(10),
                AppTextField(
                  label: 'اسم عائلة الأم',
                  controller: _motherFamilyCtrl,
                ).animate().fadeIn(delay: 90.ms).slideY(begin: 0.1),
              ],

              const Gap(32),

              // ── BIRTH DETAILS (optional) ───────────────────────────────────
              _SectionLabel('تاريخ الميلاد'),
              const Gap(10),
              _DatePickerField(
                value: _birthDate,
                label: 'تاريخ الميلاد (اختياري)',
                onTap: _pickBirthDate,
                onClear: _birthDate != null
                    ? () => setState(() => _birthDate = null)
                    : null,
              ).animate().fadeIn(delay: 300.ms),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('إظهار تاريخ الميلاد للأقارب الموثّقين'),
                  value: _showBirthDate,
                  onChanged: (v) => setState(() => _showBirthDate = v),
                  activeColor: AppColors.primary,
                ),
              ).animate().fadeIn(delay: 320.ms),

              const Gap(40),

              // ── SAVE ───────────────────────────────────────────────────────
              AppButton(
                label: 'لنبدأ',
                onPressed: _save,
                isLoading: _isLoading,
              ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.3),
              const Gap(48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
}

class _FamilyToggle extends StatelessWidget {
  final bool createNew;
  final ValueChanged<bool> onChanged;
  const _FamilyToggle({required this.createNew, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => onChanged(true),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: createNew ? AppColors.primary : AppColors.surface,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'إنشاء عائلة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: createNew ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => onChanged(false),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: !createNew ? AppColors.primary : AppColors.surface,
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12)),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'الانضمام لعائلة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: !createNew ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _GenderChip({
    required this.label, required this.selected,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? color : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? color : AppColors.border,
                  width: selected ? 2 : 1),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
}

class _ExpandToggle extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  const _ExpandToggle(
      {required this.label, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AppColors.primary,
            ),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      );
}

class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DatePickerField(
      {required this.value, required this.label,
       required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textTertiary),
            const Gap(12),
            Expanded(
              child: Text(
                value != null
                    ? '${value!.day}/${value!.month}/${value!.year}'
                    : label,
                style: TextStyle(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontSize: 15,
                ),
              ),
            ),
            if (onClear != null && value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textTertiary),
              ),
          ]),
        ),
      );
}
