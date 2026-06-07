import 'package:flutter/material.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/widgets/todo_task_tile.dart';

class TodoCategorySection extends StatelessWidget {
  final Color accentColor;
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final List<TodoItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<TodoItem> onToggleCompleted;
  final ValueChanged<TodoItem> onDelete;

  const TodoCategorySection({
    super.key,
    required this.accentColor,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggleExpanded,
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'KATEGORI',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                    fontSize: 30 / 2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count tugas',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.appFaint,
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            if (items.isEmpty)
              _EmptyBox(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
              )
            else
              ...items.map(
                (item) => TodoTaskTile(
                  item: item,
                  onToggleCompleted: onToggleCompleted,
                  onDelete: onDelete,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.appPrimarySoft,
            child: Icon(icon, color: context.appPrimary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMuted, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
