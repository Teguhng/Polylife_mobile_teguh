import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import '../models/catatan_model.dart';
import '../providers/catatan_provider.dart';
import 'package:intl/intl.dart';

enum CatatanFormResult { created, updated }

class CatatanFormScreen extends ConsumerStatefulWidget {
  final Catatan? catatan;

  const CatatanFormScreen({super.key, this.catatan});

  @override
  ConsumerState<CatatanFormScreen> createState() => _CatatanFormScreenState();
}

class _CatatanFormScreenState extends ConsumerState<CatatanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _isiController;
  late DateTime _selectedDate;
  late bool _showPreview;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.catatan?.judul ?? '');
    _isiController = TextEditingController(text: widget.catatan?.isi ?? '');
    _showPreview = widget.catatan?.showPreview ?? false;

    if (widget.catatan != null) {
      try {
        _selectedDate = DateTime.parse(widget.catatan!.tanggal);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final notifier = ref.read(catatanProvider.notifier);

    bool success;
    if (widget.catatan == null) {
      success = await notifier.createCatatan(
        _judulController.text,
        _isiController.text,
        formattedDate,
        _showPreview,
      );
    } else {
      success = await notifier.updateCatatan(
        widget.catatan!.id,
        _judulController.text,
        _isiController.text,
        formattedDate,
        _showPreview,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(
        context,
        widget.catatan == null
            ? CatatanFormResult.created
            : CatatanFormResult.updated,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan catatan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: Text(widget.catatan == null ? 'Buat Catatan' : 'Edit Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _judulController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Catatan',
                        hintText: 'Masukkan judul',
                      ),
                      validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _isiController,
                      decoration: const InputDecoration(
                        labelText: 'Isi Catatan',
                        hintText: 'Tuliskan detail catatan Anda di sini...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 12,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: SwitchListTile.adaptive(
                        value: _showPreview,
                        onChanged: (value) =>
                            setState(() => _showPreview = value),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tampilkan preview di daftar catatan',
                          style: TextStyle(
                            color: context.appText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          'Jika dimatikan, isi catatan tidak dipakai sebagai cuplikan di list maupun cache preview lokal.',
                          style: TextStyle(color: context.appMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
