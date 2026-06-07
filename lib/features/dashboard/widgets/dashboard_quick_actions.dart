import 'package:flutter/material.dart';

class DashboardQuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class DashboardQuickActions extends StatelessWidget {
  final List<DashboardQuickAction> actions;

  const DashboardQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
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
            'AKSES CEPAT',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions.map((action) {
              return _QuickActionButton(action: action);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final DashboardQuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: action.color.withValues(alpha: 0.15),
                child: Icon(action.icon, size: 16, color: action.color),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
