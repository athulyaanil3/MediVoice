import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/medicine_catalog.dart';
import '../theme/app_theme.dart';
import '../utils/reminder_time.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Opens the medicine editor. Returns a snackbar message when saved, or null if dismissed.
Future<void> showMedicineEditorSheet(
  BuildContext context, {
  Medicine? existing,
}) async {
  final catalog = context.read<MedicineCatalog>();

  final message = await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MedicineEditorSheet(
      existing: existing,
      catalog: catalog,
    ),
  );

  if (!context.mounted || message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

class _MedicineEditorSheet extends StatefulWidget {
  const _MedicineEditorSheet({
    required this.existing,
    required this.catalog,
  });

  final Medicine? existing;
  final MedicineCatalog catalog;

  @override
  State<_MedicineEditorSheet> createState() => _MedicineEditorSheetState();
}

class _MedicineEditorSheetState extends State<_MedicineEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtr;
  late final TextEditingController _dosageCtr;
  late final TextEditingController _notesCtr;
  late final TextEditingController _stockCtr;
  late final TextEditingController _perDoseCtr;

  late final List<String> _times;
  late final List<String> _selectedDays;
  late bool _trackInventory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtr = TextEditingController(text: e?.name ?? '');
    _dosageCtr = TextEditingController(text: e?.dosage ?? '');
    _notesCtr = TextEditingController(text: e?.notes ?? '');
    _stockCtr = TextEditingController(
      text: e != null && e.stock > 0 ? '${e.stock}' : '',
    );
    _perDoseCtr = TextEditingController(
      text: e != null && e.dailyDose > 0 ? '${e.dailyDose}' : '',
    );
    _times = List<String>.from(
      normalizeReminderTimes(e?.reminderTimes ?? []),
    );
    _selectedDays = List<String>.from(e?.repeatDays ?? []);
    _trackInventory = e != null && (e.stock > 0 || e.dailyDose > 0);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _dosageCtr.dispose();
    _notesCtr.dispose();
    _stockCtr.dispose();
    _perDoseCtr.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || picked == null) return;
    final formatted = formatReminderTime(picked);
    if (_times.contains(formatted)) return;
    setState(() => _times.add(formatted));
  }

  void _selectEveryDay() {
    setState(() {
      _selectedDays
        ..clear()
        ..addAll(_weekdays);
    });
  }

  int _parseStock() {
    if (!_trackInventory) return 0;
    return int.tryParse(_stockCtr.text.trim()) ?? 0;
  }

  int _parsePerDose() {
    if (!_trackInventory) return 0;
    final stock = _parseStock();
    if (stock <= 0) return 0;
    return int.tryParse(_perDoseCtr.text.trim()) ?? 1;
  }

  Future<void> _save() async {

    try {

      if (_saving) return;

      if (!_formKey.currentState!.validate()) {
        return;
      }

      final timesToSave =
      normalizeReminderTimes(_times);

      if (timesToSave.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Add at least one reminder time.',
            ),
          ),
        );

        return;
      }

      setState(() => _saving = true);

      final repeatDays =
      _selectedDays.isEmpty
          ? List<String>.from(_weekdays)
          : List<String>.from(_selectedDays);

      final stock = _parseStock();
      final perDose = _parsePerDose();

      String? warning;

      if (widget.existing != null) {

        warning =
        await widget.catalog.replaceMedicine(

          widget.existing!,

          name: _nameCtr.text.trim(),
          dosage: _dosageCtr.text.trim(),
          reminderTimes: timesToSave,
          repeatDays: repeatDays,
          stock: stock,
          dailyDose: perDose,
          notes: _notesCtr.text.trim(),
        );

      } else {

        warning =
        await widget.catalog.addMedicine(

          name: _nameCtr.text.trim(),
          dosage: _dosageCtr.text.trim(),
          reminderTimes: timesToSave,
          repeatDays: repeatDays,
          stock: stock,
          dailyDose: perDose,
          notes: _notesCtr.text.trim(),
        );
      }

      if (!mounted) return;

      setState(() => _saving = false);

      Navigator.pop(
        context,
        warning ??
            'Medicine saved successfully',
      );

    } catch (e) {

      debugPrint("SAVE ERROR: $e");

      if (mounted) {

        setState(() => _saving = false);

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              'Error: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.inkMuted.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existing == null ? 'Add medicine' : 'Edit medicine',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepTeal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Name and at least one reminder time are required.',
                        style: TextStyle(color: AppTheme.inkMuted, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Medicine'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameCtr,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Medicine name *',
                          hintText: 'e.g. Paracetamol',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter the medicine name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _dosageCtr,
                        decoration: const InputDecoration(
                          labelText: 'How much to take (optional)',
                          hintText: 'e.g. 1 tablet, 500 mg, 5 ml',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('Reminders'),
                      const SizedBox(height: 6),
                      const Text(
                        'When should we remind you?',
                        style: TextStyle(color: AppTheme.inkMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickTime,
                        icon: const Icon(Icons.schedule_rounded, size: 20),
                        label: const Text('Add time'),
                      ),
                      const SizedBox(height: 10),
                      if (_times.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.mintGlow.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'No times yet — tap “Add time” for each dose (e.g. 8:00 AM, 8:00 PM).',
                            style: TextStyle(color: AppTheme.inkMuted, fontSize: 13, height: 1.4),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in _times)
                            Chip(
                              label: Text(displayReminderTime(t)),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: _saving
                                    ? null
                                    : () => setState(() => _times.remove(t)),
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Repeat on',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          TextButton(
                            onPressed: _saving ? null : _selectEveryDay,
                            child: const Text('Every day'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final day in _weekdays)
                            FilterChip(
                              label: Text(day),
                              selected: _selectedDays.contains(day),
                              onSelected: _saving
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedDays.add(day);
                                        } else {
                                          _selectedDays.remove(day);
                                        }
                                      });
                                    },
                            ),
                        ],
                      ),
                      if (_selectedDays.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'If none selected, reminders run every day.',
                            style: TextStyle(color: AppTheme.inkMuted, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Track pill count',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Optional — get low-stock alerts when supply runs down',
                          style: TextStyle(color: AppTheme.inkMuted, fontSize: 13),
                        ),
                        value: _trackInventory,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _trackInventory = v),
                      ),
                      if (_trackInventory) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockCtr,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Units left',
                                  hintText: 'e.g. 30',
                                ),
                                validator: (v) {
                                  if (!_trackInventory) return null;
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n < 0) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _perDoseCtr,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Per reminder',
                                  hintText: 'Usually 1',
                                ),
                                validator: (v) {
                                  if (!_trackInventory) return null;
                                  final stock = int.tryParse(_stockCtr.text.trim());
                                  if (stock == null || stock <= 0) return null;
                                  if (v == null || v.trim().isEmpty) return null;
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n < 1) return 'At least 1';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _sectionLabel('Notes (optional)'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notesCtr,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Take with food, doctor instructions…',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.existing == null ? 'Save medicine' : 'Update medicine',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppTheme.deepTeal,
      letterSpacing: 0.6,
    ),
  );
}
