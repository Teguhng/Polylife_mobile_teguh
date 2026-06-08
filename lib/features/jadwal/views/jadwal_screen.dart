import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/providers/jadwal_provider.dart';
import 'package:mobile_ver/features/jadwal/views/jadwal_form_screen.dart';
import 'package:mobile_ver/features/profile/widgets/profile_avatar.dart';

class JadwalScreen extends ConsumerStatefulWidget {
  const JadwalScreen({super.key});

  @override
  ConsumerState<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends ConsumerState<JadwalScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final state = ref.watch(jadwalProvider);
    final notifier = ref.read(jadwalProvider.notifier);
    final monthAnchor = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      1,
    );
    final monthGrid = _buildMonthGrid(monthAnchor);
    final selectedItems = [...state.dayItems]
      ..sort((a, b) => _compareAgendaItemsForDate(a, b, state.selectedDate));
    final allItems = [...state.allItems]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: state.isLoading && state.allItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: context.appPrimary,
                onRefresh: notifier.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
                  children: [
                    _TopBar(
                      user: user,
                      userName: user?.displayName ?? 'Pengguna',
                      onOpenProfile: () => context.push('/profile'),
                      onOpenNotifications: () => context.go('/pengumuman'),
                    ),
                    const SizedBox(height: 18),
                    _MonthNavigationRow(
                      label: DateFormat(
                        'MMMM yyyy',
                        'en_US',
                      ).format(monthAnchor),
                      onPrevious: () => notifier.selectDate(
                        _shiftMonth(state.selectedDate, -1),
                      ),
                      onNext: () => notifier.selectDate(
                        _shiftMonth(state.selectedDate, 1),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CalendarCard(
                      monthAnchor: monthAnchor,
                      selectedDate: state.selectedDate,
                      monthGrid: monthGrid,
                      countResolver: notifier.countForDate,
                      dominantTypeResolver: notifier.dominantTypeForDate,
                      onSelectDate: notifier.selectDate,
                    ),
                    const SizedBox(height: 16),
                    const _LegendWrap(),
                    const SizedBox(height: 18),
                    _AgendaSectionCard(
                      selectedDate: state.selectedDate,
                      items: selectedItems,
                      onOpenAll: () => _openAllAgendaSheet(allItems),
                      onTapItem: (item) => _openAgendaActions(item),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: state.errorMessage!),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateForm(context, ref),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Future<void> _openCreateForm(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(jadwalProvider).selectedDate;
    final input = await Navigator.of(context).push<JadwalInput>(
      MaterialPageRoute(
        builder: (_) => JadwalFormScreen(initialDate: selectedDate),
      ),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final result = await ref
        .read(jadwalProvider.notifier)
        .createFromInput(input);
    if (!context.mounted) {
      return;
    }

    if (result.success) {
      ref.read(jadwalProvider.notifier).selectDate(input.startAt);
    }
    _showActionResult(context, result);
  }

  Future<void> _openEditForm(
    BuildContext context,
    WidgetRef ref,
    JadwalItem item,
  ) async {
    final input = await Navigator.of(context).push<JadwalInput>(
      MaterialPageRoute(builder: (_) => JadwalFormScreen(initialItem: item)),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final result = await ref
        .read(jadwalProvider.notifier)
        .updateFromInput(id: item.id, input: input);
    if (!context.mounted) {
      return;
    }

    if (result.success) {
      ref.read(jadwalProvider.notifier).selectDate(input.startAt);
    }
    _showActionResult(context, result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    JadwalItem item,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Jadwal'),
          content: Text('Hapus agenda "${item.title}"?'),
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

    if (remove != true) {
      return;
    }

    await ref.read(jadwalProvider.notifier).delete(item.id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jadwal berhasil dihapus.')));
  }

  Future<void> _openAgendaActions(JadwalItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit jadwal'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEditForm(context, ref, item);
                },
              ),
              ListTile(
                leading: Icon(
                  item.completed
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                title: Text(
                  item.completed ? 'Tandai belum selesai' : 'Tandai selesai',
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ref.read(jadwalProvider.notifier).toggleCompleted(item);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE25555),
                ),
                title: const Text(
                  'Hapus jadwal',
                  style: TextStyle(color: Color(0xFFE25555)),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, ref, item);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAllAgendaSheet(List<JadwalItem> items) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Semua Agenda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ctx.appText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} item',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ctx.appMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.65,
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada agenda tersimpan.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: ctx.appMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _CompactAgendaListTile(
                              item: item,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _openAgendaActions(item);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActionResult(BuildContext context, JadwalActionResult result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil disimpan.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Gagal menyimpan jadwal.')),
    );
  }
}

class _TopBar extends StatelessWidget {
  final User? user;
  final String userName;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;

  const _TopBar({
    required this.user,
    required this.userName,
    required this.onOpenProfile,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
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
                        color: const Color(0xFF3440C8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.appPrimary,
                        ),
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
      ],
    );
  }
}

class _MonthNavigationRow extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavigationRow({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.appPrimary,
                size: 20,
              ),
            ],
          ),
        ),
        _MonthNavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        const SizedBox(width: 8),
        _MonthNavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: context.appText),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime monthAnchor;
  final DateTime selectedDate;
  final List<DateTime> monthGrid;
  final void Function(DateTime) onSelectDate;
  final int Function(DateTime) countResolver;
  final JadwalType? Function(DateTime) dominantTypeResolver;

  const _CalendarCard({
    required this.monthAnchor,
    required this.selectedDate,
    required this.monthGrid,
    required this.onSelectDate,
    required this.countResolver,
    required this.dominantTypeResolver,
  });

  @override
  Widget build(BuildContext context) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.appFaint,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: monthGrid.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 6,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final day = monthGrid[index];
              final inMonth = day.month == monthAnchor.month;
              final isSelected = _isSameDate(day, selectedDate);
              final isToday = _isSameDate(day, DateTime.now());
              final count = countResolver(day);
              final type = dominantTypeResolver(day);
              final dotColor = _typeColor(type);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectDate(day),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isToday && !isSelected
                          ? Border.all(color: context.appBorder)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : inMonth
                                ? context.appText
                                : context.appFaint.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 8,
                          child: count > 0
                              ? Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendWrap extends StatelessWidget {
  const _LegendWrap();

  @override
  Widget build(BuildContext context) {
    const items = <_LegendItem>[
      _LegendItem(label: 'Kuliah', color: Color(0xFF4F46E5)),
      _LegendItem(label: 'UTS/UAS', color: Color(0xFFF43F5E)),
      _LegendItem(label: 'Personal', color: Color(0xFF10B981)),
      _LegendItem(label: 'Kegiatan', color: Color(0xFFF59E0B)),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AgendaSectionCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<JadwalItem> items;
  final VoidCallback onOpenAll;
  final void Function(JadwalItem item) onTapItem;

  const _AgendaSectionCard({
    required this.selectedDate,
    required this.items,
    required this.onOpenAll,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(selectedDate);
    final isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agenda Tanggal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel[0].toUpperCase() + dateLabel.substring(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenAll,
                style: TextButton.styleFrom(
                  foregroundColor: context.appPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (isWeekend) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.appDangerSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.appDanger.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                'Akhir pekan: jadwal kuliah otomatis libur.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.appDanger,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
                  child: Column(
                    children: [
                      Text(
                        isWeekend
                            ? 'Libur kuliah (akhir pekan).'
                            : 'Belum ada agenda pada tanggal ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isWeekend
                            ? 'Sabtu/Minggu otomatis bebas perkuliahan.'
                            : 'Tambahkan agenda baru atau pilih tanggal lain.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _AgendaArticleCard(
                    item: items[i],
                    selectedDate: selectedDate,
                    onTap: () => onTapItem(items[i]),
                  ),
                  if (i != items.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AgendaArticleCard extends StatelessWidget {
  final JadwalItem item;
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _AgendaArticleCard({
    required this.item,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _agendaVisual(item);
    final matchedMatkuls = [..._resolveMatkulsForDate(item, selectedDate)]
      ..sort((a, b) => _compareMatkulPreviewsByTime(a, b));
    final primaryMatkul = matchedMatkuls.isNotEmpty
        ? matchedMatkuls.first
        : item.primaryMatkul;
    final agendaSummary = item.notes.trim().isNotEmpty
        ? item.notes.trim()
        : _agendaSummaryFromType(item.type);
    final allowGenericMatkulFallback =
        item.matkulPreviews.isEmpty && item.matkulNames.isNotEmpty;
    final matkulTitle = primaryMatkul?.name.trim().isNotEmpty == true
        ? primaryMatkul!.name.trim()
        : matchedMatkuls.isNotEmpty
        ? matchedMatkuls.first.name
        : allowGenericMatkulFallback
        ? item.matkulNames.first
        : null;
    final fallbackDetail = _agendaFallbackDetail(item);
    final matkulPlaceholder = item.matkulPreviews.isNotEmpty
        ? 'Belum ada matkul untuk hari ini'
        : 'Belum ada matkul terhubung';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: context.appSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          agendaSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.appMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.badgeBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      visual.badgeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: visual.badgeForeground,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (matchedMatkuls.isNotEmpty)
                Column(
                  children: [
                    for (
                      var index = 0;
                      index < matchedMatkuls.length;
                      index++
                    ) ...[
                      _AgendaMatkulPreviewTile(
                        preview: matchedMatkuls[index],
                        defaultAccent: visual.accent,
                        isLast: index == matchedMatkuls.length - 1,
                      ),
                      if (index != matchedMatkuls.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                )
              else
                _AgendaMatkulFallbackTile(
                  title: matkulTitle ?? matkulPlaceholder,
                  detail: fallbackDetail,
                  accent: visual.accent,
                  startTime: DateFormat('HH:mm', 'id_ID').format(item.startAt),
                  durationText: _durationLabel(
                    item.endAt.difference(item.startAt),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AgendaMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.appMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.appMuted,
          ),
        ),
      ],
    );
  }
}

class _AgendaMatkulPreviewTile extends StatelessWidget {
  final JadwalMatkulPreview preview;
  final Color defaultAccent;
  final bool isLast;

  const _AgendaMatkulPreviewTile({
    required this.preview,
    required this.defaultAccent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _parseAgendaAccent(preview.warnaLabel, defaultAccent);
    final startTime = _startTimeFromLabel(preview.timeLabel) ?? '--:--';
    final durationText = _durationFromTimeLabel(preview.timeLabel);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Column(
            children: [
              Text(
                startTime,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 8),
                Container(width: 1.5, height: 74, color: context.appBorder),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? accent.withValues(alpha: 0.14)
                  : accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 92,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                preview.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: context.appText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'MATKUL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if ((preview.ruangan ?? '').trim().isNotEmpty)
                              _AgendaMeta(
                                icon: Icons.meeting_room_outlined,
                                text: preview.ruangan!,
                              ),
                            if (durationText != null)
                              _AgendaMeta(
                                icon: Icons.schedule_rounded,
                                text: durationText,
                              ),
                            if ((preview.kelas ?? '').trim().isNotEmpty)
                              _AgendaMeta(
                                icon: Icons.class_outlined,
                                text: 'Kelas ${preview.kelas!}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgendaMatkulFallbackTile extends StatelessWidget {
  final String title;
  final String? detail;
  final Color accent;
  final String startTime;
  final String? durationText;

  const _AgendaMatkulFallbackTile({
    required this.title,
    required this.detail,
    required this.accent,
    required this.startTime,
    this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            startTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? accent.withValues(alpha: 0.14)
                  : accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 92,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (detail != null && detail!.trim().isNotEmpty)
                              _AgendaMeta(
                                icon: Icons.place_outlined,
                                text: detail!,
                              ),
                            if (durationText != null &&
                                durationText!.trim().isNotEmpty)
                              _AgendaMeta(
                                icon: Icons.schedule_rounded,
                                text: durationText!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactAgendaListTile extends StatelessWidget {
  final JadwalItem item;
  final VoidCallback onTap;

  const _CompactAgendaListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = _agendaVisual(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: context.appSurfaceAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd MMM, HH:mm', 'id_ID').format(item.startAt)} • ${visual.badgeLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});
}

class _AgendaVisual {
  final Color accent;
  final Color cardBackground;
  final String badgeLabel;
  final Color badgeBackground;
  final Color badgeForeground;

  const _AgendaVisual({
    required this.accent,
    required this.cardBackground,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.badgeForeground,
  });
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
        border: Border.all(color: context.appDanger.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          color: context.appDanger,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

List<DateTime> _buildMonthGrid(DateTime monthAnchor) {
  final firstDay = DateTime(monthAnchor.year, monthAnchor.month, 1);
  final leadingDays = firstDay.weekday - DateTime.monday;
  final gridStart = firstDay.subtract(Duration(days: leadingDays));

  return List<DateTime>.generate(
    42,
    (index) => gridStart.add(Duration(days: index)),
  );
}

DateTime _shiftMonth(DateTime selectedDate, int delta) {
  final rawMonth = DateTime(selectedDate.year, selectedDate.month + delta, 1);
  final maxDay = DateTime(rawMonth.year, rawMonth.month + 1, 0).day;
  final safeDay = selectedDate.day > maxDay ? maxDay : selectedDate.day;

  return DateTime(
    rawMonth.year,
    rawMonth.month,
    safeDay,
    selectedDate.hour,
    selectedDate.minute,
  );
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Color _typeColor(JadwalType? type) {
  switch (type) {
    case JadwalType.kuliah:
      return const Color(0xFF4F46E5);
    case JadwalType.ujian:
      return const Color(0xFFF43F5E);
    case JadwalType.personal:
      return const Color(0xFF10B981);
    case JadwalType.rapat:
    case JadwalType.tugas:
      return const Color(0xFFF59E0B);
    case null:
      return const Color(0xFFD0D5E3);
  }
}

_AgendaVisual _agendaVisual(JadwalItem item) {
  switch (item.type) {
    case JadwalType.kuliah:
      return const _AgendaVisual(
        accent: Color(0xFF4F46E5),
        cardBackground: Color(0xFFF3F2FF),
        badgeLabel: 'MATKUL',
        badgeBackground: Color(0xFFDCD9FF),
        badgeForeground: Color(0xFF5A50E8),
      );
    case JadwalType.ujian:
      return const _AgendaVisual(
        accent: Color(0xFFF43F5E),
        cardBackground: Color(0xFFFFF1F4),
        badgeLabel: 'UTS/UAS',
        badgeBackground: Color(0xFFFFD8E1),
        badgeForeground: Color(0xFFE11D48),
      );
    case JadwalType.personal:
      return const _AgendaVisual(
        accent: Color(0xFF10B981),
        cardBackground: Color(0xFFECFDF3),
        badgeLabel: 'PERSONAL',
        badgeBackground: Color(0xFFD6FAE8),
        badgeForeground: Color(0xFF0E9F6E),
      );
    case JadwalType.rapat:
      return const _AgendaVisual(
        accent: Color(0xFFF59E0B),
        cardBackground: Color(0xFFFFF8EB),
        badgeLabel: 'KEGIATAN',
        badgeBackground: Color(0xFFFFE9BF),
        badgeForeground: Color(0xFFDD8B00),
      );
    case JadwalType.tugas:
      return const _AgendaVisual(
        accent: Color(0xFFF59E0B),
        cardBackground: Color(0xFFFFF8EB),
        badgeLabel: 'KEGIATAN',
        badgeBackground: Color(0xFFFFE9BF),
        badgeForeground: Color(0xFFDD8B00),
      );
  }
}

String _durationLabel(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes <= 0) {
    return '0 menit';
  }
  if (minutes < 60) {
    return '$minutes menit';
  }

  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) {
    return '$hours jam';
  }

  return '$hours jam $remainder menit';
}

String _agendaSummaryFromType(JadwalType type) {
  switch (type) {
    case JadwalType.kuliah:
      return 'Agenda kuliah pada hari ini.';
    case JadwalType.tugas:
      return 'Agenda tugas yang perlu dipantau.';
    case JadwalType.ujian:
      return 'Agenda ujian atau evaluasi akademik.';
    case JadwalType.rapat:
      return 'Agenda rapat atau kegiatan organisasi.';
    case JadwalType.personal:
      return 'Agenda personal untuk hari ini.';
  }
}

Color _parseAgendaAccent(String? rawColor, Color fallback) {
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

String? _startTimeFromLabel(String? timeLabel) {
  final raw = (timeLabel ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }

  final parts = raw.split('-');
  final start = parts.first.trim();
  return start.isEmpty ? null : start;
}

String? _durationFromTimeLabel(String? timeLabel) {
  final raw = (timeLabel ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }

  final parts = raw.split('-').map((part) => part.trim()).toList();
  if (parts.length != 2) {
    return raw;
  }

  final start = _parseTimeOfDay(parts[0]);
  final end = _parseTimeOfDay(parts[1]);
  if (start == null || end == null) {
    return raw;
  }

  final minutes = end - start;
  if (minutes <= 0) {
    return raw;
  }

  final hours = minutes ~/ 60;
  final remainder = minutes % 60;

  if (hours > 0 && remainder > 0) {
    return '$hours jam $remainder menit';
  }
  if (hours > 0) {
    return '$hours jam';
  }

  return '$remainder menit';
}

int? _parseTimeOfDay(String raw) {
  final match = RegExp(r'^(\d{1,2})[:.](\d{1,2})$').firstMatch(raw);
  if (match == null) {
    return null;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }

  return (hour * 60) + minute;
}

List<JadwalMatkulPreview> _resolveMatkulsForDate(
  JadwalItem item,
  DateTime selectedDate,
) {
  if (item.matkulPreviews.isEmpty) {
    return const <JadwalMatkulPreview>[];
  }

  final dayKey = _weekdayName(selectedDate.weekday);
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
        .expand((preview) => _withEntriesForDay(preview, dayKey))
        .toList();
  }

  return item.matkulPreviews
      .where(
        (preview) =>
            preview.scheduleEntries.isEmpty && preview.scheduleDays.isEmpty,
      )
      .toList();
}

List<JadwalMatkulPreview> _withEntriesForDay(
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

int _compareMatkulPreviewsByTime(JadwalMatkulPreview a, JadwalMatkulPreview b) {
  final aStart = _sortMinutesFromTimeLabel(a.timeLabel);
  final bStart = _sortMinutesFromTimeLabel(b.timeLabel);
  if (aStart != bStart) return aStart.compareTo(bStart);
  return a.name.compareTo(b.name);
}

int _sortMinutesFromTimeLabel(String? timeLabel) {
  final start = _startTimeFromLabel(timeLabel);
  final parsed = start == null ? null : _parseAgendaTimeOfDay(start);
  if (parsed == null) return 24 * 60;

  return parsed.$1 * 60 + parsed.$2;
}

int _compareAgendaItemsForDate(
  JadwalItem a,
  JadwalItem b,
  DateTime selectedDate,
) {
  final byStart = _agendaSortStart(
    a,
    selectedDate,
  ).compareTo(_agendaSortStart(b, selectedDate));
  if (byStart != 0) return byStart;

  return a.id.compareTo(b.id);
}

DateTime _agendaSortStart(JadwalItem item, DateTime selectedDate) {
  final matched = _resolveMatkulsForDate(item, selectedDate);
  DateTime? earliest;

  for (final preview in matched) {
    final time = _startTimeFromLabel(preview.timeLabel);
    if (time == null) continue;

    final parsed = _parseAgendaTimeOfDay(time);
    if (parsed == null) continue;

    final candidate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      parsed.$1,
      parsed.$2,
    );
    if (earliest == null || candidate.isBefore(earliest)) {
      earliest = candidate;
    }
  }

  return earliest ?? item.startAt;
}

(int, int)? _parseAgendaTimeOfDay(String value) {
  final match = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(value.trim());
  if (match == null) return null;

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return (hour, minute);
}

String _weekdayName(int weekday) {
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

String? _agendaFallbackDetail(JadwalItem item) {
  final location = item.location.trim();
  if (location.isNotEmpty) {
    return location;
  }

  final note = item.notes.trim();
  if (note.isNotEmpty) {
    return note;
  }

  final duration = _durationLabel(item.endAt.difference(item.startAt));
  return duration.trim().isEmpty ? null : duration;
}
