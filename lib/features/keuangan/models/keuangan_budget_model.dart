class KeuanganBudgetPeriod {
  final int month;
  final int year;
  final String monthName;
  final List<KeuanganBudgetItem> items;
  final List<KeuanganUnbudgetedExpense> unbudgetedExpenses;
  final double totalLimit;
  final double totalSpent;
  final double totalRemaining;
  final double totalOverbudget;
  final double overallPercentage;
  final int overbudgetCount;
  final String healthStatus;
  final List<String> categorySuggestions;

  const KeuanganBudgetPeriod({
    required this.month,
    required this.year,
    required this.monthName,
    required this.items,
    required this.unbudgetedExpenses,
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.totalOverbudget,
    required this.overallPercentage,
    required this.overbudgetCount,
    required this.healthStatus,
    required this.categorySuggestions,
  });

  factory KeuanganBudgetPeriod.fromJson(Map<String, dynamic> json) =>
      KeuanganBudgetPeriod(
        month: _intValue(json['month']),
        year: _intValue(json['year']),
        monthName: (json['month_name'] ?? '').toString(),
        items: _mapList(
          json['items'],
        ).map(KeuanganBudgetItem.fromJson).toList(),
        unbudgetedExpenses: _mapList(
          json['unbudgeted_expenses'],
        ).map(KeuanganUnbudgetedExpense.fromJson).toList(),
        totalLimit: _doubleValue(json['total_limit']),
        totalSpent: _doubleValue(json['total_spent']),
        totalRemaining: _doubleValue(json['total_remaining']),
        totalOverbudget: _doubleValue(json['total_overbudget']),
        overallPercentage: _doubleValue(json['overall_percentage']),
        overbudgetCount: _intValue(json['overbudget_count']),
        healthStatus: (json['health_status'] ?? '').toString(),
        categorySuggestions: _stringList(json['category_suggestions']),
      );
}

class KeuanganBudgetItem {
  final int? id;
  final String category;
  final double limit;
  final double spent;
  final double remaining;
  final double overbudget;
  final double percentage;
  final String status;

  const KeuanganBudgetItem({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.overbudget,
    required this.percentage,
    required this.status,
  });

  factory KeuanganBudgetItem.fromJson(Map<String, dynamic> json) =>
      KeuanganBudgetItem(
        id: _nullableInt(json['id']),
        category: (json['kategori'] ?? '').toString(),
        limit: _doubleValue(json['nominal_limit']),
        spent: _doubleValue(json['actual_spent']),
        remaining: _doubleValue(json['remaining']),
        overbudget: _doubleValue(json['overbudget']),
        percentage: _doubleValue(json['percentage']),
        status: (json['status'] ?? 'aman').toString(),
      );
}

class KeuanganUnbudgetedExpense {
  final String category;
  final double spent;

  const KeuanganUnbudgetedExpense({
    required this.category,
    required this.spent,
  });

  factory KeuanganUnbudgetedExpense.fromJson(Map<String, dynamic> json) =>
      KeuanganUnbudgetedExpense(
        category: (json['kategori'] ?? '').toString(),
        spent: _doubleValue(json['actual_spent']),
      );
}

int _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) => value == null ? null : _intValue(value);
double _doubleValue(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
List<Map<String, dynamic>> _mapList(dynamic value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const <Map<String, dynamic>>[];
List<String> _stringList(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList()
    : const <String>[];
