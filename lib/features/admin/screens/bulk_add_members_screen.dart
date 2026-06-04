import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/csv_download.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/providers/tree_provider.dart';

// ── Entry model ──────────────────────────────────────────────────────────────

class _Entry {
  // Paternal four-part name
  final TextEditingController firstName       = TextEditingController();
  final TextEditingController fatherName      = TextEditingController();
  final TextEditingController grandfatherName = TextEditingController();
  final TextEditingController familyName      = TextEditingController();

  // Supporting fields
  final TextEditingController city      = TextEditingController();
  final TextEditingController birthYear = TextEditingController();
  String gender = 'male';

  // Extra CSV-only fields (saved to DB, shown as badges under the row)
  String? motherFirstName;
  String? motherFatherName;
  String? motherGrandfatherName;
  String? motherFamilyName;
  String? placeOfBirth;
  String? notes;

  String get motherFullName {
    final parts = [motherFirstName, motherFatherName,
                   motherGrandfatherName, motherFamilyName]
        .where((p) => p != null && p.isNotEmpty);
    return parts.join(' ');
  }

  bool get hasMother => motherFirstName != null && motherFirstName!.isNotEmpty;

  void dispose() {
    firstName.dispose();
    fatherName.dispose();
    grandfatherName.dispose();
    familyName.dispose();
    city.dispose();
    birthYear.dispose();
  }

  bool get isEmpty => firstName.text.trim().isEmpty;

  Map<String, dynamic> toRow(String familyId) => {
        'family_id': familyId,
        'first_name': firstName.text.trim(),
        'father_name': fatherName.text.trim(),
        'grandfather_name': grandfatherName.text.trim(),
        'family_name': familyName.text.trim(),
        'city': city.text.trim().isEmpty ? 'Unknown' : city.text.trim(),
        'gender': gender,
        if (_parsedYear != null) 'birth_date': '$_parsedYear-01-01',
        if (motherFirstName != null) 'mother_first_name': motherFirstName,
        if (motherFatherName != null) 'mother_father_name': motherFatherName,
        if (motherGrandfatherName != null)
          'mother_grandfather_name': motherGrandfatherName,
        if (motherFamilyName != null) 'mother_family_name': motherFamilyName,
        if (placeOfBirth != null) 'place_of_birth': placeOfBirth,
        if (notes != null) 'notes': notes,
      };

  int? get _parsedYear {
    final y = int.tryParse(birthYear.text.trim());
    if (y == null || y < 1800 || y > DateTime.now().year) return null;
    return y;
  }
}

// ── CSV template & parser ────────────────────────────────────────────────────

const _templateCsv =
    // Required: first_name father_name grandfather_name family_name city gender
    // Optional: birth_year mother_first_name mother_father_name
    //           mother_grandfather_name mother_family_name place_of_birth notes
    'first_name,father_name,grandfather_name,family_name,city,gender,'
    'birth_year,mother_first_name,mother_father_name,mother_grandfather_name,'
    'mother_family_name,place_of_birth,notes\n'
    'Ibrahim,Ahmed,Hassan,Al-Hassan,Tripoli,male,1940,,,,,Tripoli,\n'
    'Fatima,Ali,Hassan,Al-Amin,Tripoli,female,1945,,,,,,\n'
    'Omar,Ibrahim,Ahmed,Al-Hassan,Tripoli,male,1968,'
    'Fatima,Ali,Hassan,Al-Amin,,\n'
    'Amira,Ibrahim,Ahmed,Al-Hassan,Tripoli,female,1972,'
    'Fatima,Ali,Hassan,Al-Amin,,\n'
    'Khalid,Ibrahim,Ahmed,Al-Hassan,Benghazi,male,1975,'
    'Fatima,Ali,Hassan,Al-Amin,Benghazi,\n'
    'Yusuf,Omar,Ibrahim,Al-Hassan,Tripoli,male,1995,'
    'Maryam,Khalid,Saleh,Al-Farsi,,\n'
    'Noor,Omar,Ibrahim,Al-Hassan,Tripoli,female,1998,'
    'Maryam,Khalid,Saleh,Al-Farsi,,\n'
    'Hassan,Khalid,Ibrahim,Al-Hassan,Benghazi,male,2000,'
    'Aisha,Mohammed,Yusuf,Al-Zawi,Benghazi,';

List<_Entry> _csvToEntries(String content) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter(eol: '\n').convert(normalized);
  if (rows.isEmpty) return [];

  final headers =
      rows[0].map((h) => h.toString().trim().toLowerCase()).toList();

  final entries = <_Entry>[];
  for (final row in rows.skip(1)) {
    final m = <String, String>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      final v = row[i].toString().trim();
      if (v.isNotEmpty) m[headers[i]] = v;
    }

    if ((m['first_name'] ?? '').isEmpty) continue;

    final e = _Entry();
    e.firstName.text       = m['first_name'] ?? '';
    e.fatherName.text      = m['father_name'] ?? '';
    e.grandfatherName.text = m['grandfather_name'] ?? '';
    e.familyName.text      = m['family_name'] ?? '';
    e.city.text            = m['city'] ?? '';
    e.birthYear.text       = m['birth_year'] ?? '';
    final g = m['gender']?.toLowerCase() ?? '';
    e.gender       = g == 'female' ? 'female' : 'male';
    e.motherFirstName       = m['mother_first_name'];
    e.motherFatherName      = m['mother_father_name'];
    e.motherGrandfatherName = m['mother_grandfather_name'];
    e.motherFamilyName      = m['mother_family_name'];
    e.placeOfBirth          = m['place_of_birth'];
    e.notes                 = m['notes'];
    entries.add(e);
  }
  return entries;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class BulkAddMembersScreen extends ConsumerStatefulWidget {
  const BulkAddMembersScreen({super.key});

  @override
  ConsumerState<BulkAddMembersScreen> createState() =>
      _BulkAddMembersScreenState();
}

class _BulkAddMembersScreenState extends ConsumerState<BulkAddMembersScreen> {
  List<_Entry> _entries = [_Entry(), _Entry(), _Entry()];
  bool _isSaving    = false;
  bool _isImporting = false;

  @override
  void dispose() {
    for (final e in _entries) e.dispose();
    super.dispose();
  }

  int get _filledCount => _entries.where((e) => !e.isEmpty).length;

  void _addRow() => setState(() => _entries.add(_Entry()));

  void _removeRow(int index) {
    _entries[index].dispose();
    setState(() => _entries.removeAt(index));
  }

  void _showCsvSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CsvSheet(
          onImport: _importCsv, isImporting: _isImporting),
    );
  }

  Future<void> _importCsv() async {
    Navigator.of(context).pop();
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      final content = utf8.decode(result.files.single.bytes!);
      final parsed  = _csvToEntries(content);

      if (parsed.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No valid rows found in file'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      for (final e in _entries) e.dispose();
      setState(() => _entries = parsed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${parsed.length} rows loaded from CSV'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to read file: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _save() async {
    final valid = _entries.where((e) => !e.isEmpty).toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter at least one first name'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final familyId = await ref.read(userFamilyIdProvider.future);
      if (familyId == null) throw Exception('No family found');

      final rows = valid.map((e) => e.toRow(familyId)).toList();
      await ref.read(treeNotifierProvider.notifier).bulkAddMembers(rows);

      final newRels = await ref
          .read(treeNotifierProvider.notifier)
          .autoDetectRelationships();

      if (mounted) {
        final relMsg = newRels > 0
            ? ' — $newRels relationship${newRels == 1 ? '' : 's'} detected'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${valid.length} member${valid.length != 1 ? 's' : ''} added$relMsg'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Add Members'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file_rounded),
              tooltip: 'Import / Template',
              onPressed: _showCsvSheet,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSaving || _filledCount == 0 ? null : _save,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Save ($_filledCount)'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Column headers
          Container(
            color: AppColors.surfaceVariant,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              const SizedBox(width: 48),
              _hdr('First', flex: 2),
              const Gap(4),
              _hdr('Father', flex: 2),
              const Gap(4),
              _hdr('Grand.', flex: 2),
              const Gap(4),
              _hdr('Family', flex: 2),
              const Gap(4),
              _hdr('City', flex: 2),
              const Gap(4),
              _hdr('Year', width: 46),
              const SizedBox(width: 32),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _entries.length + 1,
              itemBuilder: (context, i) {
                if (i == _entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add row'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border)),
                    ),
                  );
                }
                return _EntryRow(
                  key: ObjectKey(_entries[i]),
                  entry: _entries[i],
                  onRemove: _entries.length > 1 ? () => _removeRow(i) : null,
                  onChanged: () => setState(() {}),
                ).animate().fadeIn(delay: (i * 15).ms).slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String text, {int flex = 0, double? width}) {
    final child = Text(text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: AppColors.textTertiary, letterSpacing: 0.4));
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex, child: child);
  }
}

// ── CSV bottom sheet ──────────────────────────────────────────────────────────

class _CsvSheet extends StatelessWidget {
  final VoidCallback onImport;
  final bool isImporting;
  const _CsvSheet({required this.onImport, required this.isImporting});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('CSV Import & Template',
                style: Theme.of(context).textTheme.titleLarge),
            const Gap(4),
            Text(
              'Columns: first_name · father_name · grandfather_name · family_name · city · gender · birth_year',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            const Gap(14),
            _Step(number: '1', text: 'Tap Download Template — opens / saves the .csv file'),
            _Step(number: '2', text: 'Open in Google Sheets or Excel and fill in your family members'),
            _Step(number: '3', text: 'File → Download / Save As → CSV (.csv)'),
            _Step(number: '4', text: 'Tap Import File and select your saved CSV'),
            const Gap(14),
            Text('TEMPLATE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary, letterSpacing: 1.2)),
            const Gap(8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(12)),
                child: SingleChildScrollView(
                  controller: controller,
                  child: SelectableText(
                    _templateCsv,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 11,
                        color: Color(0xFFCDD6F4), height: 1.7),
                  ),
                ),
              ),
            ),
            const Gap(14),
            // Primary actions
            Row(children: [
              Expanded(
                child: _DownloadButton(),
              ),
              const Gap(12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isImporting ? null : onImport,
                  icon: isImporting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Import File'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: AppColors.primary),
                ),
              ),
            ]),
            const Gap(8),
            // Secondary: copy to clipboard
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                      const ClipboardData(text: _templateCsv));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy to clipboard instead'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    textStyle: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  const _DownloadButton();

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      await downloadCsv(_templateCsv, 'shajarah_members_template.csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: _busy ? null : _download,
        icon: _busy
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.download_rounded, size: 18),
        label: const Text('Download Template'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: AppColors.accent,
        ),
      );
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(
                color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: Center(
              child: Text(number,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
        ]),
      );
}

// ── Entry row ─────────────────────────────────────────────────────────────────

class _EntryRow extends StatefulWidget {
  final _Entry entry;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _EntryRow({super.key, required this.entry, required this.onRemove,
      required this.onChanged});

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  @override
  void initState() {
    super.initState();
    widget.entry.firstName.addListener(widget.onChanged);
  }

  @override
  void dispose() {
    widget.entry.firstName.removeListener(widget.onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Dismissible(
      key: ObjectKey(e),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Gender toggle
          GestureDetector(
            onTap: () => setState(() {
              e.gender = e.gender == 'male' ? 'female' : 'male';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36, height: 34,
              decoration: BoxDecoration(
                color: e.gender == 'male' ? AppColors.maleLight : AppColors.femaleLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: e.gender == 'male' ? AppColors.male : AppColors.female),
              ),
              child: Center(
                child: Text(e.gender == 'male' ? '♂' : '♀',
                    style: TextStyle(fontSize: 16,
                        color: e.gender == 'male' ? AppColors.male : AppColors.female)),
              ),
            ),
          ),
          const Gap(4),
          Expanded(flex: 2, child: _CF(ctrl: e.firstName, hint: 'First')),
          const Gap(4),
          Expanded(flex: 2, child: _CF(ctrl: e.fatherName, hint: 'Father')),
          const Gap(4),
          Expanded(flex: 2, child: _CF(ctrl: e.grandfatherName, hint: 'Grand.')),
          const Gap(4),
          Expanded(flex: 2, child: _CF(ctrl: e.familyName, hint: 'Family')),
          const Gap(4),
          Expanded(flex: 2, child: _CF(ctrl: e.city, hint: 'City')),
          const Gap(4),
          SizedBox(
            width: 46,
            child: _CF(
              ctrl: e.birthYear,
              hint: '1970',
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
          ),
          SizedBox(
            width: 32,
            child: widget.onRemove != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        size: 18, color: AppColors.textTertiary),
                    onPressed: widget.onRemove)
                : const SizedBox.shrink(),
          ),
          ]),
          // ── Extra field badges ─────────────────────────────────────────
          if (e.hasMother || e.placeOfBirth != null || e.notes != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 42),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (e.hasMother)
                    _Badge(
                      icon: Icons.woman_rounded,
                      label: e.motherFullName,
                      color: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                    ),
                  if (e.placeOfBirth != null)
                    _Badge(
                      icon: Icons.location_on_outlined,
                      label: e.placeOfBirth!,
                      color: AppColors.primary,
                      bg: AppColors.primaryContainer,
                    ),
                  if (e.notes != null)
                    _Badge(
                      icon: Icons.notes_rounded,
                      label: 'note',
                      color: AppColors.accent,
                      bg: AppColors.accentLight,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.icon, required this.label,
      required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const Gap(3),
          Text(
            label.length > 22 ? '${label.substring(0, 20)}…' : label,
            style: TextStyle(fontSize: 10, color: color,
                fontWeight: FontWeight.w500),
          ),
        ]),
      );
}

class _CF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  const _CF({required this.ctrl, required this.hint,
      this.keyboardType, this.formatters});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );
}
