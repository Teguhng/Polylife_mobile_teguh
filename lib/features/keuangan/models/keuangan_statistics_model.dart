class KeuanganAnnualStatistics {
  final int year;
  final List<int> yearOptions;
  final List<String> labels;
  final List<double> incomeByMonth;
  final List<double> expensesByMonth;
  final List<double> netByMonth;
  final List<double> balanceByMonth;
  final double totalIncome;
  final double totalExpenses;
  final double totalNet;
  final double averageIncome;
  final double averageExpenses;
  final double savingsRate;
  final bool isDeficit;
  final String projectionLabel;
  final double yearEndProjection;
  final Map<String, double> topExpenseCategories;
  final Map<String, double> topIncomeCategories;
  // Retained for compatibility with Flutter hot reload in existing sessions.
  // The anomaly section is no longer displayed in the statistics UI.
  final List<KeuanganAnomaly> anomalies;
  final List<String> suggestions;

  const KeuanganAnnualStatistics({
    required this.year,
    required this.yearOptions,
    required this.labels,
    required this.incomeByMonth,
    required this.expensesByMonth,
    required this.netByMonth,
    required this.balanceByMonth,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalNet,
    required this.averageIncome,
    required this.averageExpenses,
    required this.savingsRate,
    required this.isDeficit,
    required this.projectionLabel,
    required this.yearEndProjection,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
    required this.anomalies,
    required this.suggestions,
  });

  factory KeuanganAnnualStatistics.fromJson(Map<String, dynamic> json) {
    return KeuanganAnnualStatistics(
      year: _intValue(json['tahun']),
      yearOptions: _intList(json['tahun_options']),
      labels: _stringList(json['labels']),
      incomeByMonth: _doubleList(json['seriesPemasukan']),
      expensesByMonth: _doubleList(json['seriesPengeluaran']),
      netByMonth: _doubleList(json['seriesNet']),
      balanceByMonth: _doubleList(json['cumulativeSaldo']),
      totalIncome: _doubleValue(json['totalPemasukan']),
      totalExpenses: _doubleValue(json['totalPengeluaran']),
      totalNet: _doubleValue(json['totalNet']),
      averageIncome: _doubleValue(json['avgPemasukan']),
      averageExpenses: _doubleValue(json['avgPengeluaran']),
      savingsRate: _doubleValue(json['savingsRate']),
      isDeficit: json['isDefisit'] == true,
      projectionLabel: (json['proyeksiLabel'] ?? 'Proyeksi Akhir Tahun')
          .toString(),
      yearEndProjection: _doubleValue(json['proyeksiAkhirTahun']),
      topExpenseCategories: _amountMap(json['topKategoriPengeluaran']),
      topIncomeCategories: _amountMap(json['topKategoriPemasukan']),
      anomalies: _mapList(
        json['anomali'],
      ).map(KeuanganAnomaly.fromJson).toList(),
      suggestions: _stringList(json['saran']),
    );
  }
}

class KeuanganAnomaly {
  final String month;
  final double expense;
  final double threshold;

  const KeuanganAnomaly({
    required this.month,
    required this.expense,
    required this.threshold,
  });

  factory KeuanganAnomaly.fromJson(Map<String, dynamic> json) {
    return KeuanganAnomaly(
      month: (json['bulan'] ?? '').toString(),
      expense: _doubleValue(json['nilai']),
      threshold: _doubleValue(json['batas']),
    );
  }
}

int _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _doubleValue(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

List<double> _doubleList(dynamic value) =>
    value is List ? value.map(_doubleValue).toList() : const <double>[];

List<int> _intList(dynamic value) =>
    value is List ? value.map(_intValue).toList() : const <int>[];

List<String> _stringList(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList()
    : const <String>[];

List<Map<String, dynamic>> _mapList(dynamic value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const <Map<String, dynamic>>[];

Map<String, double> _amountMap(dynamic value) {
  if (value is! Map) return const <String, double>{};
  final totals = <String, double>{};
  final labels = <String, String>{};
  for (final entry in value.entries) {
    final normalized = entry.key.toString().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized.isEmpty) continue;
    final key = normalized.toLowerCase();
    labels.putIfAbsent(key, () => _titleCaseCategory(normalized));
    totals[key] = (totals[key] ?? 0) + _doubleValue(entry.value);
  }
  return {for (final entry in totals.entries) labels[entry.key]!: entry.value};
}

String _titleCaseCategory(String value) => value
    .split(' ')
    .map(
      (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    )
    .join(' ');
