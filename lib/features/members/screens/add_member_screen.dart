import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/providers/tree_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _first = TextEditingController();
  final _father = TextEditingController();
  final _grand = TextEditingController();
  final _family = TextEditingController();
  final _clan = TextEditingController();
  final _mother = TextEditingController();
  final _city = TextEditingController();
  final _place = TextEditingController();
  String _gender = 'male';
  DateTime? _birthDate;
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _showBirth = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_first, _father, _grand, _family, _clan, _mother, _city, _place]) c.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(treeNotifierProvider.notifier).pickAndUploadPhoto();
      if (url != null) setState(() => _photoUrl = url);
    } catch (e) {
      _toast('تعذّر رفع الصورة: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _submit() async {
    if ([_first, _father, _grand, _family, _city].any((c) => c.text.trim().isEmpty)) {
      _toast('أكمل الاسم الرباعي والمدينة');
      return;
    }
    setState(() => _loading = true);
    try {
      final familyId = await ref.read(userFamilyIdProvider.future);
      if (familyId == null) throw Exception('لا توجد عائلة');
      final mp = _mother.text.trim().split(RegExp(r'\s+'));
      await ref.read(treeNotifierProvider.notifier).addMember(
            familyId: familyId,
            firstName: _first.text.trim(),
            fatherName: _father.text.trim(),
            grandfatherName: _grand.text.trim(),
            familyName: _family.text.trim(),
            clanName: _clan.text.trim().isEmpty ? null : _clan.text.trim(),
            city: _city.text.trim(),
            gender: _gender,
            motherFirstName: mp.isNotEmpty && mp[0].isNotEmpty ? mp[0] : null,
            motherFatherName: mp.length > 1 ? mp[1] : null,
            motherGrandfatherName: mp.length > 2 ? mp[2] : null,
            motherFamilyName: mp.length > 3 ? mp.sublist(3).join(' ') : null,
            birthDate: _birthDate,
            placeOfBirth: _place.text.trim().isEmpty ? null : _place.text.trim(),
            photoUrl: _photoUrl,
            showBirthDate: _showBirth,
          );
      final n = await ref.read(treeNotifierProvider.notifier).autoDetectRelationships();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(n > 0 ? 'أُضيف الفرد · اكتُشفت $n صلة' : 'أُضيف الفرد',
            textAlign: TextAlign.right),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
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
    return AppScreen(
      title: 'إضافة فرد',
      leading: RoundButton('back', onTap: () => context.pop()),
      child: ListView(children: [
        const SizedBox(height: 4),
        // optional photo
        Center(
          child: GestureDetector(
            onTap: _uploadingPhoto ? null : _pickPhoto,
            child: Stack(children: [
              Avatar(char: _first.text.isNotEmpty ? _first.text.characters.first : null, photoUrl: _photoUrl, size: 76),
              PositionedDirectional(
                bottom: 0, end: 0,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                  child: _uploadingPhoto
                      ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryInk))
                      : const Icon(Icons.camera_alt_rounded, size: 13, color: AppColors.primaryInk),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: AppField(label: 'الاسم', controller: _first)),
          const SizedBox(width: 10),
          Expanded(child: AppField(label: 'اسم الأب', controller: _father)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: AppField(label: 'اسم الجد', controller: _grand)),
          const SizedBox(width: 10),
          Expanded(child: AppField(label: 'العائلة (اللقب)', controller: _family)),
        ]),
        const SizedBox(height: 10),
        AppField(label: 'القبيلة', controller: _clan, hint: 'اختياري — للبحث عبر العائلات'),
        const SizedBox(height: 12),

        // gender (functional)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(13)),
          child: Row(children: [
            _seg('ذكر', 'male'),
            _seg('أنثى', 'female'),
          ]),
        ),
        const SizedBox(height: 12),

        // auto-link hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(AppIcons.of('sparkle'), size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text('ستُكتشف صلات القرابة تلقائيًا بعد الإضافة، اعتمادًا على اسم الأب والجد والقبيلة والمدينة.',
                  style: ui(size: 12.5, color: AppColors.ink, height: 1.6)),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        AppField(
          label: 'اسم الأم (للنسب الأمومي)',
          controller: _mother,
          hint: 'اختياري — مخفي عن غير الأقارب',
          badge: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(AppIcons.of('lock'), size: 13, color: AppColors.muted),
            const SizedBox(width: 3),
            Text('خاص', style: ui(size: 11, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        AppField(label: 'المدينة', controller: _city),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _DateField(label: 'تاريخ الميلاد', value: _birthDate, onTap: _pickBirthDate)),
          const SizedBox(width: 10),
          Expanded(child: AppField(label: 'مكان الميلاد', controller: _place, hint: 'اختياري')),
        ]),
        const SizedBox(height: 12),
        AppCard(
          pad: 4,
          child: SettingRow(
            icon: 'calendar',
            title: 'إظهار تاريخ الميلاد',
            sub: 'للأقارب الموثّقين فقط',
            last: true,
            trailing: AppToggle(value: _showBirth, onChanged: (v) => setState(() => _showBirth = v)),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton('إضافة إلى الشجرة', loading: _loading, onPressed: _submit),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _seg(String label, String g) {
    final on = _gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: ui(size: 14, weight: on ? FontWeight.w700 : FontWeight.w600, color: on ? AppColors.primaryInk : AppColors.muted)),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: ui(size: 12.5, weight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 7),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: value != null ? AppColors.primary : AppColors.line, width: 1.5),
          ),
          child: Row(children: [
            Icon(AppIcons.of('calendar'), size: 17, color: AppColors.faint),
            const SizedBox(width: 8),
            Text(value != null ? '${value!.day}/${value!.month}/${value!.year}' : 'اختياري',
                style: ui(size: 15, weight: value != null ? FontWeight.w600 : FontWeight.w400, color: value != null ? AppColors.ink : AppColors.faint)),
          ]),
        ),
      ),
    ]);
  }
}
