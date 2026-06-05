import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../claims/providers/claim_provider.dart';
import '../../tree/providers/tree_provider.dart';

class NameEntryScreen extends ConsumerStatefulWidget {
  const NameEntryScreen({super.key});

  @override
  ConsumerState<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends ConsumerState<NameEntryScreen> {
  final _first = TextEditingController();
  final _father = TextEditingController();
  final _grand = TextEditingController();
  final _family = TextEditingController();
  final _clan = TextEditingController();
  final _city = TextEditingController();
  final _place = TextEditingController();
  String _gender = 'male';
  DateTime? _birthDate;
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_first, _father, _grand, _family, _clan, _city, _place]) c.dispose();
    super.dispose();
  }

  String get _fullName => [_first.text, _father.text, _grand.text, _family.text]
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ');

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
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _submit() async {
    if ([_first, _father, _grand, _family, _city].any((c) => c.text.trim().isEmpty)) {
      _toast('أكمل اسمك الرباعي والمدينة');
      return;
    }
    setState(() => _loading = true);
    try {
      // ── 1. Is this person already in a tree? Offer to claim instead of duplicating.
      final matches = await ref.read(claimNotifierProvider.notifier).findMatches(
            _first.text.trim(), _father.text.trim(), _grand.text.trim(),
            _family.text.trim(), _city.text.trim());
      final claimable = matches.where((m) => !m.claimed).toList();
      if (claimable.isNotEmpty && mounted) {
        setState(() => _loading = false);
        final picked = await _showClaimSheet(claimable);
        if (picked != null) {
          setState(() => _loading = true);
          await ref.read(claimNotifierProvider.notifier).requestClaim(picked.id);
          if (mounted) context.go('/pending');
          return;
        }
        setState(() => _loading = true); // "not me" → create new
      }

      // ── 2. Create a fresh profile (join existing tribe family or create it).
      final supabase = ref.read(supabaseProvider);
      final familyName = _family.text.trim();
      final fullName = _fullName;
      try {
        await supabase.rpc('join_family_by_name',
            params: {'p_family_name': familyName, 'p_full_name': fullName});
      } catch (_) {
        await supabase.rpc('setup_profile',
            params: {'p_family_name': familyName, 'p_full_name': fullName});
      }
      final profile = await supabase.from('user_profiles').select('family_id')
          .eq('id', ref.read(currentUserProvider)!.id).single();
      final familyId = profile['family_id'] as String;

      final member = await ref.read(treeNotifierProvider.notifier).addMember(
            familyId: familyId,
            firstName: _first.text.trim(),
            fatherName: _father.text.trim(),
            grandfatherName: _grand.text.trim(),
            familyName: familyName,
            clanName: _clan.text.trim().isEmpty ? null : _clan.text.trim(),
            city: _city.text.trim(),
            gender: _gender,
            birthDate: _birthDate,
            placeOfBirth: _place.text.trim().isEmpty ? null : _place.text.trim(),
            photoUrl: _photoUrl,
          );
      await ref.read(treeNotifierProvider.notifier).linkUserToMember(member.id);
      final detected = await ref.read(treeNotifierProvider.notifier).autoDetectRelationships();

      if (!mounted) return;
      context.go(detected > 0 ? '/smart-link' : '/tree-reveal', extra: detected > 0 ? member.id : null);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ClaimMatch?> _showClaimSheet(List<ClaimMatch> matches) {
    return showModalBottomSheet<ClaimMatch>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              const Leaf(size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('وجدناك في الشجرة', style: brand(size: 20, weight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text('يبدو أن أحد أفراد عائلتك أضافك مسبقًا. اختر ملفك لربط حسابك به (بعد موافقة المشرف) بدلًا من إنشاء نسخة مكررة.',
                style: ui(size: 13.5, color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 16),
            ...matches.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    Avatar(char: m.firstName.isNotEmpty ? m.firstName.characters.first : '؟', size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.fullName, style: brand(size: 15, weight: FontWeight.w600)),
                        Text('عائلة ${m.familyLabel} · ${m.city}', style: ui(size: 12, color: AppColors.muted)),
                      ]),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, m),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14)),
                      child: const Text('هذا أنا'),
                    ),
                  ]),
                )),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('لا، أنشئ ملفًا جديدًا', style: ui(size: 13.5, weight: FontWeight.w600, color: AppColors.muted)),
              ),
            ),
          ]),
        ),
      ),
    );
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
    return OnboardingShell(
      step: 1,
      footer: PrimaryButton('متابعة', loading: _loading, onPressed: _submit),
      child: ListView(children: [
        const SizedBox(height: 4),
        Text('ما اسمك الكامل؟', style: brand(size: 27, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('الاسم الرباعي يحمل نسبك — منه نربط والدك وإخوتك تلقائيًا.',
            style: ui(size: 14.5, color: AppColors.muted, height: 1.6)),
        const SizedBox(height: 16),

        // optional photo
        Center(
          child: GestureDetector(
            onTap: _uploadingPhoto ? null : _pickPhoto,
            child: Column(children: [
              Stack(children: [
                Avatar(char: _first.text.isNotEmpty ? _first.text.characters.first : null, photoUrl: _photoUrl, size: 84),
                PositionedDirectional(
                  bottom: 0, end: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                    child: _uploadingPhoto
                        ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryInk))
                        : const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primaryInk),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text('صورة (اختياري)', style: ui(size: 11.5, color: AppColors.faint)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        _GenderToggle(value: _gender, onChanged: (g) => setState(() => _gender = g)),
        const SizedBox(height: 16),

        // live full-name preview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: AppColors.glow, blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اسمك الكامل',
                style: ui(size: 11, weight: FontWeight.w600, color: AppColors.primaryInk.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text(_fullName.isEmpty ? 'اكتب اسمك الرباعي…' : _fullName,
                style: brand(size: 19, weight: FontWeight.w600,
                    color: _fullName.isEmpty ? AppColors.primaryInk.withValues(alpha: 0.5) : AppColors.primaryInk)),
          ]),
        ),
        const SizedBox(height: 18),

        Row(children: [
          Expanded(child: AppField(label: 'الاسم', controller: _first, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 12),
          Expanded(child: AppField(label: 'اسم الأب', controller: _father, onChanged: (_) => setState(() {}))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppField(label: 'اسم الجد', controller: _grand, onChanged: (_) => setState(() {}))),
          const SizedBox(width: 12),
          Expanded(child: AppField(label: 'العائلة (اللقب)', controller: _family, onChanged: (_) => setState(() {}))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppField(label: 'القبيلة', controller: _clan)),
          const SizedBox(width: 12),
          Expanded(child: AppField(label: 'المدينة', controller: _city)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _DateField(label: 'تاريخ الميلاد', value: _birthDate, onTap: _pickBirthDate)),
          const SizedBox(width: 12),
          Expanded(child: AppField(label: 'مكان الميلاد', controller: _place, hint: 'اختياري')),
        ]),
        const SizedBox(height: 8),
        Text('القبيلة والمدينة تمنعان الخلط بين العائلات المتشابهة، وتُستخدمان للبحث عن الأقارب في عائلات أخرى.',
            style: ui(size: 11, color: AppColors.faint, height: 1.5)),
        const SizedBox(height: 20),
      ]),
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

class _GenderToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _GenderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String g, String label) {
      final on = value == g;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(g),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: ui(size: 14, weight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? AppColors.primaryInk : AppColors.muted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(13)),
      child: Row(children: [seg('male', 'ذكر'), seg('female', 'أنثى')]),
    );
  }
}
