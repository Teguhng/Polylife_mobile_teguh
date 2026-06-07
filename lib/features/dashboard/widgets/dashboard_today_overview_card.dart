import 'package:flutter/material.dart';

class DashboardTodayOverviewCard extends StatelessWidget {
  final int jadwalTodayCount;
  final int todoOngoingCount;
  final int todoCompletedCount;
  final int pengumumanCount;
  final VoidCallback onOpenJadwal;
  final VoidCallback onOpenTodo;
  final VoidCallback onOpenPengumuman;

  const DashboardTodayOverviewCard({
    super.key,
    required this.jadwalTodayCount,
    required this.todoOngoingCount,
    required this.todoCompletedCount,
    required this.pengumumanCount,
    required this.onOpenJadwal,
    required this.onOpenTodo,
    required this.onOpenPengumuman,
  });

  @override
  Widget build(BuildContext context) {
    final totalTodo = todoOngoingCount + todoCompletedCount;
    final completionRate = totalTodo == 0
        ? 0.0
        : (todoCompletedCount / totalTodo).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TARGET HARI INI',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OverviewPill(
                  label: 'Agenda',
                  value: '$jadwalTodayCount',
                  color: const Color(0xFF4F46E5),
                  icon: Icons.calendar_today_outlined,
                  onTap: onOpenJadwal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewPill(
                  label: 'To-Do Aktif',
                  value: '$todoOngoingCount',
                  color: const Color(0xFFEA580C),
                  icon: Icons.checklist_rounded,
                  onTap: onOpenTodo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Progres To-Do',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$todoCompletedCount / $totalTodo selesai',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onOpenPengumuman,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pengumumanCount == 0
                          ? 'Belum ada pengumuman baru.'
                          : '$pengumumanCount pengumuman siap dibaca.',
                      style: const TextStyle(
                        color: Color(0xFF4338CA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _OverviewPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
