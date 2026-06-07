import 'package:flutter/material.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';

class TodoProgressHeaderCard extends StatelessWidget {
  final int totalTasks;
  final VoidCallback onCreateTask;

  const TodoProgressHeaderCard({
    super.key,
    required this.totalTasks,
    required this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ATUR TUGAS KAMU DENGAN RAPI',
            style: TextStyle(
              color: context.appMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau Progress Harian',
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w800,
              fontSize: 34 / 2,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreateTask,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tugas Baru'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.appSurfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total tugas',
                        style: TextStyle(
                          color: context.appMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalTasks',
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 30 / 2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    'Klik kartu kategori di bawah untuk melihat daftar tugas.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: context.appFaint,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
