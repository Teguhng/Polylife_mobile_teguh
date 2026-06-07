import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/reminder/models/reminder_list_item.dart';
import 'package:mobile_ver/features/reminder/providers/reminder_list_provider.dart';
import 'package:mobile_ver/features/reminder/providers/upcoming_reminder_provider.dart';

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderListProvider);
    final notifier = ref.read(reminderListProvider.notifier);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kelola Reminder',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ReminderHeroCard(
              total: state.items.length,
              onCreateReminder: () => context.push('/reminder/new'),
              onTestNotification: () => _testNotification(context, ref),
              onReschedule: () => _rescheduleNotifications(context, ref),
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null) ...[
              _ReminderErrorBanner(message: state.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (state.isLoading && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.items.isEmpty)
              const _ReminderEmptyState()
            else
              Column(
                children: [
                  for (var i = 0; i < state.items.length; i++) ...[
                    _ReminderCard(
                      item: state.items[i],
                      onOpenTarget: () =>
                          _openDestination(context, state.items[i]),
                      onDelete: () =>
                          _deleteReminder(context, ref, state.items[i]),
                    ),
                    if (i != state.items.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openDestination(BuildContext context, ReminderListItem item) {
    if (item.destination == 'jadwal') {
      context.go('/jadwal');
      return;
    }

    context.go('/todo');
  }

  Future<void> _deleteReminder(
    BuildContext context,
    WidgetRef ref,
    ReminderListItem item,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Reminder'),
        content: Text('Hapus reminder untuk "${item.title}"?'),
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
      ),
    );

    if (remove != true || !context.mounted) return;

    final success = await ref
        .read(reminderListProvider.notifier)
        .deleteReminder(item.id);
    if (success) {
      await ref
          .read(upcomingReminderProvider.notifier)
          .fetchReminder(showLoader: false, force: true);
    }
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reminder dihapus.' : 'Gagal menghapus reminder.',
        ),
      ),
    );
  }

  Future<void> _testNotification(BuildContext context, WidgetRef ref) async {
    final message = await ref
        .read(reminderListProvider.notifier)
        .testNotification();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _rescheduleNotifications(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final message = await ref
        .read(reminderListProvider.notifier)
        .rescheduleNotifications();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ReminderHeroCard extends StatelessWidget {
  final int total;
  final VoidCallback onCreateReminder;
  final VoidCallback onTestNotification;
  final VoidCallback onReschedule;

  const _ReminderHeroCard({
    required this.total,
    required this.onCreateReminder,
    required this.onTestNotification,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E5F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REMINDER CERDAS',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF5A50E8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aktifkan pengingat untuk to-do, tugas, jadwal, atau kegiatan supaya tenggatmu aman.',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF81869C),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroStatsPill(total: total),
                    const SizedBox(height: 12),
                    _CreateReminderButton(onTap: onCreateReminder),
                    const SizedBox(height: 10),
                    _ReminderDebugActions(
                      onTestNotification: onTestNotification,
                      onReschedule: onReschedule,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _HeroStatsPill(total: total)),
                        const SizedBox(width: 14),
                        _CreateReminderButton(onTap: onCreateReminder),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ReminderDebugActions(
                      onTestNotification: onTestNotification,
                      onReschedule: onReschedule,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderDebugActions extends StatelessWidget {
  final VoidCallback onTestNotification;
  final VoidCallback onReschedule;

  const _ReminderDebugActions({
    required this.onTestNotification,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onTestNotification,
          icon: const Icon(Icons.notifications_active_outlined, size: 16),
          label: const Text('Tes Notif'),
        ),
        OutlinedButton.icon(
          onPressed: onReschedule,
          icon: const Icon(Icons.schedule_outlined, size: 16),
          label: const Text('Jadwalkan Ulang'),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderListItem item;
  final VoidCallback onOpenTarget;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.item,
    required this.onOpenTarget,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming =
        item.scheduledAt != null && item.scheduledAt!.isAfter(DateTime.now());
    final timeText = item.scheduledAt == null
        ? 'Waktu belum tersedia'
        : DateFormat(
            "EEEE, dd MMMM yyyy '•' HH:mm",
            'id_ID',
          ).format(item.scheduledAt!);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE7F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                item.targetLabel,
                const Color(0xFFEAE8FF),
                const Color(0xFF4E44F2),
              ),
              _chip(
                item.active ? 'Aktif' : 'Nonaktif',
                item.active ? const Color(0xFFE8FFF2) : const Color(0xFFF3F4F6),
                item.active ? const Color(0xFF15803D) : const Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                height: 9,
                width: 9,
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? const Color(0xFF5A50E8)
                      : const Color(0xFFF97316),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF211C31),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF79809B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.targetContext,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF616985),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  OutlinedButton(
                    onPressed: onOpenTarget,
                    child: const Text('Buka'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroStatsPill extends StatelessWidget {
  final int total;

  const _HeroStatsPill({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4D42F2), Color(0xFF5D52F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$total reminder aktif di workspace kamu',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF241E35),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateReminderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateReminderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4E44F2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        '+ Reminder Baru',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReminderEmptyState extends StatelessWidget {
  const _ReminderEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE7F5)),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFF4E44F2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada reminder yang aktif.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF221D33),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aktifkan reminder dari item To-Do atau Jadwal agar pengingat muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: const Color(0xFF81869C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderErrorBanner extends StatelessWidget {
  final String message;

  const _ReminderErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFDA4AF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFBE123C),
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
