import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetCard extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPickMonth;
  final List<String> sortedCategories;
  final Map<String, double> expensesByCategory;
  final Map<String, double> budgetLimits;
  final String budgetMonth;
  final NumberFormat formatter;
  final Function(String category, double currentLimit) onSetBudgetLimit;

  const BudgetCard({
    super.key,
    required this.monthLabel,
    required this.onPickMonth,
    required this.sortedCategories,
    required this.expensesByCategory,
    required this.budgetLimits,
    required this.budgetMonth,
    required this.formatter,
    required this.onSetBudgetLimit,
  });

  String _budgetKey(String category) {
    return '$budgetMonth|${category.toLowerCase().trim()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Budget Kategori',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onPickMonth,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                child: Text(monthLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sortedCategories.isEmpty)
            const Text(
              'Belum ada pengeluaran pada bulan ini.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            Column(
              children: sortedCategories.map((category) {
                final spent = expensesByCategory[category] ?? 0;
                final limit = budgetLimits[_budgetKey(category)] ?? 0;
                final progress = limit <= 0 ? 0.0 : (spent / limit);
                final overBudget = limit > 0 && spent > limit;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => onSetBudgetLimit(category, limit),
                            child: Text(limit > 0 ? 'Ubah Limit' : 'Set Limit'),
                          ),
                        ],
                      ),
                      Text(
                        limit <= 0
                            ? 'Terpakai ${formatter.format(spent)}'
                            : '${formatter.format(spent)} / ${formatter.format(limit)}',
                        style: TextStyle(
                          color: overBudget
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: overBudget
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        minHeight: 7,
                        value: limit <= 0 ? 0 : progress.clamp(0, 1),
                        borderRadius: BorderRadius.circular(99),
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: overBudget
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF4F46E5),
                      ),
                      if (overBudget)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            'Melebihi budget bulan ini',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
