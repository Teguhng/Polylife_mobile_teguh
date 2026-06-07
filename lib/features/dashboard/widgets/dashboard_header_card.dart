import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';

class DashboardHeaderCard extends StatelessWidget {
  final String userName;

  const DashboardHeaderCard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKSPACE PRODUKTIF',
            style: TextStyle(
              color: context.appMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Halo, $userName',
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel[0].toUpperCase() + dateLabel.substring(1),
            style: TextStyle(
              color: context.appMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _HintPill(icon: Icons.bolt_outlined, text: 'Fokus harian'),
              SizedBox(width: 8),
              _HintPill(icon: Icons.insights_outlined, text: 'Ringkasan cepat'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appPrimarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: context.appPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
