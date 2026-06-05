import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/csv_download.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/providers/tree_provider.dart';

const _template =
    'first_name,father_name,grandfather_name,family_name,clan_name,city,gender,birth_year,mother_full_name\n'
    'أحمد,عبدالله,محمد,الحسن,العتيبي,طرابلس,male,1990,فاطمة علي الزروق\n'
    'سالم,عبدالله,محمد,الحسن,العتيبي,طرابلس,male,1992,فاطمة علي الزروق\n'
    'نورة,محمد,سالم,الحسن,العتيبي,طرابلس,female,1965,\n';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _fileName;
  List<Map<String, String>> _rows = [];
  bool _busy = false;

  static const _cols = [
    ('first_name', 'الاسم'),
    ('father_name', 'اسم الأب'),
    ('grandfather_name', 'اسم الجد'),
    ('family_name', 'العائلة'),
    ('clan_name', 'القبيلة'),
    ('city', 'المدينة'),
  ];

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv', 'txt'], withData: true);
    if (res == null || res.files.single.bytes == null) return;
    final text = utf8.decode(res.files.single.bytes!).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final table = const CsvToListConverter(eol: '\n').convert(text);
    if (table.isEmpty) return;
    final headers = table.first.map((h) => h.toString().trim().toLowerCase()).toList();
    final rows = <Map<String, String>>[];
    for (final r in table.skip(1)) {
      final m = <String, String>{};
      for (var i = 0; i < headers.length && i < r.length; i++) {
        final v = r[i].toString().trim();
        if (v.isNotEmpty) m[headers[i]] = v;
      }
      if ((m['first_name'] ?? '').isNotEmpty) rows.add(m);
    }
    setState(() {
      _fileName = res.files.single.name;
      _rows = rows;
    });
  }

  Future<void> _import() async {
    if (_rows.isEmpty) return;
    setState(() => _busy = true);
    try {
      final familyId = await ref.read(userFamilyIdProvider.future);
      if (familyId == null) throw Exception('لا توجد عائلة');
      final payload = _rows.map((m) {
        final mp = (m['mother_full_name'] ?? '').split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
        final y = int.tryParse(m['birth_year'] ?? '');
        return {
          'family_id': familyId,
          'first_name': m['first_name'],
          'father_name': m['father_name'] ?? '',
          'grandfather_name': m['grandfather_name'] ?? '',
          'family_name': m['family_name'] ?? '',
          if ((m['clan_name'] ?? '').isNotEmpty) 'clan_name': m['clan_name'],
          'city': (m['city'] ?? '').isEmpty ? 'غير معروف' : m['city'],
          'gender': (m['gender'] ?? 'male') == 'female' ? 'female' : 'male',
          if (y != null && y > 1800) 'birth_date': '$y-01-01',
          if (mp.isNotEmpty) 'mother_first_name': mp[0],
          if (mp.length > 1) 'mother_father_name': mp[1],
          if (mp.length > 2) 'mother_grandfather_name': mp[2],
          if (mp.length > 3) 'mother_family_name': mp.sublist(3).join(' '),
        };
      }).toList();
      await ref.read(treeNotifierProvider.notifier).bulkAddMembers(payload);
      final n = await ref.read(treeNotifierProvider.notifier).autoDetectRelationships();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('أُضيف ${_rows.length} فردًا · اكتُشفت $n صلة', textAlign: TextAlign.right),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e', textAlign: TextAlign.right),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _fileName != null;
    return AppScreen(
      title: 'استيراد CSV',
      leading: RoundButton('back', onTap: () => context.pop()),
      trailing: RoundButton('upload', onTap: () => downloadCsv(_template, 'shajarah_template.csv')),
      child: ListView(children: [
        const SizedBox(height: 4),
        // dropzone
        GestureDetector(
          onTap: _pick,
          child: DottedBorderBox(
            child: Column(children: [
              Container(
                width: 48, height: 48, alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
                child: Icon(AppIcons.of('upload'), size: 24, color: AppColors.accent),
              ),
              const SizedBox(height: 8),
              Text(loaded ? _fileName! : 'اختر ملف CSV', style: ui(size: 14.5, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(loaded ? 'تم رفع الملف · ${_rows.length} صفًا' : 'اضغط للاختيار من جهازك', style: ui(size: 12, color: AppColors.muted)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        const SectionTitle('مطابقة الأعمدة'),
        AppCard(
          pad: 4,
          child: Column(children: [
            for (var i = 0; i < _cols.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                decoration: BoxDecoration(
                  border: i == _cols.length - 1 ? null : const Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(children: [
                  Expanded(child: Text(_cols[i].$1, style: ui(size: 13, color: AppColors.muted))),
                  Icon(AppIcons.of('back'), size: 15, color: AppColors.faint),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_cols[i].$2, textAlign: TextAlign.left, style: ui(size: 13.5, weight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  Icon(AppIcons.of('check'), size: 16, color: AppColors.primary),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(AppIcons.of('sparkle'), size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(child: Text('ستُكتشف صلات القرابة تلقائيًا بعد الاستيراد.', style: ui(size: 12.5, height: 1.6))),
          ]),
        ),
        const SizedBox(height: 20),
        PrimaryButton(loaded ? 'استيراد ${_rows.length} فردًا' : 'اختر ملفًا أولًا',
            loading: _busy, onPressed: loaded ? _import : null),
        const SizedBox(height: 30),
      ]),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DottedPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: child,
        ),
      );
}

class _DottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.faint
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(16));
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DottedPainter o) => false;
}
