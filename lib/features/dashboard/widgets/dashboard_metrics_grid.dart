import 'package:flutter/material.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';

class DashboardMetric {
  final String title;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardMetric({
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
    this.onTap,
  });
}

class DashboardMetricsGrid extends StatelessWidget {
  final List<DashboardMetric> metrics;

  const DashboardMetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN MODUL',
            style: TextStyle(
              color: context.appMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: metrics.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.42,
            ),
            itemBuilder: (context, index) {
              return _MetricCard(metric: metrics[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final DashboardMetric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: metric.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: metric.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: metric.color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: metric.color.withValues(alpha: 0.2),
                  child: Icon(metric.icon, size: 14, color: metric.color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    metric.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: metric.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              metric.value,
              style: TextStyle(
                color: context.appText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              metric.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
