import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';
import 'package:mobile_ver/features/keuangan/providers/keuangan_provider.dart';
import 'package:mobile_ver/features/keuangan/services/keuangan_all_exporter.dart';
import 'package:mobile_ver/features/keuangan/utils/category_icon_resolver.dart';

class KeuanganFormScreen extends ConsumerStatefulWidget {
  final KeuanganTransaction? transaction;
  final String? initialJenis;

  const KeuanganFormScreen({super.key, this.transaction, this.initialJenis});

  @override
  ConsumerState<KeuanganFormScreen> createState() => _KeuanganFormScreenState();
}

class _KeuanganFormScreenState extends ConsumerState<KeuanganFormScreen> {
  static const List<_CategoryPreset> _expenseCategoryPresets = [
    _CategoryPreset('Transport', Icons.directions_car_outlined),
    _CategoryPreset('Bensin', Icons.local_gas_station_outlined),
    _CategoryPreset('Parkir', Icons.local_parking_outlined),
    _CategoryPreset('Makan', Icons.restaurant_outlined),
    _CategoryPreset('Kopi', Icons.local_cafe_outlined),
    _CategoryPreset('Belanja', Icons.shopping_bag_outlined),
    _CategoryPreset('Groceries', Icons.local_grocery_store_outlined),
    _CategoryPreset('Buku', Icons.menu_book_outlined),
    _CategoryPreset('Alat Tulis', Icons.edit_note_outlined),
    _CategoryPreset('Kuliah', Icons.school_outlined),
    _CategoryPreset('Kost/Sewa', Icons.home_work_outlined),
    _CategoryPreset('Listrik', Icons.bolt_outlined),
    _CategoryPreset('Air', Icons.water_drop_outlined),
    _CategoryPreset('Internet', Icons.wifi_outlined),
    _CategoryPreset('Pulsa', Icons.phone_android_outlined),
    _CategoryPreset('Kesehatan', Icons.health_and_safety_outlined),
    _CategoryPreset('Obat', Icons.medication_outlined),
    _CategoryPreset('Olahraga', Icons.fitness_center_outlined),
    _CategoryPreset('Hiburan', Icons.movie_outlined),
    _CategoryPreset('Gaming', Icons.sports_esports_outlined),
    _CategoryPreset('Langganan', Icons.subscriptions_outlined),
    _CategoryPreset('Donasi', Icons.volunteer_activism_outlined),
    _CategoryPreset('Cicilan', Icons.request_quote_outlined),
    _CategoryPreset('Asuransi', Icons.shield_outlined),
    _CategoryPreset('Pajak', Icons.receipt_long_outlined),
    _CategoryPreset('Tagihan', Icons.receipt_outlined),
    _CategoryPreset('Lainnya', Icons.receipt_long_outlined),
  ];

  static const List<_CategoryPreset> _incomeCategoryPresets = [
    _CategoryPreset('Gaji', Icons.payments_outlined),
    _CategoryPreset('Uang Saku', Icons.attach_money),
    _CategoryPreset('THR', Icons.card_giftcard_outlined),
    _CategoryPreset('Tunjangan', Icons.payments_outlined),
    _CategoryPreset('Honor', Icons.payments_outlined),
    _CategoryPreset('Freelance', Icons.work_outline),
    _CategoryPreset('Jasa/Konsultasi', Icons.work_outline),
    _CategoryPreset('Beasiswa', Icons.workspace_premium_outlined),
    _CategoryPreset('Hibah/Bantuan', Icons.workspace_premium_outlined),
    _CategoryPreset('Bonus', Icons.card_giftcard_outlined),
    _CategoryPreset('Hadiah Lomba', Icons.emoji_events_outlined),
    _CategoryPreset('Investasi', Icons.trending_up_outlined),
    _CategoryPreset('Dividen/Bunga', Icons.trending_up_outlined),
    _CategoryPreset('Tabungan', Icons.savings_outlined),
    _CategoryPreset('Komisi/Affiliate', Icons.point_of_sale_outlined),
    _CategoryPreset('Penjualan', Icons.storefront_outlined),
    _CategoryPreset('Jual Barang Bekas', Icons.inventory_2_outlined),
    _CategoryPreset('Royalti/Lisensi', Icons.monetization_on_outlined),
    _CategoryPreset('Sewa Aset', Icons.account_balance_wallet_outlined),
    _CategoryPreset(
      'Sponsorship/Donasi Masuk',
      Icons.volunteer_activism_outlined,
    ),
    _CategoryPreset('Hadiah', Icons.redeem_outlined),
    _CategoryPreset('Refund', Icons.replay_outlined),
    _CategoryPreset('Reimburse', Icons.replay_outlined),
    _CategoryPreset('Lainnya', Icons.account_balance_wallet_outlined),
  ];

  final _formKey = GlobalKey<FormState>();
  final KeuanganAllExporter _moneyParser = const KeuanganAllExporter();
  late final TextEditingController _kategoriController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _nominalController;
  late String _jenis;
  late DateTime _tanggal;
  late IconData _selectedKategoriIcon;
  bool _isSaving = false;

  bool get _isEdit => widget.transaction != null;
  List<_CategoryPreset> get _activeCategoryPresets =>
      _jenis == 'pemasukan' ? _incomeCategoryPresets : _expenseCategoryPresets;

  @override
  void initState() {
    super.initState();

    final trx = widget.transaction;
    _jenis = trx?.jenis ?? widget.initialJenis ?? 'pemasukan';
    _tanggal = trx?.tanggal ?? DateTime.now();

    _kategoriController = TextEditingController(text: trx?.kategori ?? '');
    _deskripsiController = TextEditingController(text: trx?.deskripsi ?? '');
    _nominalController = TextEditingController(
      text: trx == null ? '' : _initialNominalText(trx.nominal),
    );
    _selectedKategoriIcon = resolveKeuanganCategoryIcon(
      kategori: _kategoriController.text,
      jenis: _jenis,
      emptyFallback: Icons.category_outlined,
    );
  }

  @override
  void dispose() {
    _kategoriController.dispose();
    _deskripsiController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _tanggal = picked);
  }

  Future<void> _pickKategoriPreset() async {
    final selected = await showModalBottomSheet<_CategoryPreset>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  'Pilih Kategori ${_jenis == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran'}',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ..._activeCategoryPresets.map((preset) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF475569),
                    child: Icon(preset.icon),
                  ),
                  title: Text(preset.label),
                  onTap: () => Navigator.of(ctx).pop(preset),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final nextValue = selected.label;
    setState(() {
      _kategoriController.text = nextValue;
      _kategoriController.selection = TextSelection.collapsed(
        offset: nextValue.length,
      );
      _selectedKategoriIcon = resolveKeuanganCategoryIcon(
        kategori: nextValue,
        jenis: _jenis,
        emptyFallback: Icons.category_outlined,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = _parseNominal(_nominalController.text);
    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal tidak valid.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(keuanganProvider.notifier);
    final success = _isEdit
        ? await notifier.updateTransaction(
            id: widget.transaction!.id,
            jenis: _jenis,
            kategori: _kategoriController.text,
            deskripsi: _deskripsiController.text,
            nominal: nominal,
            tanggal: _tanggal,
          )
        : await notifier.createTransaction(
            jenis: _jenis,
            kategori: _kategoriController.text,
            deskripsi: _deskripsiController.text,
            nominal: nominal,
            tanggal: _tanggal,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Transaksi diperbarui.' : 'Transaksi ditambahkan.',
          ),
          backgroundColor: const Color(0xFF166534),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal menyimpan transaksi.'),
        backgroundColor: Color(0xFFB91C1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy').format(_tanggal);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _jenis,
              decoration: const InputDecoration(labelText: 'Jenis'),
              items: const [
                DropdownMenuItem(value: 'pemasukan', child: Text('Pemasukan')),
                DropdownMenuItem(
                  value: 'pengeluaran',
                  child: Text('Pengeluaran'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _jenis = value;
                        _selectedKategoriIcon = resolveKeuanganCategoryIcon(
                          kategori: _kategoriController.text,
                          jenis: _jenis,
                          emptyFallback: Icons.category_outlined,
                        );
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kategoriController,
              enabled: !_isSaving,
              onChanged: (value) {
                setState(() {
                  _selectedKategoriIcon = resolveKeuanganCategoryIcon(
                    kategori: value,
                    jenis: _jenis,
                    emptyFallback: Icons.category_outlined,
                  );
                });
              },
              decoration: InputDecoration(
                labelText: 'Kategori',
                hintText: 'Contoh: Makan, Gaji, Transport',
                suffixIcon: IconButton(
                  tooltip: 'Pilih ikon kategori',
                  icon: Icon(_selectedKategoriIcon),
                  onPressed: _isSaving ? null : _pickKategoriPreset,
                ),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Kategori wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nominalController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                hintText: 'Contoh: 50000',
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Nominal wajib diisi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _isSaving ? null : _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dateText),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deskripsiController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Catatan tambahan transaksi',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  String _initialNominalText(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  double? _parseNominal(String raw) {
    return _moneyParser.parseMoney(raw);
  }
}

class _CategoryPreset {
  final String label;
  final IconData icon;

  const _CategoryPreset(this.label, this.icon);
}
