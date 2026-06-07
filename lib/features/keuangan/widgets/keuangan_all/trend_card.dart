import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/features/keuangan/widgets/keuangan_all/trend_bar_chart.dart';

class TrendCard extends StatelessWidget {
  final List<double> series;
  final String trendRange;
  final ValueChanged<String> onTrendRangeChanged;
  final NumberFormat formatter;

  const TrendCard({
    super.key,
    required this.series,
    required this.trendRange,
    required this.onTrendRangeChanged,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final maxOut = series.isEmpty ? 0.0 : series.reduce(math.max);

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
                'Tren Pengeluaran',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _buildTrendChip('7d', '7H'),
              const SizedBox(width: 4),
              _buildTrendChip('30d', '30H'),
              const SizedBox(width: 4),
              _buildTrendChip('month', 'Bulan'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 88, child: TrendBarChart(values: series)),
          const SizedBox(height: 6),
          Text(
            'Maks: ${formatter.format(maxOut)}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChip(String value, String label) {
    final selected = trendRange == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTrendRangeChanged(value),
      selectedColor: const Color(0xFFEEF2FF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB),
      ),
      backgroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
