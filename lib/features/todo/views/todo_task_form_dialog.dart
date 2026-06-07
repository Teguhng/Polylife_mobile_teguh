import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/features/todo/models/todo_item.dart';

Future<TodoInput?> showTodoTaskFormDialog(BuildContext context) {
  return showDialog<TodoInput>(
    context: context,
    builder: (context) => const _TodoTaskFormDialog(),
  );
}

class _TodoTaskFormDialog extends StatefulWidget {
  const _TodoTaskFormDialog();

  @override
  State<_TodoTaskFormDialog> createState() => _TodoTaskFormDialogState();
}

class _TodoTaskFormDialogState extends State<_TodoTaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      TodoInput(
        title: _titleController.text.trim(),
        description: '',
        dueDate: _dueDate,
        priority: TodoPriority.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueDate == null
        ? 'Atur deadline (opsional)'
        : DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_dueDate!);

    return AlertDialog(
      title: const Text('To-Do Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama item'),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Nama item wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(dueLabel),
              ),
              if (_dueDate != null)
                TextButton(
                  onPressed: () => setState(() => _dueDate = null),
                  child: const Text('Hapus deadline'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
