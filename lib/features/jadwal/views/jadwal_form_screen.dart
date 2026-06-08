import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';

class JadwalFormScreen extends StatefulWidget {
  final JadwalItem? initialItem;
  final DateTime? initialDate;

  const JadwalFormScreen({super.key, this.initialItem, this.initialDate});

  @override
  State<JadwalFormScreen> createState() => _JadwalFormScreenState();
}

class _JadwalFormScreenState extends State<JadwalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late JadwalType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _completed = false;

  bool get _isEdit => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    final seedDate = item?.startAt ?? widget.initialDate ?? DateTime.now();
    _titleController = TextEditingController(text: item?.title ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _selectedType = item?.type ?? JadwalType.kuliah;
    _selectedDate = DateTime(seedDate.year, seedDate.month, seedDate.day);
    _startTime = TimeOfDay.fromDateTime(item?.startAt ?? DateTime.now());
    _endTime = TimeOfDay.fromDateTime(
      item?.endAt ?? DateTime.now().add(const Duration(hours: 1)),
    );
    _completed = item?.completed ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final startAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!endAt.isAfter(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai harus lebih besar dari jam mulai.'),
        ),
      );
      return;
    }

    final input = JadwalInput(
      title: _titleController.text.trim(),
      type: _selectedType,
      startAt: startAt,
      endAt: endAt,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      completed: _completed,
    );

    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: Text(_isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
        actions: [TextButton(onPressed: _submit, child: const Text('Simpan'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Judul agenda'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Judul wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<JadwalType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Jenis agenda'),
              items: JadwalType.values
                  .map(
                    (type) => DropdownMenuItem<JadwalType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text('Tanggal: $dateLabel'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: true),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('Mulai ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(start: false),
                    icon: const Icon(Icons.schedule_send_outlined),
                    label: Text('Selesai ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Lokasi',
                hintText: 'Contoh: Gedung A / Zoom',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tandai selesai'),
                value: _completed,
                onChanged: (value) => setState(() => _completed = value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
