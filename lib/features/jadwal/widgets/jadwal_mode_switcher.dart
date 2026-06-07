import 'package:flutter/material.dart';

class JadwalModeOption {
  final String key;
  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;

  const JadwalModeOption({
    required this.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
  });
}

class JadwalModeSwitcher extends StatelessWidget {
  final String selectedKey;
  final List<JadwalModeOption> options;
  final ValueChanged<String> onSelected;

  const JadwalModeSwitcher({
    super.key,
    required this.selectedKey,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MODE TAMPILAN',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = option.key == selectedKey;
              return InkWell(
                onTap: () => onSelected(option.key),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? option.accentColor.withValues(alpha: 0.12)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? option.accentColor.withValues(alpha: 0.4)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option.icon,
                        size: 14,
                        color: selected
                            ? option.accentColor
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option.label,
                        style: TextStyle(
                          color: selected
                              ? option.accentColor
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? option.accentColor.withValues(alpha: 0.2)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${option.count}',
                          style: TextStyle(
                            color: selected
                                ? option.accentColor
                                : const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
