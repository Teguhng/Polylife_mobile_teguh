import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';
import 'package:mobile_ver/features/keuangan/providers/keuangan_provider.dart';
import 'package:mobile_ver/features/keuangan/services/keuangan_all_exporter.dart';
import 'package:mobile_ver/features/keuangan/services/keuangan_all_logic.dart';

import 'package:mobile_ver/features/keuangan/models/recurring_template.dart';
import 'package:mobile_ver/features/keuangan/models/bill_reminder_item.dart';
import 'package:mobile_ver/features/keuangan/models/trash_entry.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/summary_card.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/transaction_tile.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/empty_state.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/error_banner.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/trend_card.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/budget_card.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/recurring_card.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/bill_reminder_card.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/filters_bar.dart';

final NumberFormat _allIdrFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class KeuanganAllScreen extends ConsumerStatefulWidget {
  const KeuanganAllScreen({super.key});

  @override
  ConsumerState<KeuanganAllScreen> createState() => _KeuanganAllScreenState();
}

class _KeuanganAllScreenState extends ConsumerState<KeuanganAllScreen> {
  final KeuanganAllLogic _logic = const KeuanganAllLogic();
  final KeuanganAllExporter _exporter = const KeuanganAllExporter();

  bool _isLoading = true;
  String? _errorMessage;
  List<KeuanganTransaction> _items = const [];

  // Quick filter
  String _searchQuery = '';
  String _jenisFilter = 'semua'; // semua | pemasukan | pengeluaran
  String _monthFilter = 'semua'; // semua | yyyy-MM

  // Advanced filter
  DateTimeRange? _dateRangeFilter;
  double? _minNominalFilter;
  double? _maxNominalFilter;
  Set<String> _categoryFilters = <String>{};

  // Budget by category and month (key: yyyy-MM|category-lower)
  final Map<String, double> _budgetLimits = <String, double>{};
  String _budgetMonth = '';

  // Recurring templates
  final List<RecurringTemplate> _recurringTemplates = <RecurringTemplate>[];
  int _nextRecurringId = 1;

  // Bill reminders
  final List<BillReminderItem> _billReminders = <BillReminderItem>[];
  int _nextBillId = 1;

  // Trash and undo
  final List<TrashEntry> _trashEntries = <TrashEntry>[];

  // Trend range
  String _trendRange = '30d'; // 7d | 30d | month

  @override
  void initState() {
    super.initState();
    _seedUtilityDefaults();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ref
          .read(keuanganProvider.notifier)
          .fetchAllTransactions();
      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
        if (_budgetMonth.isEmpty) {
          final months = _availableMonths();
          _budgetMonth = months.isNotEmpty ? months.first : _currentMonthKey();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat semua transaksi keuangan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems();
    final budgetMonth = _resolvedBudgetMonth();
    final expensesByCategory = _expenseByCategory(budgetMonth);
    final sortedCategories = expensesByCategory.keys.toList()
      ..sort(
        (a, b) =>
            (expensesByCategory[b] ?? 0).compareTo(expensesByCategory[a] ?? 0),
      );
    final advancedFilterCount = _advancedFilterCount();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: const Text('Semua Keuangan'),
        actions: [
          IconButton(
            tooltip: 'Filter lanjutan',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (advancedFilterCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        advancedFilterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openAdvancedFilterSheet,
          ),
          IconButton(
            tooltip: 'Ekspor',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _openExportSheet(filteredItems),
          ),
          IconButton(
            tooltip: 'Sampah',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.delete_outline_rounded),
                if (_trashEntries.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _trashEntries.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openTrashSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null) ...[
                    AllErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  FiltersBar(
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    jenisFilter: _jenisFilter,
                    onJenisChanged: (value) =>
                        setState(() => _jenisFilter = value),
                    monthFilterLabel: _monthFilterLabel(_monthFilter),
                    onMonthFilterPressed: _showMonthFilterPicker,
                  ),
                  const SizedBox(height: 12),
                  TrendCard(
                    series: _buildTrendSeries(filteredItems),
                    trendRange: _trendRange,
                    onTrendRangeChanged: (value) =>
                        setState(() => _trendRange = value),
                    formatter: _allIdrFormatter,
                  ),
                  const SizedBox(height: 12),
                  BudgetCard(
                    monthLabel: _monthFilterLabel(budgetMonth),
                    onPickMonth: _pickBudgetMonth,
                    sortedCategories: sortedCategories,
                    expensesByCategory: expensesByCategory,
                    budgetLimits: _budgetLimits,
                    budgetMonth: budgetMonth,
                    formatter: _allIdrFormatter,
                    onSetBudgetLimit: (cat, limit) =>
                        _setBudgetLimit(budgetMonth, cat, limit),
                  ),
                  const SizedBox(height: 12),
                  RecurringCard(
                    recurringTemplates: _recurringTemplates,
                    onAddRecurring: _addRecurringTemplate,
                    onProcessDue: _processDueRecurring,
                    onToggleActive: (item) => setState(() {}),
                    onRunNow: _runRecurringTemplate,
                    formatter: _allIdrFormatter,
                  ),
                  const SizedBox(height: 12),
                  BillReminderCard(
                    billReminders: _billReminders,
                    onAddBillReminder: _addBillReminder,
                    onPayBill: _payBill,
                    formatter: _allIdrFormatter,
                  ),
                  const SizedBox(height: 12),
                  if (filteredItems.isEmpty)
                    AllEmptyState(
                      message: _items.isEmpty
                          ? 'Belum ada data transaksi.'
                          : 'Tidak ada transaksi sesuai filter.',
                    )
                  else ...[
                    AllSummaryCard(
                      items: filteredItems,
                      formatter: _allIdrFormatter,
                    ),
                    const SizedBox(height: 14),
                    ..._buildGroupedByMonth(filteredItems),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _showMonthFilterPicker() async {
    final months = _availableMonths();

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Filter Bulan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                title: const Text('Semua Bulan'),
                trailing: _monthFilter == 'semua'
                    ? const Icon(Icons.check, color: Color(0xFF4F46E5))
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _monthFilter = 'semua';
                  });
                },
              ),
              ...months.map((monthKey) {
                final selected = _monthFilter == monthKey;
                return ListTile(
                  title: Text(_monthFilterLabel(monthKey)),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF4F46E5))
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _monthFilter = monthKey;
                    });
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickBudgetMonth() async {
    final months = _availableMonths();
    if (months.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Pilih Bulan Budget',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ...months.map((monthKey) {
                final selected = _resolvedBudgetMonth() == monthKey;
                return ListTile(
                  title: Text(_monthFilterLabel(monthKey)),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF4F46E5))
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _budgetMonth = monthKey;
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setBudgetLimit(
    String month,
    String category,
    double currentLimit,
  ) async {
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );

    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Budget: $category'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Limit budget',
              prefixText: 'Rp ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(0),
              child: const Text('Hapus'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = _parseMoney(controller.text);
                Navigator.of(ctx).pop(parsed);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      final key = _budgetKey(month, category);
      if (result <= 0) {
        _budgetLimits.remove(key);
      } else {
        _budgetLimits[key] = result;
      }
    });
  }

  Future<void> _openAdvancedFilterSheet() async {
    final categories = _availableCategories();
    DateTimeRange? tempRange = _dateRangeFilter;
    Set<String> tempCategories = <String>{..._categoryFilters};
    final minController = TextEditingController(
      text: _minNominalFilter?.toStringAsFixed(0) ?? '',
    );
    final maxController = TextEditingController(
      text: _maxNominalFilter?.toStringAsFixed(0) ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Filter Lanjutan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: tempRange,
                        );
                        if (range == null) return;
                        setModal(() {
                          tempRange = range;
                        });
                      },
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        tempRange == null
                            ? 'Pilih rentang tanggal'
                            : '${DateFormat('dd MMM yyyy').format(tempRange!.start)} - ${DateFormat('dd MMM yyyy').format(tempRange!.end)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Nominal Min',
                              prefixText: 'Rp ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Nominal Max',
                              prefixText: 'Rp ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.map((category) {
                        final selected = tempCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (value) {
                            setModal(() {
                              if (value) {
                                tempCategories.add(category);
                              } else {
                                tempCategories.remove(category);
                              }
                            });
                          },
                          selectedColor: const Color(0xFFEEF2FF),
                          checkmarkColor: const Color(0xFF4F46E5),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _dateRangeFilter = null;
                                _minNominalFilter = null;
                                _maxNominalFilter = null;
                                _categoryFilters = <String>{};
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _dateRangeFilter = tempRange;
                                _minNominalFilter = _parseMoney(
                                  minController.text,
                                );
                                _maxNominalFilter = _parseMoney(
                                  maxController.text,
                                );
                                _categoryFilters = tempCategories;
                              });
                            },
                            child: const Text('Terapkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    minController.dispose();
    maxController.dispose();
  }

  Future<void> _openExportSheet(List<KeuanganTransaction> rows) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text(
                  'Ekspor Data',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Ekspor CSV (copy clipboard)'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final csv = _buildCsv(rows);
                  await Clipboard.setData(ClipboardData(text: csv));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CSV berhasil disalin ke clipboard.'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Ekspor PDF (ringkasan text)'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final text = _buildPdfStyleReport(rows);
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ringkasan PDF-style disalin. Bisa ditempel ke generator PDF.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTrashSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModal) {
              return ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text(
                      'Sampah (${_trashEntries.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: TextButton(
                      onPressed: _trashEntries.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _trashEntries.clear();
                              });
                              setModal(() {});
                            },
                      child: const Text('Kosongkan'),
                    ),
                  ),
                  if (_trashEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada transaksi di sampah.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ..._trashEntries.map((entry) {
                      return ListTile(
                        leading: const Icon(Icons.restore_from_trash_outlined),
                        title: Text(entry.item.kategori),
                        subtitle: Text(
                          '${entry.item.jenis} • ${_allIdrFormatter.format(entry.item.nominal)}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await _restoreTrashEntry(entry);
                            if (context.mounted) {
                              setModal(() {});
                            }
                          },
                          child: const Text('Pulihkan'),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteWithUndo(KeuanganTransaction item) async {
    setState(() {
      _items = _items.where((row) => row.id != item.id).toList();
      _trashEntries.insert(
        0,
        TrashEntry(item: item, deletedAt: DateTime.now()),
      );
    });

    final success = await ref
        .read(keuanganProvider.notifier)
        .deleteTransaction(item.id);
    if (!success) {
      setState(() {
        _items = [item, ..._items];
        _trashEntries.removeWhere((entry) => entry.item.id == item.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus transaksi.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaksi "${item.kategori}" dihapus.'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            final entry = _trashEntries.firstWhere(
              (row) => row.item.id == item.id,
              orElse: () => TrashEntry(item: item, deletedAt: DateTime.now()),
            );
            _restoreTrashEntry(entry);
          },
        ),
      ),
    );
  }

  Future<void> _restoreTrashEntry(TrashEntry entry) async {
    final success = await ref
        .read(keuanganProvider.notifier)
        .createTransaction(
          jenis: entry.item.jenis,
          kategori: entry.item.kategori,
          deskripsi: entry.item.deskripsi,
          nominal: entry.item.nominal,
          tanggal: entry.item.tanggal,
        );

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memulihkan transaksi.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _trashEntries.removeWhere((row) => row.item.id == entry.item.id);
    });
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dipulihkan.')),
    );
  }

  Future<void> _addRecurringTemplate() async {
    final kategoriController = TextEditingController();
    final nominalController = TextEditingController();
    String jenis = 'pengeluaran';
    String frequency = 'monthly';
    DateTime nextRun = DateTime.now();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return AlertDialog(
              title: const Text('Tambah Transaksi Berulang'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: jenis,
                      items: const [
                        DropdownMenuItem(
                          value: 'pemasukan',
                          child: Text('Pemasukan'),
                        ),
                        DropdownMenuItem(
                          value: 'pengeluaran',
                          child: Text('Pengeluaran'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModal(() {
                          jenis = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Jenis'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: kategoriController,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nominalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Harian')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Mingguan'),
                        ),
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Bulanan'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModal(() {
                          frequency = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Frekuensi'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextRun,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setModal(() {
                          nextRun = picked;
                        });
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        DateFormat('dd MMM yyyy', 'id_ID').format(nextRun),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) {
      kategoriController.dispose();
      nominalController.dispose();
      return;
    }

    final nominal = _parseMoney(nominalController.text);
    final kategori = kategoriController.text.trim();
    kategoriController.dispose();
    nominalController.dispose();

    if (nominal == null || nominal <= 0 || kategori.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Template tidak valid.')));
      return;
    }

    setState(() {
      _recurringTemplates.add(
        RecurringTemplate(
          id: _nextRecurringId++,
          jenis: jenis,
          kategori: kategori,
          nominal: nominal,
          frequency: frequency,
          nextRun: nextRun,
          active: true,
        ),
      );
    });
  }

  Future<void> _runRecurringTemplate(RecurringTemplate template) async {
    if (!template.active) return;

    final success = await ref
        .read(keuanganProvider.notifier)
        .createTransaction(
          jenis: template.jenis,
          kategori: template.kategori,
          deskripsi: 'Transaksi berulang (${template.frequencyLabel})',
          nominal: template.nominal,
          tanggal: template.nextRun,
        );

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menjalankan template berulang.')),
      );
      return;
    }

    setState(() {
      template.nextRun = _advanceRecurringDate(
        template.nextRun,
        template.frequency,
      );
    });
    await _load();
  }

  Future<void> _processDueRecurring() async {
    final now = DateTime.now();
    bool anyCreated = false;

    for (final template in _recurringTemplates) {
      if (!template.active) continue;

      while (!template.nextRun.isAfter(now)) {
        final success = await ref
            .read(keuanganProvider.notifier)
            .createTransaction(
              jenis: template.jenis,
              kategori: template.kategori,
              deskripsi: 'Transaksi berulang (${template.frequencyLabel})',
              nominal: template.nominal,
              tanggal: template.nextRun,
            );
        if (!success) break;

        anyCreated = true;
        template.nextRun = _advanceRecurringDate(
          template.nextRun,
          template.frequency,
        );
      }
    }

    if (anyCreated) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berulang berhasil diproses.')),
      );
    }
  }

  DateTime _advanceRecurringDate(DateTime base, String frequency) {
    return _logic.advanceRecurringDate(base: base, frequency: frequency);
  }

  Future<void> _addBillReminder() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return AlertDialog(
              title: const Text('Tambah Reminder Tagihan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama tagihan',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setModal(() {
                          dueDate = picked;
                        });
                      },
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(
                        DateFormat('dd MMM yyyy', 'id_ID').format(dueDate),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) {
      nameController.dispose();
      amountController.dispose();
      return;
    }

    final amount = _parseMoney(amountController.text);
    final name = nameController.text.trim();
    nameController.dispose();
    amountController.dispose();

    if (name.isEmpty || amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder tidak valid.')));
      return;
    }

    setState(() {
      _billReminders.add(
        BillReminderItem(
          id: _nextBillId++,
          name: name,
          amount: amount,
          dueDate: dueDate,
          paid: false,
        ),
      );
    });
  }

  Future<void> _payBill(BillReminderItem item) async {
    final success = await ref
        .read(keuanganProvider.notifier)
        .createTransaction(
          jenis: 'pengeluaran',
          kategori: item.name,
          deskripsi: 'Pembayaran tagihan',
          nominal: item.amount,
          tanggal: DateTime.now(),
        );

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mencatat pembayaran tagihan.')),
      );
      return;
    }

    setState(() {
      item.paid = true;
    });
    await _load();
  }

  List<KeuanganTransaction> _filteredItems() {
    return _logic.filterItems(
      items: _items,
      searchQuery: _searchQuery,
      jenisFilter: _jenisFilter,
      monthFilter: _monthFilter,
      dateRangeFilter: _dateRangeFilter,
      minNominalFilter: _minNominalFilter,
      maxNominalFilter: _maxNominalFilter,
      categoryFilters: _categoryFilters,
    );
  }

  List<double> _buildTrendSeries(List<KeuanganTransaction> source) {
    return _logic.buildTrendSeries(
      source: source,
      trendRange: _trendRange,
      monthFilter: _monthFilter,
      currentMonthKey: _currentMonthKey(),
    );
  }

  List<String> _availableCategories() {
    return _logic.availableCategories(_items);
  }

  List<String> _availableMonths() {
    return _logic.availableMonths(_items);
  }

  String _monthFilterLabel(String monthKey) {
    return _logic.monthFilterLabel(monthKey);
  }

  String _resolvedBudgetMonth() {
    return _logic.resolvedBudgetMonth(
      budgetMonth: _budgetMonth,
      monthFilter: _monthFilter,
      items: _items,
      currentMonthKey: _currentMonthKey(),
    );
  }

  Map<String, double> _expenseByCategory(String monthKey) {
    return _logic.expenseByCategory(items: _items, monthKey: monthKey);
  }

  String _budgetKey(String month, String category) {
    return _logic.budgetKey(month, category);
  }

  double? _parseMoney(String raw) {
    return _exporter.parseMoney(raw);
  }

  int _advancedFilterCount() {
    return _logic.advancedFilterCount(
      dateRangeFilter: _dateRangeFilter,
      minNominalFilter: _minNominalFilter,
      maxNominalFilter: _maxNominalFilter,
      categoryFilters: _categoryFilters,
    );
  }

  String _buildCsv(List<KeuanganTransaction> rows) {
    return _exporter.buildCsv(rows);
  }

  String _buildPdfStyleReport(List<KeuanganTransaction> rows) {
    return _exporter.buildPdfStyleReport(
      rows: rows,
      formatter: _allIdrFormatter,
    );
  }

  String _currentMonthKey() {
    return _exporter.currentMonthKey();
  }

  void _seedUtilityDefaults() {
    if (_recurringTemplates.isEmpty) {
      _recurringTemplates.addAll([
        RecurringTemplate(
          id: _nextRecurringId++,
          jenis: 'pengeluaran',
          kategori: 'Kost/Sewa',
          nominal: 750000,
          frequency: 'monthly',
          nextRun: DateTime(DateTime.now().year, DateTime.now().month, 1),
          active: true,
        ),
        RecurringTemplate(
          id: _nextRecurringId++,
          jenis: 'pengeluaran',
          kategori: 'Internet',
          nominal: 200000,
          frequency: 'monthly',
          nextRun: DateTime(DateTime.now().year, DateTime.now().month, 10),
          active: true,
        ),
      ]);
    }

    if (_billReminders.isEmpty) {
      _billReminders.addAll([
        BillReminderItem(
          id: _nextBillId++,
          name: 'Tagihan Listrik',
          amount: 150000,
          dueDate: DateTime(DateTime.now().year, DateTime.now().month, 20),
          paid: false,
        ),
        BillReminderItem(
          id: _nextBillId++,
          name: 'Tagihan Internet',
          amount: 200000,
          dueDate: DateTime(DateTime.now().year, DateTime.now().month, 25),
          paid: false,
        ),
      ]);
    }
  }

  List<Widget> _buildGroupedByMonth(List<KeuanganTransaction> rows) {
    final grouped = <String, List<KeuanganTransaction>>{};
    for (final row in rows) {
      final key = DateFormat('yyyy-MM').format(row.tanggal);
      grouped.putIfAbsent(key, () => <KeuanganTransaction>[]).add(row);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final key in sortedKeys) {
      final dt = DateTime.parse('$key-01');
      final title = DateFormat('MMMM yyyy', 'id_ID').format(dt);
      final items = grouped[key] ?? const <KeuanganTransaction>[];

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title[0].toUpperCase() + title.substring(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      );

      for (final item in items) {
        widgets.add(
          Dismissible(
            key: ValueKey(
              'all-keu-${item.id}-${item.tanggal.toIso8601String()}',
            ),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => _deleteWithUndo(item),
            child: AllTransactionTile(item: item, formatter: _allIdrFormatter),
          ),
        );
      }

      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }
}

// Extracted to separate files
