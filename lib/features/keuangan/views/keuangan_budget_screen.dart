import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/ai/widgets/ai_app_bar_action.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_budget_model.dart';

final NumberFormat _budgetIdr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

const _budgetMonthNames = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

class KeuanganBudgetScreen extends StatefulWidget {
  const KeuanganBudgetScreen({super.key});

  @override
  State<KeuanganBudgetScreen> createState() => _KeuanganBudgetScreenState();
}

class _KeuanganBudgetScreenState extends State<KeuanganBudgetScreen> {
  late int _month = DateTime.now().month;
  late int _year = DateTime.now().year;
  late Future<KeuanganBudgetPeriod> _period = _load(_month, _year);

  Future<KeuanganBudgetPeriod> _load(int month, int year) async {
    final response = await ApiClient.get(
      '/keuangan/anggaran?bulan=$month&tahun=$year&refresh=${DateTime.now().microsecondsSinceEpoch}',
    );
    final payload = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(_message(payload, 'Anggaran belum bisa dimuat.'));
    }
    final data = payload['data'];
    if (data is! Map) {
      throw const FormatException('Format data anggaran tidak dikenali.');
    }
    return KeuanganBudgetPeriod.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _decode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _message(Map<String, dynamic> payload, String fallback) =>
      payload['message']?.toString() ?? fallback;

  void _selectPeriod({int? month, int? year}) {
    setState(() {
      _month = month ?? _month;
      _year = year ?? _year;
      _period = _load(_month, _year);
    });
  }

  Future<void> _refresh() async {
    setState(() => _period = _load(_month, _year));
    try {
      await _period;
    } catch (_) {}
  }

  Future<void> _openForm({String category = '', double? amount}) async {
    final current = await _period
        .then<KeuanganBudgetPeriod?>((value) => value)
        .catchError((_) => null);
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BudgetFormSheet(
        category: category,
        amount: amount,
        suggestions: current?.categorySuggestions ?? const [],
        month: _month,
        year: _year,
      ),
    );
    if (saved == true) {
      await _refresh();
      if (mounted) _showMessage('Plafon anggaran tersimpan.');
    }
  }

  Future<void> _delete(KeuanganBudgetItem item) async {
    final id = item.id;
    if (id == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus plafon?'),
        content: Text(
          'Plafon untuk ${item.category} akan dihapus dari periode ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: context.appDanger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      final response = await ApiClient.delete('/keuangan/anggaran/$id');
      final payload = _decode(response.body);
      if (response.statusCode != 200) {
        throw Exception(_message(payload, 'Plafon gagal dihapus.'));
      }
      await _refresh();
      if (mounted) _showMessage('Plafon anggaran dihapus.');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(6, (index) => DateTime.now().year - index);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Plafon Anggaran',
          style: GoogleFonts.plusJakartaSans(
            color: context.appText,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        actions: [
          const AiAppBarAction(),
          IconButton(
            tooltip: 'Tambah plafon',
            onPressed: () => _openForm(),
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: context.appPrimary,
            ),
          ),
        ],
      ),
      body: FutureBuilder<KeuanganBudgetPeriod>(
        future: _period,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _BudgetError(
              message:
                  snapshot.error?.toString().replaceFirst('Exception: ', '') ??
                  'Anggaran belum bisa dimuat.',
              onRetry: () => _selectPeriod(),
            );
          }
          final data = snapshot.requireData;
          return RefreshIndicator(
            color: context.appPrimary,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _PeriodCard(
                  data: data,
                  month: _month,
                  year: _year,
                  years: years,
                  onMonth: (value) => _selectPeriod(month: value),
                  onYear: (value) => _selectPeriod(year: value),
                ),
                const SizedBox(height: 14),
                _BudgetSummary(data: data),
                const SizedBox(height: 14),
                _BudgetList(
                  data: data,
                  onEdit: (item) =>
                      _openForm(category: item.category, amount: item.limit),
                  onDelete: _delete,
                  onAdd: () => _openForm(),
                ),
                if (data.unbudgetedExpenses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _UnbudgetedCard(
                    items: data.unbudgetedExpenses,
                    onAdd: (item) =>
                        _openForm(category: item.category, amount: item.spent),
                  ),
                ],
                const SizedBox(height: 14),
                const _BudgetTipsCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final KeuanganBudgetPeriod data;
  final int month;
  final int year;
  final List<int> years;
  final ValueChanged<int> onMonth;
  final ValueChanged<int> onYear;

  const _PeriodCard({
    required this.data,
    required this.month,
    required this.year,
    required this.years,
    required this.onMonth,
    required this.onYear,
  });

  @override
  Widget build(BuildContext context) => _BudgetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plafon Anggaran Periode', style: _budgetTitle(context)),
        const SizedBox(height: 4),
        Text(
          'Monitoring pengeluaran per kategori untuk ${data.monthName} ${data.year}',
          style: TextStyle(color: context.appMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                initialValue: month,
                isExpanded: true,
                decoration: _dropdownDecoration(context),
                dropdownColor: context.appSurface,
                style: TextStyle(color: context.appText),
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(
                      _budgetMonthNames[index],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) onMonth(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                initialValue: years.contains(year) ? year : years.first,
                isExpanded: true,
                decoration: _dropdownDecoration(context),
                dropdownColor: context.appSurface,
                style: TextStyle(color: context.appText),
                items: years
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text('$value')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onYear(value);
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BudgetSummary extends StatelessWidget {
  final KeuanganBudgetPeriod data;
  const _BudgetSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final left = data.totalRemaining > 0
        ? data.totalRemaining
        : data.totalOverbudget;
    final leftLabel = data.totalRemaining > 0 ? 'Sisa Anggaran' : 'Kelebihan';
    final statusColor = data.healthStatus.contains('Kritis')
        ? context.appDanger
        : data.healthStatus.contains('Waspada')
        ? context.appWarning
        : context.appSuccess;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Total Plafon',
                value: _budgetIdr.format(data.totalLimit),
                tint: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                label: 'Realisasi Belanja',
                value: _budgetIdr.format(data.totalSpent),
                tint: context.appMuted,
                detail:
                    '${data.overallPercentage.toStringAsFixed(0)}% dari plafon',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: leftLabel,
                value: _budgetIdr.format(left),
                tint: data.totalRemaining > 0
                    ? context.appSuccess
                    : context.appDanger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                label: 'Status Anggaran',
                value: data.healthStatus,
                tint: statusColor,
                detail: '${data.overbudgetCount} pos melewati batas',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;
  final String? detail;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.tint,
    this.detail,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 100),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: tint.withValues(alpha: .18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tint,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: context.appText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 3),
          Text(
            detail!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.appMuted, fontSize: 9),
          ),
        ],
      ],
    ),
  );
}

class _BudgetList extends StatelessWidget {
  final KeuanganBudgetPeriod data;
  final ValueChanged<KeuanganBudgetItem> onEdit;
  final ValueChanged<KeuanganBudgetItem> onDelete;
  final VoidCallback onAdd;
  const _BudgetList({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => _BudgetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Plafon Pos Anggaran',
                    style: _budgetTitle(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau batas pengeluaran setiap bulan.',
                    style: TextStyle(color: context.appMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onAdd,
              tooltip: 'Tambah',
              icon: Icon(Icons.add_circle_outline, color: context.appPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (data.items.isEmpty)
          _EmptyBudgets(onAdd: onAdd)
        else
          ...data.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BudgetItemCard(
                item: item,
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ),
          ),
      ],
    ),
  );
}

class _BudgetItemCard extends StatelessWidget {
  final KeuanganBudgetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BudgetItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = item.status == 'over';
    final isWarning = item.status == 'waspada';
    final color = isOver
        ? context.appDanger
        : isWarning
        ? context.appWarning
        : context.appSuccess;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        color: context.appText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Terpakai ${_budgetIdr.format(item.spent)} dari ${_budgetIdr.format(item.limit)}',
                      style: TextStyle(color: context.appMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isOver
                        ? 'Over ${_budgetIdr.format(item.overbudget)}'
                        : 'Sisa ${_budgetIdr.format(item.remaining)}',
                    style: TextStyle(color: context.appMuted, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (item.percentage / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: context.appBorder,
              color: color,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Ubah'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 15,
                    color: context.appDanger,
                  ),
                  label: Text(
                    'Hapus',
                    style: TextStyle(color: context.appDanger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBudgets({required this.onAdd});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: context.appBorder, style: BorderStyle.solid),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(Icons.savings_outlined, size: 34, color: context.appMuted),
        const SizedBox(height: 8),
        Text(
          'Belum ada plafon anggaran',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Atur batas pengeluaran untuk periode ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Pasang plafon'),
        ),
      ],
    ),
  );
}

class _UnbudgetedCard extends StatelessWidget {
  final List<KeuanganUnbudgetedExpense> items;
  final ValueChanged<KeuanganUnbudgetedExpense> onAdd;
  const _UnbudgetedCard({required this.items, required this.onAdd});

  @override
  Widget build(BuildContext context) => _BudgetCard(
    color: context.appWarning.withValues(alpha: .08),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pos Pengeluaran Belum Beranggaran',
          style: TextStyle(
            color: context.appWarning,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Ada transaksi pengeluaran yang belum memiliki plafon.',
          style: TextStyle(color: context.appMuted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => onAdd(item),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                side: BorderSide(color: context.appBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.category} · ${_budgetIdr.format(item.spent)}',
                      style: TextStyle(color: context.appText, fontSize: 12),
                    ),
                  ),
                  Text(
                    'Pasang +',
                    style: TextStyle(
                      color: context.appPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BudgetTipsCard extends StatelessWidget {
  const _BudgetTipsCard();
  @override
  Widget build(BuildContext context) => _BudgetCard(
    color: context.appPrimarySoft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips Smart Budgeting',
          style: TextStyle(
            color: context.appPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Gunakan aturan 50/30/20: 50% kebutuhan pokok, 30% makan dan pribadi, 20% tabungan.',
          style: TextStyle(color: context.appText, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}

class _BudgetFormSheet extends StatefulWidget {
  final String category;
  final double? amount;
  final List<String> suggestions;
  final int month;
  final int year;
  const _BudgetFormSheet({
    required this.category,
    required this.amount,
    required this.suggestions,
    required this.month,
    required this.year,
  });

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  late final TextEditingController _categoryController = TextEditingController(
    text: widget.category,
  );
  late final TextEditingController _amountController = TextEditingController(
    text: widget.amount == null ? '' : widget.amount!.round().toString(),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _decode(String source) {
    try {
      final value = jsonDecode(source);
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _save() async {
    final category = _categoryController.text.trim();
    final amount =
        int.tryParse(_amountController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (category.isEmpty || amount < 1000) {
      setState(() => _error = 'Isi kategori dan plafon minimal Rp 1.000.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ApiClient.post('/keuangan/anggaran', {
        'kategori': category,
        'nominal_limit': amount,
        'bulan': widget.month,
        'tahun': widget.year,
      });
      final payload = _decode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          payload['message']?.toString() ??
              'Plafon gagal disimpan (HTTP ${response.statusCode}).',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = '${_budgetMonthNames[widget.month - 1]} ${widget.year}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pasang Plafon Anggaran',
                    style: _budgetTitle(context),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              'Atur batas pengeluaran per kategori untuk $period.',
              style: TextStyle(color: context.appMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Text(
              'Kategori Pos Belanja',
              style: TextStyle(
                color: context.appText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration(
                context,
                'Pilih atau ketik kategori',
              ),
            ),
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.suggestions
                    .take(8)
                    .map(
                      (suggestion) => ActionChip(
                        label: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 10),
                        ),
                        onPressed: () => setState(
                          () => _categoryController.text = suggestion,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Plafon Maksimal',
              style: TextStyle(
                color: context.appText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDecoration(context, '0', prefix: 'Rp '),
            ),
            const SizedBox(height: 5),
            Text(
              'Periode: $period',
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: context.appDanger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Plafon Anggaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _BudgetError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_outlined, size: 42, color: context.appMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _BudgetCard({required this.child, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? context.appSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appCardShadow,
    ),
    child: child,
  );
}

InputDecoration _dropdownDecoration(BuildContext context) => InputDecoration(
  isDense: true,
  filled: true,
  fillColor: context.appSurfaceAlt,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: context.appBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: context.appBorder),
  ),
);

InputDecoration _fieldDecoration(
  BuildContext context,
  String hint, {
  String? prefix,
}) => InputDecoration(
  hintText: hint,
  prefixText: prefix,
  filled: true,
  fillColor: context.appSurfaceAlt,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(color: context.appBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(color: context.appBorder),
  ),
);

TextStyle _budgetTitle(BuildContext context) => GoogleFonts.plusJakartaSans(
  color: context.appText,
  fontSize: 17,
  fontWeight: FontWeight.w800,
);
