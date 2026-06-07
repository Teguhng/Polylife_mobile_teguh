import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';

class JadwalItemCard extends StatelessWidget {
  final JadwalItem item;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JadwalItemCard({
    super.key,
    required this.item,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleForType(item.type);
    final timeLabel =
        '${DateFormat('HH:mm').format(item.startAt)} - ${DateFormat('HH:mm').format(item.endAt)}';
    final subtitleSegments = <String>[
      if (item.location.trim().isNotEmpty) item.location.trim(),
      if (item.notes.trim().isNotEmpty) item.notes.trim(),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.completed,
            onChanged: (_) => onToggleCompleted(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: style.bgColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, size: 12, color: style.fgColor),
                          const SizedBox(width: 4),
                          Text(
                            item.type.label,
                            style: TextStyle(
                              color: style.fgColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: context.appMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    decoration: item.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (subtitleSegments.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitleSegments.join(' • '),
                    style: TextStyle(
                      color: item.completed
                          ? context.appFaint
                          : context.appMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Aksi jadwal',
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }

  _JadwalTypeStyle _styleForType(JadwalType type) {
    switch (type) {
      case JadwalType.kuliah:
        return const _JadwalTypeStyle(
          bgColor: Color(0xFFDBEAFE),
          fgColor: Color(0xFF1D4ED8),
          icon: Icons.school_outlined,
        );
      case JadwalType.tugas:
        return const _JadwalTypeStyle(
          bgColor: Color(0xFFFEF3C7),
          fgColor: Color(0xFFB45309),
          icon: Icons.assignment_outlined,
        );
      case JadwalType.ujian:
        return const _JadwalTypeStyle(
          bgColor: Color(0xFFFEE2E2),
          fgColor: Color(0xFFB91C1C),
          icon: Icons.fact_check_outlined,
        );
      case JadwalType.rapat:
        return const _JadwalTypeStyle(
          bgColor: Color(0xFFE0E7FF),
          fgColor: Color(0xFF4338CA),
          icon: Icons.groups_2_outlined,
        );
      case JadwalType.personal:
        return const _JadwalTypeStyle(
          bgColor: Color(0xFFDCFCE7),
          fgColor: Color(0xFF166534),
          icon: Icons.person_outline_rounded,
        );
    }
  }
}

class _JadwalTypeStyle {
  final Color bgColor;
  final Color fgColor;
  final IconData icon;

  const _JadwalTypeStyle({
    required this.bgColor,
    required this.fgColor,
    required this.icon,
  });
}
