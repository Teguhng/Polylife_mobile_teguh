import 'package:flutter/material.dart';

import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/widgets/jadwal_empty_state.dart';
import 'package:mobile_ver/features/jadwal/widgets/jadwal_item_card.dart';

class JadwalAgendaFeedSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<JadwalItem> items;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<JadwalItem> onToggleCompleted;
  final ValueChanged<JadwalItem> onEdit;
  final ValueChanged<JadwalItem> onDelete;

  const JadwalAgendaFeedSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAFTAR AGENDA',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${items.length} item',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (items.isEmpty)
            JadwalEmptyState(title: emptyTitle, subtitle: emptySubtitle)
          else
            ...items.map(
              (item) => JadwalItemCard(
                item: item,
                onToggleCompleted: () => onToggleCompleted(item),
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ),
        ],
      ),
    );
  }
}
