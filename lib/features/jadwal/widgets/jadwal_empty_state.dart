import 'package:flutter/material.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';

class JadwalEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const JadwalEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_month_outlined, color: context.appMuted),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(color: context.appMuted, height: 1.3),
          ),
        ],
      ),
    );
  }
}
