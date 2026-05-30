import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final String? parentId; // pre-link as child of this member

  const AddMemberScreen({super.key, this.parentId});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _gender = 'male';
  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isBirth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1970),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final familyId = await ref.read(userFamilyIdProvider.future);
      if (familyId == null) throw Exception('No family found');

      final member = await ref.read(treeNotifierProvider.notifier).addMember(
            familyId: familyId,
            fullName: _nameCtrl.text.trim(),
            fullNameAr: _nameArCtrl.text.trim().isEmpty
                ? null
                : _nameArCtrl.text.trim(),
            gender: _gender,
            birthDate: _birthDate,
            deathDate: _deathDate,
            birthPlace: _birthPlaceCtrl.text.trim().isEmpty
                ? null
                : _birthPlaceCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );

      // Link to parent if provided
      if (widget.parentId != null) {
        await ref.read(treeNotifierProvider.notifier).addRelationship(
              memberId: widget.parentId!,
              relatedMemberId: member.id,
              type: RelationshipType.child,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added!')),
        );
        context.pop();
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
      appBar: AppBar(
        title: const Text('Add Member'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Gender selector
            _SectionTitle('Gender').animate().fadeIn(),
            const Gap(10),
            Row(
              children: [
                _GenderChip(
                  label: 'Male  ♂',
                  selected: _gender == 'male',
                  color: AppColors.male,
                  bgColor: AppColors.maleLight,
                  onTap: () => setState(() => _gender = 'male'),
                ),
                const Gap(12),
                _GenderChip(
                  label: 'Female  ♀',
                  selected: _gender == 'female',
                  color: AppColors.female,
                  bgColor: AppColors.femaleLight,
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ],
            ).animate().fadeIn(delay: 50.ms),
            const Gap(24),
            _SectionTitle('Name').animate().fadeIn(delay: 100.ms),
            const Gap(10),
            AppTextField(
              label: 'Full name *',
              controller: _nameCtrl,
              validator: (v) =>
                  v != null && v.trim().isNotEmpty ? null : 'Required',
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            const Gap(12),
            AppTextField(
              label: 'الاسم بالعربية',
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const Gap(24),
            _SectionTitle('Dates').animate().fadeIn(delay: 250.ms),
            const Gap(10),
            _DateField(
              label: 'Date of birth',
              value: _birthDate,
              onTap: () => _pickDate(true),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const Gap(12),
            _DateField(
              label: 'Date of death (if applicable)',
              value: _deathDate,
              onTap: () => _pickDate(false),
              onClear: _deathDate != null
                  ? () => setState(() => _deathDate = null)
                  : null,
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
            const Gap(24),
            _SectionTitle('Details').animate().fadeIn(delay: 400.ms),
            const Gap(10),
            AppTextField(
              label: 'Place of birth',
              controller: _birthPlaceCtrl,
              prefix: const Icon(Icons.location_on_outlined),
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
            const Gap(12),
            AppTextField(
              label: 'Phone number',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.phone_outlined),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            const Gap(12),
            AppTextField(
              label: 'Notes',
              controller: _notesCtrl,
              maxLines: 3,
            ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
            const Gap(32),
            AppButton(
              label: 'Add Member',
              onPressed: _save,
              isLoading: _isLoading,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            const Gap(40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
              width: selected ? 2 : 1,
            ),
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
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
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
          ],
        ),
      ),
    );
  }
}
