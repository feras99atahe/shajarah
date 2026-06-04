import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final String? parentId;
  const AddMemberScreen({super.key, this.parentId});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  // Paternal four-part name
  final _firstNameCtrl      = TextEditingController();
  final _fatherNameCtrl     = TextEditingController();
  final _grandfatherNameCtrl= TextEditingController();
  final _familyNameCtrl     = TextEditingController();

  // Maternal four-part name
  final _motherFirstCtrl    = TextEditingController();
  final _motherFatherCtrl   = TextEditingController();
  final _motherGrandfatherCtrl = TextEditingController();
  final _motherFamilyCtrl   = TextEditingController();

  // Other fields
  final _cityCtrl           = TextEditingController();
  final _placeOfBirthCtrl   = TextEditingController();
  final _notesCtrl          = TextEditingController();

  String _gender = 'male';
  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _showBirthDate = false;
  bool _showMaternalFields = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _fatherNameCtrl, _grandfatherNameCtrl, _familyNameCtrl,
      _motherFirstCtrl, _motherFatherCtrl, _motherGrandfatherCtrl, _motherFamilyCtrl,
      _cityCtrl, _placeOfBirthCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isBirth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1970),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isBirth ? _birthDate = picked : _deathDate = picked);
  }

  String? _req(String? v) =>
      v != null && v.trim().isNotEmpty ? null : 'Required';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final familyId = await ref.read(userFamilyIdProvider.future);
      if (familyId == null) throw Exception('No family found');

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
            deathDate: _deathDate,
            placeOfBirth: _placeOfBirthCtrl.text.trim().isEmpty
                ? null : _placeOfBirthCtrl.text.trim(),
            showBirthDate: _showBirthDate,
            notes: _notesCtrl.text.trim().isEmpty
                ? null : _notesCtrl.text.trim(),
          );

      if (widget.parentId != null) {
        await ref.read(treeNotifierProvider.notifier).addRelationship(
              memberId: widget.parentId!,
              relatedMemberId: member.id,
              type: RelationshipType.child,
            );
      }

      // Auto-detect relationships from name data (runs silently in background)
      final newRels = await ref
          .read(treeNotifierProvider.notifier)
          .autoDetectRelationships();

      if (mounted) {
        final msg = newRels > 0
            ? 'Member added — $newRels relationship${newRels == 1 ? '' : 's'} detected automatically'
            : 'Member added';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor:
                newRels > 0 ? AppColors.success : null,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

            // ── Gender ──────────────────────────────────────────────────────
            _sectionTitle('Gender'),
            const Gap(10),
            Row(children: [
              _GenderChip(label: 'Male ♂', selected: _gender == 'male',
                  color: AppColors.male, bg: AppColors.maleLight,
                  onTap: () => setState(() => _gender = 'male')),
              const Gap(12),
              _GenderChip(label: 'Female ♀', selected: _gender == 'female',
                  color: AppColors.female, bg: AppColors.femaleLight,
                  onTap: () => setState(() => _gender = 'female')),
            ]).animate().fadeIn(delay: 50.ms),
            const Gap(24),

            // ── Paternal four-part name ──────────────────────────────────────
            _sectionTitle('Paternal Name'),
            const Gap(4),
            Text('First · Father · Grandfather · Family',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary)),
            const Gap(10),
            AppTextField(label: 'First name *', controller: _firstNameCtrl,
                validator: _req).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const Gap(10),
            AppTextField(label: "Father's name *", controller: _fatherNameCtrl,
                validator: _req).animate().fadeIn(delay: 130.ms).slideY(begin: 0.1),
            const Gap(10),
            AppTextField(label: "Grandfather's name *", controller: _grandfatherNameCtrl,
                validator: _req).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),
            const Gap(10),
            AppTextField(label: 'Family / Tribe name *', controller: _familyNameCtrl,
                validator: _req).animate().fadeIn(delay: 190.ms).slideY(begin: 0.1),
            const Gap(24),

            // ── City ────────────────────────────────────────────────────────
            _sectionTitle('Location'),
            const Gap(4),
            Text('Used to scope name searches and prevent regional overlaps.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary)),
            const Gap(10),
            AppTextField(
              label: 'City *',
              controller: _cityCtrl,
              validator: _req,
              prefix: const Icon(Icons.location_city_outlined),
            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.1),
            const Gap(24),

            // ── Maternal name (optional, collapsible) ───────────────────────
            _sectionTitle('Maternal Name'),
            const Gap(4),
            Text('Hidden from others unless they have a verified family connection.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary)),
            const Gap(10),
            GestureDetector(
              onTap: () => setState(() => _showMaternalFields = !_showMaternalFields),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(_showMaternalFields
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                        color: AppColors.primary),
                    const Gap(8),
                    Text(_showMaternalFields ? 'Hide maternal fields' : 'Add maternal name (optional)',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 240.ms),
            if (_showMaternalFields) ...[
              const Gap(10),
              AppTextField(label: "Mother's first name", controller: _motherFirstCtrl)
                  .animate().fadeIn().slideY(begin: 0.1),
              const Gap(10),
              AppTextField(label: "Mother's father name", controller: _motherFatherCtrl)
                  .animate().fadeIn(delay: 30.ms).slideY(begin: 0.1),
              const Gap(10),
              AppTextField(label: "Mother's grandfather name", controller: _motherGrandfatherCtrl)
                  .animate().fadeIn(delay: 60.ms).slideY(begin: 0.1),
              const Gap(10),
              AppTextField(label: "Mother's family name", controller: _motherFamilyCtrl)
                  .animate().fadeIn(delay: 90.ms).slideY(begin: 0.1),
            ],
            const Gap(24),

            // ── Dates ────────────────────────────────────────────────────────
            _sectionTitle('Dates'),
            const Gap(10),
            _DateField(label: 'Date of birth', value: _birthDate,
                onTap: () => _pickDate(true))
                .animate().fadeIn(delay: 260.ms).slideY(begin: 0.1),
            const Gap(10),
            _DateField(label: 'Date of death (if applicable)', value: _deathDate,
                onTap: () => _pickDate(false),
                onClear: _deathDate != null ? () => setState(() => _deathDate = null) : null)
                .animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),
            const Gap(24),

            // ── Additional ───────────────────────────────────────────────────
            _sectionTitle('Additional Details'),
            const Gap(10),
            AppTextField(label: 'Place of birth', controller: _placeOfBirthCtrl,
                prefix: const Icon(Icons.location_on_outlined))
                .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const Gap(10),
            AppTextField(label: 'Notes', controller: _notesCtrl, maxLines: 3)
                .animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),
            const Gap(24),

            // ── Privacy ───────────────────────────────────────────────────────
            _sectionTitle('Privacy'),
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
                title: const Text('Show birth date to verified relatives'),
                subtitle: const Text('Only visible to family members connected in the tree'),
                value: _showBirthDate,
                onChanged: (v) => setState(() => _showBirthDate = v),
                activeColor: AppColors.primary,
              ),
            ).animate().fadeIn(delay: 340.ms),
            const Gap(32),

            // ── Save ─────────────────────────────────────────────────────────
            AppButton(
              label: 'Add Member',
              onPressed: _save,
              isLoading: _isLoading,
            ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.2),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
      );
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

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
              border: Border.all(color: selected ? color : AppColors.border,
                  width: selected ? 2 : 1),
            ),
            child: Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ),
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({required this.label, this.value, required this.onTap, this.onClear});

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
                  color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
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
