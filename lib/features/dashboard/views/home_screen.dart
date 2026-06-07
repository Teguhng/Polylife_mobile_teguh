import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/catatan/providers/catatan_provider.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/providers/jadwal_provider.dart';
import 'package:mobile_ver/features/keuangan/providers/keuangan_provider.dart';
import 'package:mobile_ver/features/pengumuman/models/pengumuman_model.dart';
import 'package:mobile_ver/features/pengumuman/providers/pengumuman_provider.dart';
import 'package:mobile_ver/features/profile/widgets/profile_avatar.dart';
import 'package:mobile_ver/features/reminder/models/upcoming_reminder.dart';
import 'package:mobile_ver/features/reminder/providers/upcoming_reminder_provider.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/providers/todo_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final keuanganState = ref.watch(keuanganProvider);
    final jadwalState = ref.watch(jadwalProvider);
    final todoState = ref.watch(todoProvider);
    final catatanAsync = ref.watch(catatanProvider);
    final pengumumanAsync = ref.watch(pengumumanProvider);
    final reminderAsync = ref.watch(upcomingReminderProvider);

    final now = DateTime.now();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final pengumumanRows = pengumumanAsync.valueOrNull ?? const <Pengumuman>[];
    final latestPengumuman = pengumumanRows.isEmpty
        ? null
        : pengumumanRows.first;

    final scheduleItems = _buildSchedulePreview(jadwalState, now);
    final isWeekendToday =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final reminderPreview = _buildReminderPreview(
      reminderAsync: reminderAsync,
      openReminder: () => context.push('/reminder'),
    );
    final priorityTodos = _buildPriorityTodos(todoState.ongoingItems);
    final budgetRemaining = keuanganState.summary.saldo < 0
        ? 0.0
        : keuanganState.summary.saldo;
    final spendingProgress = keuanganState.summary.totalPemasukan > 0
        ? (keuanganState.summary.totalPengeluaran /
                  keuanganState.summary.totalPemasukan)
              .clamp(0.0, 1.0)
        : 0.0;

    final hasDataIssue =
        catatanAsync.hasError ||
        pengumumanAsync.hasError ||
        reminderAsync.hasError ||
        jadwalState.errorMessage != null ||
        todoState.errorMessage != null ||
        keuanganState.errorMessage != null;

    Future<void> refreshAll() async {
      await Future.wait([
        ref.read(keuanganProvider.notifier).fetchKeuangan(showLoader: false),
        ref.read(jadwalProvider.notifier).load(),
        ref.read(todoProvider.notifier).load(),
        ref.read(catatanProvider.notifier).fetchCatatan(),
        ref.read(pengumumanProvider.notifier).fetchPengumuman(),
        ref
            .read(upcomingReminderProvider.notifier)
            .fetchReminder(showLoader: false, force: true),
      ]);
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.appPrimary,
          onRefresh: refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _DashboardTopBar(
                user: user,
                userName: user?.displayName ?? 'Pengguna',
                onOpenProfile: () => context.push('/profile'),
                onOpenNotifications: () => context.go('/pengumuman'),
                onLogout: () => ref.read(authProvider.notifier).logout(),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.go('/keuangan'),
                child: _BudgetSummaryCard(
                  balanceLabel: currency.format(
                    keuanganState.summary.totalPengeluaran,
                  ),
                  remainingLabel: currency.format(budgetRemaining),
                  progress: spendingProgress,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: reminderPreview.onTap,
                child: _ReminderCard(preview: reminderPreview),
              ),
              if (hasDataIssue) ...[
                const SizedBox(height: 14),
                const _DashboardWarningBanner(
                  message:
                      'Sebagian data belum sinkron. Tarik layar untuk memuat ulang.',
                ),
              ],
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Jadwal Hari Ini',
                actionLabel: 'Lihat Semua',
                onTap: () => context.go('/jadwal'),
              ),
              const SizedBox(height: 12),
              if (scheduleItems.isEmpty)
                _EmptyPanel(
                  title: isWeekendToday
                      ? 'Libur akhir pekan.'
                      : 'Belum ada agenda hari ini.',
                  subtitle: isWeekendToday
                      ? 'Sabtu/Minggu otomatis bebas perkuliahan.'
                      : 'Tambahkan jadwal baru agar beranda menampilkan fokus harian.',
                )
              else
                _TodayAgendaListCard(
                  selectedDate: now,
                  items: scheduleItems,
                  onTapItem: () => context.go('/jadwal'),
                ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Kegiatan Kampus',
                actionLabel: 'Eksplor',
                onTap: () => context.go('/pengumuman'),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.go('/pengumuman'),
                child: _CampusHighlightCard(
                  latestPengumuman: latestPengumuman,
                  announcementCount: pengumumanRows.length,
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'To-Do List Prioritas',
                trailing: _RoundActionButton(
                  icon: Icons.add_rounded,
                  onTap: () => context.go('/todo'),
                ),
              ),
              const SizedBox(height: 12),
              if (priorityTodos.isEmpty)
                const _EmptyPanel(
                  title: 'Belum ada prioritas aktif.',
                  subtitle:
                      'Task yang paling dekat deadline akan muncul di sini.',
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < priorityTodos.length; i++) ...[
                      _PriorityTodoCard(
                        item: priorityTodos[i],
                        onOpen: () => context.go('/todo'),
                        onToggle: () => ref
                            .read(todoProvider.notifier)
                            .toggleCompleted(priorityTodos[i]),
                      ),
                      if (i != priorityTodos.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final User? user;
  final String userName;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogout;

  const _DashboardTopBar({
    required this.user,
    required this.userName,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onOpenProfile,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    ProfileAvatar(
                      user: user,
                      fallbackName: userName,
                      size: 46,
                      borderWidth: 2,
                      gradientColors: const [
                        Color(0xFFE3E8FF),
                        Color(0xFFB9C6FF),
                      ],
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                      initialsStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF3440C8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.appPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _greetingLabel(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.appMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _IconCapsuleButton(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: onOpenNotifications,
        ),
        const SizedBox(width: 8),
        _IconCapsuleButton(icon: Icons.logout_rounded, onTap: onLogout),
      ],
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final String balanceLabel;
  final String remainingLabel;
  final double progress;

  const _BudgetSummaryCard({
    required this.balanceLabel,
    required this.remainingLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentText = '${(clampedProgress * 100).round()}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF4944F3), Color(0xFF4237DD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334B3FF2),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengeluaran Bulan Ini',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  balanceLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sisa Anggaran: $remainingLabel',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 78,
            width: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 78,
                  width: 78,
                  child: CircularProgressIndicator(
                    value: clampedProgress,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      percentText,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'terpakai',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final _ReminderPreview preview;

  const _ReminderCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? context.appBorder : preview.borderColor,
        ),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: preview.leadingColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(preview.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder Mendatang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  preview.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.appMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                preview.value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: preview.accentColor,
                ),
              ),
              Text(
                preview.unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: preview.accentColor.withValues(alpha: 0.8),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appText;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (actionLabel != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF5A50E8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _TodayAgendaListCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<JadwalItem> items;
  final VoidCallback onTapItem;

  const _TodayAgendaListCard({
    required this.selectedDate,
    required this.items,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _buildHomeScheduleEntries(items, selectedDate);

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _TodayScheduleEntryCard(entry: entries[i], onTap: onTapItem),
          if (i != entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TodayScheduleEntryCard extends StatelessWidget {
  final _HomeScheduleEntry entry;
  final VoidCallback onTap;

  const _TodayScheduleEntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _homeScheduleStatus(entry, DateTime.now());
    final isRunning = status.label == 'BERLANGSUNG';
    final cardColor = isRunning ? context.appPrimarySoft : context.appSurface;
    final borderColor = isRunning ? context.appPrimary : context.appBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: isRunning ? 1.4 : 1),
            boxShadow: context.appCardShadow,
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: entry.iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(entry.icon, color: entry.iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: context.appMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.appMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.trailingLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.appMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AnimatedScheduleStatusBadge(entry: entry),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedScheduleStatusBadge extends StatefulWidget {
  final _HomeScheduleEntry entry;

  const _AnimatedScheduleStatusBadge({required this.entry});

  @override
  State<_AnimatedScheduleStatusBadge> createState() =>
      _AnimatedScheduleStatusBadgeState();
}

class _AnimatedScheduleStatusBadgeState
    extends State<_AnimatedScheduleStatusBadge> {
  Timer? _timer;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _AnimatedScheduleStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.effectiveStartAt != widget.entry.effectiveStartAt ||
        oldWidget.entry.effectiveEndAt != widget.entry.effectiveEndAt) {
      _showCountdown = false;
      _restartTicker();
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _showCountdown = !_showCountdown;
      });
    });
  }

  void _restartTicker() {
    _timer?.cancel();
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = _homeScheduleStatus(widget.entry, now);
    final isRunning = status.label == 'BERLANGSUNG';
    final isUpcomingSoon =
        status.label == 'MENDATANG' &&
        widget.entry.effectiveStartAt.isAfter(now) &&
        widget.entry.effectiveStartAt.difference(now).inMinutes < 31;
    final countdownLabel = isRunning
        ? _homeRunningCountdownLabel(widget.entry.effectiveEndAt, now)
        : _homeUpcomingCountdownLabel(widget.entry.effectiveStartAt, now);
    final displayLabel = (isRunning || isUpcomingSoon) && _showCountdown
        ? countdownLabel
        : status.label;
    final backgroundColor = isUpcomingSoon
        ? const Color(0xFFFFEEF1)
        : status.backgroundColor;
    final foregroundColor = isUpcomingSoon
        ? const Color(0xFFE25555)
        : status.foregroundColor;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
      opacity: (isRunning || isUpcomingSoon) && _showCountdown ? 0.78 : 1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: SizedBox(
          key: ValueKey('${status.label}::$displayLabel'),
          width: (isRunning || isUpcomingSoon) ? 108 : null,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: foregroundColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampusHighlightCard extends StatelessWidget {
  final Pengumuman? latestPengumuman;
  final int announcementCount;

  const _CampusHighlightCard({
    required this.latestPengumuman,
    required this.announcementCount,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = latestPengumuman?.excerpt.trim().isNotEmpty == true
        ? latestPengumuman!.excerpt.trim()
        : 'Temukan seminar, lomba, dan kegiatan kampus lainnya.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.explore_outlined,
              color: Color(0xFF4E44F2),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eksplor Semua Kegiatan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  announcementCount > 0
                      ? subtitle
                      : 'Temukan seminar, lomba, dan kegiatan kampus lainnya.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: context.appMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: context.appPrimary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _PriorityTodoCard extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _PriorityTodoCard({
    required this.item,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = _todoUrgency(item, DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorder),
            boxShadow: context.appCardShadow,
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.appBorder, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      urgency.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 9,
                width: 9,
                decoration: BoxDecoration(
                  color: urgency.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appPrimary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          height: 34,
          width: 34,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _IconCapsuleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _IconCapsuleButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, color: context.appText, size: 22)),
              if (showDot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4F),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appSurface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyPanel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardWarningBanner extends StatelessWidget {
  final String message;

  const _DashboardWarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? context.appWarningSoft : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF92400E) : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: context.appWarning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: isDark
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFF9A3412),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPreview {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color leadingColor;
  final Color accentColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _ReminderPreview({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.leadingColor,
    required this.accentColor,
    required this.borderColor,
    required this.onTap,
  });
}

class _HomeScheduleVisualStyle {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _HomeScheduleVisualStyle({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _HomeScheduleStatusData {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _HomeScheduleStatusData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class _HomeScheduleEntry {
  final JadwalItem item;
  final String title;
  final String timeLabel;
  final String trailingLabel;
  final DateTime effectiveStartAt;
  final DateTime effectiveEndAt;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _HomeScheduleEntry({
    required this.item,
    required this.title,
    required this.timeLabel,
    required this.trailingLabel,
    required this.effectiveStartAt,
    required this.effectiveEndAt,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _TodoUrgencyData {
  final String label;
  final Color color;

  const _TodoUrgencyData({required this.label, required this.color});
}

List<JadwalItem> _buildSchedulePreview(JadwalState state, DateTime now) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final isWeekend =
      todayStart.weekday == DateTime.saturday ||
      todayStart.weekday == DateTime.sunday;

  final todayItems =
      state.allItems
          .where(
            (item) =>
                item.startAt.isBefore(todayEnd) &&
                item.endAt.isAfter(todayStart),
          )
          .where((item) => !isWeekend || item.type != JadwalType.kuliah)
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

  return todayItems;
}

List<_HomeScheduleEntry> _buildHomeScheduleEntries(
  List<JadwalItem> items,
  DateTime date,
) {
  final entries = <_HomeScheduleEntry>[];

  for (final item in items) {
    final visualStyle = _homeScheduleVisualStyle(item.type);
    final matchedMatkuls = _resolveHomeMatkulsForDate(item, date);

    if (matchedMatkuls.isNotEmpty) {
      for (final preview in matchedMatkuls) {
        final timeLabel =
            (preview.timeLabel ?? _fallbackHomeScheduleTimeLabel(item)).trim();
        final range = _resolveHomeScheduleRange(
          date,
          timeLabel,
          fallbackStart: item.startAt,
          fallbackEnd: item.endAt,
        );
        final trailingLabel =
            ((preview.ruangan ?? '').trim().isNotEmpty
                    ? preview.ruangan!.trim()
                    : (preview.kelas ?? '').trim().isNotEmpty
                    ? 'Kelas ${preview.kelas!.trim()}'
                    : item.location.trim())
                .trim();

        entries.add(
          _HomeScheduleEntry(
            item: item,
            title: preview.name.trim().isNotEmpty
                ? preview.name.trim()
                : item.title.trim(),
            timeLabel: timeLabel,
            trailingLabel: trailingLabel.isNotEmpty
                ? trailingLabel
                : item.type.label.toUpperCase(),
            effectiveStartAt: range.$1,
            effectiveEndAt: range.$2,
            icon: visualStyle.icon,
            iconBackground: visualStyle.iconBackground,
            iconColor: _parseHomeAccent(
              preview.warnaLabel,
              visualStyle.iconColor,
            ),
          ),
        );
      }
      continue;
    }

    final fallbackLabel = item.location.trim().isNotEmpty
        ? item.location.trim()
        : item.type == JadwalType.kuliah
        ? 'MATKUL'
        : item.type.label.toUpperCase();
    final timeLabel = _fallbackHomeScheduleTimeLabel(item);
    final range = _resolveHomeScheduleRange(
      date,
      timeLabel,
      fallbackStart: item.startAt,
      fallbackEnd: item.endAt,
    );

    entries.add(
      _HomeScheduleEntry(
        item: item,
        title: item.title.trim().isNotEmpty
            ? item.title.trim()
            : 'Agenda tanpa judul',
        timeLabel: timeLabel,
        trailingLabel: fallbackLabel,
        effectiveStartAt: range.$1,
        effectiveEndAt: range.$2,
        icon: visualStyle.icon,
        iconBackground: visualStyle.iconBackground,
        iconColor: visualStyle.iconColor,
      ),
    );
  }

  entries.sort((a, b) {
    final byStart = a.effectiveStartAt.compareTo(b.effectiveStartAt);
    if (byStart != 0) return byStart;
    return a.title.compareTo(b.title);
  });

  return entries;
}

List<JadwalMatkulPreview> _resolveHomeMatkulsForDate(
  JadwalItem item,
  DateTime date,
) {
  if (item.matkulPreviews.isEmpty) {
    return const <JadwalMatkulPreview>[];
  }

  final dayKey = _homeWeekdayName(date.weekday);
  final matched = item.matkulPreviews.where((preview) {
    if (preview.scheduleEntries.isNotEmpty) {
      return preview.scheduleEntries.any(
        (entry) => (entry.hari ?? '').trim().toLowerCase() == dayKey,
      );
    }

    if (preview.scheduleDays.isNotEmpty) {
      return preview.scheduleDays.contains(dayKey);
    }

    return false;
  }).toList();

  if (matched.isNotEmpty) {
    return matched
        .expand((preview) => _withHomeEntriesForDay(preview, dayKey))
        .toList();
  }

  return item.matkulPreviews
      .where(
        (preview) =>
            preview.scheduleEntries.isEmpty && preview.scheduleDays.isEmpty,
      )
      .toList();
}

List<JadwalMatkulPreview> _withHomeEntriesForDay(
  JadwalMatkulPreview preview,
  String dayKey,
) {
  final matchedEntries = preview.scheduleEntries
      .where((entry) => (entry.hari ?? '').trim().toLowerCase() == dayKey)
      .toList();

  if (matchedEntries.isEmpty) {
    return <JadwalMatkulPreview>[preview];
  }

  return matchedEntries
      .map(
        (entry) => JadwalMatkulPreview(
          id: preview.id,
          name: preview.name,
          kelas: entry.kelas ?? preview.kelas,
          ruangan: entry.ruangan ?? preview.ruangan,
          timeLabel: _timeLabelFromEntry(entry) ?? preview.timeLabel,
          warnaLabel: preview.warnaLabel,
          scheduleDays: preview.scheduleDays,
          scheduleEntries: preview.scheduleEntries,
        ),
      )
      .toList();
}

String? _timeLabelFromEntry(JadwalMatkulScheduleEntry entry) {
  final start = (entry.jamMulai ?? '').trim();
  final end = (entry.jamSelesai ?? '').trim();

  if (start.isNotEmpty && end.isNotEmpty) {
    return '$start - $end';
  }
  if (start.isNotEmpty) {
    return start;
  }
  if (end.isNotEmpty) {
    return end;
  }

  return null;
}

String _homeWeekdayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'senin';
    case DateTime.tuesday:
      return 'selasa';
    case DateTime.wednesday:
      return 'rabu';
    case DateTime.thursday:
      return 'kamis';
    case DateTime.friday:
      return 'jumat';
    case DateTime.saturday:
      return 'sabtu';
    case DateTime.sunday:
      return 'minggu';
  }

  return 'senin';
}

String _fallbackHomeScheduleTimeLabel(JadwalItem item) {
  final formatter = DateFormat('HH:mm');
  return '${formatter.format(item.startAt)} - ${formatter.format(item.endAt)}';
}

(DateTime, DateTime) _resolveHomeScheduleRange(
  DateTime date,
  String timeLabel, {
  required DateTime fallbackStart,
  required DateTime fallbackEnd,
}) {
  final parts = timeLabel.split('-').map((part) => part.trim()).toList();
  if (parts.length != 2) {
    return (fallbackStart, fallbackEnd);
  }

  final start = _parseHomeTimeOfDay(parts[0]);
  final end = _parseHomeTimeOfDay(parts[1]);
  if (start == null || end == null) {
    return (fallbackStart, fallbackEnd);
  }

  final startAt = DateTime(date.year, date.month, date.day, start.$1, start.$2);
  var endAt = DateTime(date.year, date.month, date.day, end.$1, end.$2);

  if (!endAt.isAfter(startAt)) {
    endAt = endAt.add(const Duration(days: 1));
  }

  return (startAt, endAt);
}

Color _parseHomeAccent(String? rawColor, Color fallback) {
  final value = (rawColor ?? '').trim();
  if (value.isEmpty) {
    return fallback;
  }

  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length != 6) {
    return fallback;
  }

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return fallback;
  }

  return Color(0xFF000000 | parsed);
}

_HomeScheduleVisualStyle _homeScheduleVisualStyle(JadwalType type) {
  switch (type) {
    case JadwalType.kuliah:
      return const _HomeScheduleVisualStyle(
        icon: Icons.code_rounded,
        iconBackground: Color(0xFFEEF1FF),
        iconColor: Color(0xFF5A50E8),
      );
    case JadwalType.tugas:
      return const _HomeScheduleVisualStyle(
        icon: Icons.rocket_launch_outlined,
        iconBackground: Color(0xFF4B3FF2),
        iconColor: Colors.white,
      );
    case JadwalType.ujian:
      return const _HomeScheduleVisualStyle(
        icon: Icons.storage_rounded,
        iconBackground: Color(0xFFF3F5F9),
        iconColor: Color(0xFF707891),
      );
    case JadwalType.rapat:
      return const _HomeScheduleVisualStyle(
        icon: Icons.groups_rounded,
        iconBackground: Color(0xFFFFF0E6),
        iconColor: Color(0xFFEA6A25),
      );
    case JadwalType.personal:
      return const _HomeScheduleVisualStyle(
        icon: Icons.event_note_rounded,
        iconBackground: Color(0xFFECFDF3),
        iconColor: Color(0xFF1E9A59),
      );
  }
}

_HomeScheduleStatusData _homeScheduleStatus(
  _HomeScheduleEntry entry,
  DateTime now,
) {
  if (entry.effectiveEndAt.isBefore(now)) {
    return const _HomeScheduleStatusData(
      label: 'SELESAI',
      backgroundColor: Color(0xFFE8FFF2),
      foregroundColor: Color(0xFF37A463),
    );
  }

  if (entry.effectiveStartAt.isBefore(now) &&
      entry.effectiveEndAt.isAfter(now)) {
    return const _HomeScheduleStatusData(
      label: 'BERLANGSUNG',
      backgroundColor: Color(0xFF4B3FF2),
      foregroundColor: Colors.white,
    );
  }

  return const _HomeScheduleStatusData(
    label: 'MENDATANG',
    backgroundColor: Color(0xFFF2F4F8),
    foregroundColor: Color(0xFF7D859B),
  );
}

String _homeRunningCountdownLabel(DateTime endAt, DateTime now) {
  final remaining = endAt.difference(now);
  if (remaining.inSeconds <= 0) {
    return 'SELESAI';
  }

  final totalMinutes = remaining.inMinutes;
  if (totalMinutes < 60) {
    final safeMinutes = totalMinutes <= 0 ? 1 : totalMinutes;
    return '$safeMinutes MENIT';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '$hours JAM';
  }

  return '${hours}J ${minutes}M';
}

String _homeUpcomingCountdownLabel(DateTime startAt, DateTime now) {
  final remaining = startAt.difference(now);
  if (remaining.inSeconds <= 0) {
    return 'SEBENTAR';
  }

  final totalMinutes = remaining.inMinutes;
  if (totalMinutes <= 0) {
    return 'SEBENTAR';
  }

  if (totalMinutes < 60) {
    return '$totalMinutes MENIT';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '$hours JAM';
  }

  return '${hours}J ${minutes}M';
}

(int, int)? _parseHomeTimeOfDay(String raw) {
  final match = RegExp(r'^(\d{1,2})[:.](\d{1,2})$').firstMatch(raw);
  if (match == null) {
    return null;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }

  return (hour, minute);
}

List<TodoItem> _buildPriorityTodos(List<TodoItem> items) {
  final rows = List<TodoItem>.from(items)
    ..sort((a, b) {
      final dueA = a.dueDate;
      final dueB = b.dueDate;

      if (dueA == null && dueB != null) return 1;
      if (dueA != null && dueB == null) return -1;
      if (dueA != null && dueB != null) {
        final byDue = dueA.compareTo(dueB);
        if (byDue != 0) return byDue;
      }

      if (a.priority != b.priority) {
        return a.priority == TodoPriority.high ? -1 : 1;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

  return rows;
}

_ReminderPreview _buildReminderPreview({
  required AsyncValue<UpcomingReminder?> reminderAsync,
  required VoidCallback openReminder,
}) {
  return reminderAsync.when(
    data: (reminder) {
      if (reminder == null) {
        return _ReminderPreview(
          title: 'BELUM ADA REMINDER AKTIF',
          value: '--',
          unit: 'AMAN',
          icon: Icons.task_alt_rounded,
          leadingColor: Color(0xFF4B3FF2),
          accentColor: Color(0xFF4B3FF2),
          borderColor: Color(0xFFE5E2FF),
          onTap: openReminder,
        );
      }

      final countdown = reminder.secondsLeft <= 0
          ? const _CountdownLabel(value: 'NOW', unit: 'LIVE')
          : _countdownLabel(Duration(seconds: reminder.secondsLeft));
      final visual = _reminderVisualStyle(reminder.targetType);

      return _ReminderPreview(
        title: reminder.title.toUpperCase(),
        value: countdown.value,
        unit: countdown.unit,
        icon: visual.icon,
        leadingColor: visual.leadingColor,
        accentColor: visual.accentColor,
        borderColor: visual.borderColor,
        onTap: openReminder,
      );
    },
    loading: () => _ReminderPreview(
      title: 'MEMUAT REMINDER...',
      value: '...',
      unit: 'SYNC',
      icon: Icons.alarm_rounded,
      leadingColor: Color(0xFF4B3FF2),
      accentColor: Color(0xFF4B3FF2),
      borderColor: Color(0xFFE5E2FF),
      onTap: openReminder,
    ),
    error: (error, stackTrace) => _ReminderPreview(
      title: 'REMINDER BELUM TERSINKRON',
      value: '--',
      unit: 'COBA',
      icon: Icons.sync_problem_rounded,
      leadingColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFD97706),
      borderColor: Color(0xFFFDE7C2),
      onTap: openReminder,
    ),
  );
}

class _ReminderVisualStyle {
  final IconData icon;
  final Color leadingColor;
  final Color accentColor;
  final Color borderColor;

  const _ReminderVisualStyle({
    required this.icon,
    required this.leadingColor,
    required this.accentColor,
    required this.borderColor,
  });
}

_ReminderVisualStyle _reminderVisualStyle(String targetType) {
  return switch (targetType) {
    'todolist' => const _ReminderVisualStyle(
      icon: Icons.checklist_rounded,
      leadingColor: Color(0xFF10B981),
      accentColor: Color(0xFF059669),
      borderColor: Color(0xFFCCF3E6),
    ),
    'tugas' => const _ReminderVisualStyle(
      icon: Icons.assignment_late_rounded,
      leadingColor: Color(0xFFF34C4E),
      accentColor: Color(0xFFE53E3E),
      borderColor: Color(0xFFF6D3D6),
    ),
    'kegiatan' => const _ReminderVisualStyle(
      icon: Icons.celebration_rounded,
      leadingColor: Color(0xFFF97316),
      accentColor: Color(0xFFEA580C),
      borderColor: Color(0xFFFED7AA),
    ),
    _ => const _ReminderVisualStyle(
      icon: Icons.alarm_rounded,
      leadingColor: Color(0xFFF34C4E),
      accentColor: Color(0xFFE53E3E),
      borderColor: Color(0xFFF6D3D6),
    ),
  };
}

_TodoUrgencyData _todoUrgency(TodoItem item, DateTime now) {
  final dueDate = item.dueDate;

  if (dueDate == null) {
    return const _TodoUrgencyData(
      label: 'Belum ada reminder aktif',
      color: Color(0xFF22C55E),
    );
  }

  final difference = dueDate.difference(now);
  if (difference.inMinutes <= 0) {
    return const _TodoUrgencyData(
      label: 'Reminder: Segera',
      color: Color(0xFFEF4444),
    );
  }

  if (difference.inHours < 24) {
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final timeLabel = hours > 0 ? '$hours jam lagi' : '$minutes menit lagi';

    return _TodoUrgencyData(
      label: 'Reminder: $timeLabel',
      color: difference.inHours < 6
          ? const Color(0xFFEF4444)
          : const Color(0xFFF97316),
    );
  }

  if (difference.inDays < 7) {
    return _TodoUrgencyData(
      label: 'Reminder: ${difference.inDays} hari lagi',
      color: difference.inDays <= 2
          ? const Color(0xFFF97316)
          : const Color(0xFF22C55E),
    );
  }

  final formatter = DateFormat('dd MMM, HH:mm', 'id_ID');
  return _TodoUrgencyData(
    label: 'Reminder: ${formatter.format(dueDate)}',
    color: const Color(0xFF22C55E),
  );
}

String _greetingLabel() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Pagi produktif';
  if (hour < 15) return 'Siang fokus';
  if (hour < 18) return 'Sore terarah';
  return 'Malam terencana';
}

class _CountdownLabel {
  final String value;
  final String unit;

  const _CountdownLabel({required this.value, required this.unit});
}

_CountdownLabel _countdownLabel(Duration duration) {
  if (duration.inMinutes < 60) {
    return _CountdownLabel(value: '${duration.inMinutes}', unit: 'MENIT');
  }

  if (duration.inHours < 24) {
    return _CountdownLabel(value: '${duration.inHours}', unit: 'JAM');
  }

  return _CountdownLabel(value: '${duration.inDays}', unit: 'HARI');
}
