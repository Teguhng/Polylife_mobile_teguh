import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';
import 'package:mobile_ver/features/keuangan/providers/keuangan_provider.dart';
import 'package:mobile_ver/features/keuangan/utils/category_icon_resolver.dart';
import 'package:mobile_ver/features/keuangan/views/keuangan_form_screen.dart';
import 'package:mobile_ver/features/profile/widgets/profile_avatar.dart';

final NumberFormat _idrFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class KeuanganScreen extends ConsumerWidget {
  const KeuanganScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final state = ref.watch(keuanganProvider);
    final notifier = ref.read(keuanganProvider.notifier);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: context.appPrimary,
                onRefresh: () => notifier.fetchKeuangan(showLoader: false),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _FinanceTopBar(
                      user: user,
                      userName: user?.displayName ?? 'Pengguna',
                      onOpenProfile: () => context.push('/profile'),
                      onOpenNotifications: () => context.go('/pengumuman'),
                      onLogout: () => ref.read(authProvider.notifier).logout(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ringkasan Bulan Ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola arus kas harian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.appMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BalanceHeroCard(
                      saldoLabel: _idrFormatter.format(state.summary.saldo),
                      monthLabel: _selectedMonthLabelForState(state),
                      onTapMonth: () => _showMonthPicker(context, ref, state),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricCard(
                            icon: Icons.south_rounded,
                            iconColor: const Color(0xFF16A34A),
                            iconBackground: const Color(0xFFDDF8E7),
                            label: 'Pemasukan',
                            amountLabel: _idrFormatter.format(
                              state.summary.totalPemasukan,
                            ),
                            onTap: () =>
                                _openFilteredList(context, jenis: 'pemasukan'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryMetricCard(
                            icon: Icons.north_rounded,
                            iconColor: const Color(0xFFE25555),
                            iconBackground: const Color(0xFFFFE5E8),
                            label: 'Pengeluaran',
                            amountLabel: _idrFormatter.format(
                              state.summary.totalPengeluaran,
                            ),
                            onTap: () => _openFilteredList(
                              context,
                              jenis: 'pengeluaran',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transaksi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openKeuanganForm(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4E44F2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Tambah Transaksi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (state.errorMessage != null) ...[
                      _ErrorBanner(message: state.errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    if (state.items.isEmpty)
                      const _EmptyTransactionCard()
                    else
                      Column(
                        children: [
                          for (var i = 0; i < state.items.length; i++) ...[
                            _TransactionCard(
                              item: state.items[i],
                              onTap: () => _showTransactionActionsSheet(
                                context,
                                ref,
                                state.items[i],
                              ),
                            ),
                            if (i != state.items.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _openFilteredList(
    BuildContext context, {
    required String jenis,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MonthlyTransactionListScreen(jenis: jenis),
      ),
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    WidgetRef ref,
    KeuanganState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text(
                  'Pilih Bulan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ...state.monthOptions.map((option) {
                final isSelected = option.value == state.selectedMonth;
                return ListTile(
                  title: Text(option.label),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF4F46E5))
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref
                        .read(keuanganProvider.notifier)
                        .selectMonth(option.value);
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyTransactionListScreen extends ConsumerWidget {
  final String jenis;

  const _MonthlyTransactionListScreen({required this.jenis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(keuanganProvider);
    final visual = _jenisVisual(jenis);
    final monthLabel = _selectedMonthLabelForState(state);
    final rows = state.items.where((item) => item.jenis == jenis).toList();
    final total = rows.fold<double>(0, (sum, item) => sum + item.nominal);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          visual.screenTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _FilteredTransactionHeroCard(
                  visual: visual,
                  monthLabel: monthLabel,
                  totalLabel: _idrFormatter.format(total),
                  totalItems: rows.length,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visual.sectionTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE5E7F2)),
                      ),
                      child: Text(
                        '${rows.length} item',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF707792),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.errorMessage != null) ...[
                  _ErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (rows.isEmpty)
                  _EmptyTransactionCard(
                    message: visual.emptyMessage(monthLabel),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        _TransactionCard(
                          item: rows[i],
                          onTap: () => _showTransactionActionsSheet(
                            context,
                            ref,
                            rows[i],
                          ),
                        ),
                        if (i != rows.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
              ],
            ),
    );
  }
}

class _FinanceTopBar extends StatelessWidget {
  final User? user;
  final String userName;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogout;

  const _FinanceTopBar({
    required this.user,
    required this.userName,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onLogout,
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
                              color: const Color(0xFF3542D4),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _greetingLabel(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7A7F9A),
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

class _BalanceHeroCard extends StatelessWidget {
  final String saldoLabel;
  final String monthLabel;
  final VoidCallback onTapMonth;

  const _BalanceHeroCard({
    required this.saldoLabel,
    required this.monthLabel,
    required this.onTapMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTapMonth,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A45F3), Color(0xFF4036DA)],
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
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SALDO',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      saldoLabel,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          monthLabel,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _SummaryMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String amountLabel;
  final VoidCallback onTap;

  const _SummaryMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.amountLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: context.appCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: const Color(0xFF7A819C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amountLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilteredTransactionHeroCard extends StatelessWidget {
  final _JenisVisual visual;
  final String monthLabel;
  final String totalLabel;
  final int totalItems;

  const _FilteredTransactionHeroCard({
    required this.visual,
    required this.monthLabel,
    required this.totalLabel,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: visual.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(visual.icon, color: visual.iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visual.heroKicker,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: visual.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            visual.totalLabel(totalItems),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6F7690),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final KeuanganTransaction item;
  final VoidCallback onTap;

  const _TransactionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = item.isPemasukan;
    final subtitle = (item.deskripsi ?? '').trim().isNotEmpty
        ? item.deskripsi!.trim()
        : item.jenis == 'pemasukan'
        ? 'Pemasukan'
        : 'Pengeluaran';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: context.appCardShadow,
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  resolveKeuanganCategoryIcon(
                    kategori: item.kategori,
                    jenis: item.jenis,
                    emptyFallback: Icons.receipt_long_outlined,
                  ),
                  color: const Color(0xFF525A6F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.kategori.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6F7690),
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
                    '${isIncome ? '+' : '-'} ${_idrFormatter.format(item.nominal)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isIncome
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE25555),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTransactionMoment(item.tanggal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA0A5B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionCard extends StatelessWidget {
  final String message;

  const _EmptyTransactionCard({
    this.message = 'Belum ada transaksi di bulan ini.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: context.appCardShadow,
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
          fontSize: 13,
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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

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

String _greetingLabel() {
  final hour = DateTime.now().hour;
  if (hour < 11) {
    return 'Pagi produktif';
  }
  if (hour < 15) {
    return 'Siang fokus';
  }
  if (hour < 18) {
    return 'Sore terarah';
  }
  return 'Malam terencana';
}

String _formatTransactionMoment(DateTime dateTime) {
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final difference = dayStart.difference(targetDay).inDays;
  final timeLabel = DateFormat('HH:mm', 'id_ID').format(dateTime);

  if (difference == 0) {
    return 'Hari ini, $timeLabel';
  }

  if (difference == 1) {
    return 'Kemarin, $timeLabel';
  }

  return '${DateFormat('dd MMM', 'id_ID').format(dateTime)}, $timeLabel';
}

String _selectedMonthLabelForState(KeuanganState state) {
  final selected = state.monthOptions.where(
    (option) => option.value == state.selectedMonth,
  );

  if (selected.isNotEmpty) {
    final label = selected.first.label.trim();
    if (label.isNotEmpty) {
      return label;
    }
  }

  return state.selectedMonth;
}

Future<void> _openKeuanganForm(
  BuildContext context, {
  KeuanganTransaction? transaction,
  String? presetJenis,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => KeuanganFormScreen(
        transaction: transaction,
        initialJenis: presetJenis,
      ),
    ),
  );
}

Future<void> _confirmDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  KeuanganTransaction item,
) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus transaksi?'),
      content: Text('Transaksi "${item.kategori}" akan dihapus permanen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48),
          ),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  if (shouldDelete != true) {
    return;
  }

  final success = await ref
      .read(keuanganProvider.notifier)
      .deleteTransaction(item.id);

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Transaksi dihapus.' : 'Gagal menghapus transaksi.',
      ),
      backgroundColor: success
          ? const Color(0xFF166534)
          : const Color(0xFFB91C1C),
    ),
  );
}

Future<void> _showTransactionActionsSheet(
  BuildContext context,
  WidgetRef ref,
  KeuanganTransaction item,
) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit transaksi'),
              onTap: () {
                Navigator.of(ctx).pop();
                _openKeuanganForm(context, transaction: item);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFE11D48),
              ),
              title: const Text(
                'Hapus transaksi',
                style: TextStyle(color: Color(0xFFE11D48)),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteTransaction(context, ref, item);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

class _JenisVisual {
  final String jenis;
  final String screenTitle;
  final String sectionTitle;
  final String heroKicker;
  final IconData icon;
  final Color primaryColor;
  final Color iconColor;
  final Color iconBackground;

  const _JenisVisual({
    required this.jenis,
    required this.screenTitle,
    required this.sectionTitle,
    required this.heroKicker,
    required this.icon,
    required this.primaryColor,
    required this.iconColor,
    required this.iconBackground,
  });

  String totalLabel(int totalItems) {
    if (jenis == 'pemasukan') {
      return '$totalItems pemasukan tercatat bulan ini';
    }

    return '$totalItems pengeluaran tercatat bulan ini';
  }

  String emptyMessage(String monthLabel) {
    if (jenis == 'pemasukan') {
      return 'Belum ada pemasukan yang tercatat di $monthLabel.';
    }

    return 'Belum ada pengeluaran yang tercatat di $monthLabel.';
  }
}

_JenisVisual _jenisVisual(String jenis) {
  if (jenis == 'pemasukan') {
    return const _JenisVisual(
      jenis: 'pemasukan',
      screenTitle: 'Pemasukan',
      sectionTitle: 'Daftar Pemasukan',
      heroKicker: 'PEMASUKAN BULAN INI',
      icon: Icons.south_rounded,
      primaryColor: Color(0xFF16A34A),
      iconColor: Color(0xFF16A34A),
      iconBackground: Color(0xFFDDF8E7),
    );
  }

  return const _JenisVisual(
    jenis: 'pengeluaran',
    screenTitle: 'Pengeluaran',
    sectionTitle: 'Daftar Pengeluaran',
    heroKicker: 'PENGELUARAN BULAN INI',
    icon: Icons.north_rounded,
    primaryColor: Color(0xFFE25555),
    iconColor: Color(0xFFE25555),
    iconBackground: Color(0xFFFFE5E8),
  );
}
