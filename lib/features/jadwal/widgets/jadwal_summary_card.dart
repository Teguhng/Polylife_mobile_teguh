import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/features/jadwal/services/jadwal_scheduler_service.dart';

class JadwalSummaryCard extends StatelessWidget {
  final DateTime selectedDate;
  final JadwalDayStats stats;

  const JadwalSummaryCard({
    super.key,
    required this.selectedDate,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatPill(
                label: 'Total',
                value: stats.total.toString(),
                bgColor: const Color(0xFFEEF2FF),
                textColor: const Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Akan Datang',
                value: stats.upcoming.toString(),
                bgColor: const Color(0xFFECFDF3),
                textColor: const Color(0xFF166534),
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Selesai',
                value: stats.completed.toString(),
                bgColor: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF475569),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
