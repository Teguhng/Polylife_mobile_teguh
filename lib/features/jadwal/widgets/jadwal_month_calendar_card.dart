import 'package:flutter/material.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';

class JadwalMonthCalendarCard extends StatelessWidget {
  final DateTime monthAnchor;
  final DateTime selectedDate;
  final List<DateTime> monthGridDays;
  final ValueChanged<DateTime> onSelectedDate;
  final int Function(DateTime date) countResolver;
  final JadwalType? Function(DateTime date) dominantTypeResolver;

  const JadwalMonthCalendarCard({
    super.key,
    required this.monthAnchor,
    required this.selectedDate,
    required this.monthGridDays,
    required this.onSelectedDate,
    required this.countResolver,
    required this.dominantTypeResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          const _LegendRow(),
          const SizedBox(height: 10),
          Row(
            children: const [
              _WeekdayLabel('Sen'),
              _WeekdayLabel('Sel'),
              _WeekdayLabel('Rab'),
              _WeekdayLabel('Kam'),
              _WeekdayLabel('Jum'),
              _WeekdayLabel('Sab'),
              _WeekdayLabel('Min'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            itemCount: monthGridDays.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final day = monthGridDays[index];
              final inCurrentMonth = day.month == monthAnchor.month;
              final isSelected = _isSameDay(day, selectedDate);
              final count = countResolver(day);
              final dominantType = dominantTypeResolver(day);
              final dotColor = _dotColor(dominantType);

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelectedDate(day),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? context.appPrimary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    color: isSelected
                        ? context.appPrimarySoft
                        : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: inCurrentMonth
                              ? context.appText
                              : context.appFaint,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (count > 0)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5, width: 5),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _dotColor(JadwalType? type) {
    switch (type) {
      case JadwalType.kuliah:
        return const Color(0xFF10B981);
      case JadwalType.ujian:
        return const Color(0xFFF59E0B);
      case JadwalType.personal:
        return const Color(0xFFEF4444);
      case JadwalType.rapat:
      case JadwalType.tugas:
      case null:
        return const Color(0xFF1F2937);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(label: 'KULIAH', color: Color(0xFF10B981)),
        _LegendItem(label: 'UTS/UAS', color: Color(0xFFF59E0B)),
        _LegendItem(label: 'LIBUR', color: Color(0xFFEF4444)),
        _LegendItem(label: 'KEGIATAN', color: Color(0xFF1F2937)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.appMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;

  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: context.appFaint,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
