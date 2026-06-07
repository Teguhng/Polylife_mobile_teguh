import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/providers/todo_provider.dart';
import 'package:mobile_ver/features/todo/views/todo_task_form_dialog.dart';
import 'package:mobile_ver/features/todo/widgets/todo_category_section.dart';
import 'package:mobile_ver/features/todo/widgets/todo_progress_header_card.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoProvider);
    final notifier = ref.read(todoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                children: [
                  if (state.errorMessage != null) ...[
                    _ErrorBanner(message: state.errorMessage!),
                    const SizedBox(height: 10),
                  ],
                  TodoProgressHeaderCard(
                    totalTasks: state.items.length,
                    onCreateTask: () => _openTaskDialog(context, ref),
                  ),
                  const SizedBox(height: 14),
                  TodoCategorySection(
                    accentColor: const Color(0xFF4F46E5),
                    title: 'Tugas Berlangsung',
                    count: state.ongoingItems.length,
                    expanded: state.ongoingExpanded,
                    onToggleExpanded: notifier.toggleOngoingExpanded,
                    items: state.ongoingItems,
                    emptyIcon: Icons.playlist_add_check_rounded,
                    emptyTitle:
                        'Belum ada tugas berlangsung, klik + Tugas Baru untuk mulai membuat daftar.',
                    emptySubtitle: '',
                    onToggleCompleted: notifier.toggleCompleted,
                    onDelete: (item) => _confirmDelete(context, ref, item),
                  ),
                  const SizedBox(height: 14),
                  TodoCategorySection(
                    accentColor: const Color(0xFF10B981),
                    title: 'Tugas Selesai',
                    count: state.completedItems.length,
                    expanded: state.completedExpanded,
                    onToggleExpanded: notifier.toggleCompletedExpanded,
                    items: state.completedItems,
                    emptyIcon: Icons.check_circle_outline_rounded,
                    emptyTitle: 'Belum ada tugas yang diselesaikan.',
                    emptySubtitle:
                        'Selesaikan tugasmu untuk melihat daftarnya di sini.',
                    onToggleCompleted: notifier.toggleCompleted,
                    onDelete: (item) => _confirmDelete(context, ref, item),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openTaskDialog(BuildContext context, WidgetRef ref) async {
    final input = await showTodoTaskFormDialog(context);
    if (input == null || !context.mounted) return;

    final result = await ref.read(todoProvider.notifier).createTask(input);
    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas baru berhasil ditambahkan.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Gagal menambah tugas.')),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Tugas'),
          content: Text('Hapus tugas "${item.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (remove != true) return;
    await ref.read(todoProvider.notifier).deleteTask(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tugas dihapus.')));
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.appDangerSoft,
        border: Border.all(color: context.appDanger),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: TextStyle(color: context.appDanger, fontWeight: FontWeight.w600),
      ),
    );
  }
}
