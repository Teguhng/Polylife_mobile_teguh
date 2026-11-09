import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/ai/widgets/ai_app_bar_action.dart';
import 'package:mobile_ver/core/utils/pdf_download.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_statistics_model.dart';
import 'package:mobile_ver/features/keuangan/services/keuangan_statistics_pdf_exporter.dart';
import 'package:printing/printing.dart';

final NumberFormat _statisticsIdr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class KeuanganStatisticsScreen extends StatefulWidget {
  const KeuanganStatisticsScreen({super.key});

  @override
  State<KeuanganStatisticsScreen> createState() =>
      _KeuanganStatisticsScreenState();
}

class _KeuanganStatisticsScreenState extends State<KeuanganStatisticsScreen> {
  static const _pdfExporter = KeuanganStatisticsPdfExporter();
  late int _year = DateTime.now().year;
  late Future<KeuanganAnnualStatistics> _statistics = _load(_year);
  bool _exporting = false;

  Future<KeuanganAnnualStatistics> _load(int year) async {
    final response = await ApiClient.get('/keuangan/statistik?tahun=$year');
    if (response.statusCode != 200) {
      throw Exception(_responseMessage(response.body));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('Format statistik tidak dikenali.');
    }
    return KeuanganAnnualStatistics.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  String _responseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Use the fallback message for non-JSON responses.
    }
    return 'Statistik keuangan belum bisa dimuat.';
  }

  void _selectYear(int year) {
    if (year == _year) return;
    setState(() {
      _year = year;
      _statistics = _load(year);
    });
  }

  Future<void> _exportPdf(KeuanganAnnualStatistics statistics) async {
    setState(() => _exporting = true);
    try {
      final bytes = await _pdfExporter.build(statistics);
      final filename = 'laporan-keuangan-${statistics.year}.pdf';
      if (kIsWeb) {
        await downloadPdfBytes(bytes, filename);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF gagal dibuat: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Statistik Keuangan',
          style: GoogleFonts.plusJakartaSans(
            color: context.appText,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [AiAppBarAction()],
      ),
      body: FutureBuilder<KeuanganAnnualStatistics>(
        future: _statistics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _StatisticsError(
              message:
                  snapshot.error?.toString().replaceFirst('Exception: ', '') ??
                  'Statistik keuangan belum bisa dimuat.',
              onRetry: () => setState(() => _statistics = _load(_year)),
            );
          }
          final statistics = snapshot.requireData;
          if (statistics.year != _year) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && statistics.year > 0 && statistics.year != _year) {
                setState(() => _year = statistics.year);
              }
            });
          }
          return RefreshIndicator(
            color: context.appPrimary,
            onRefresh: () async => setState(() => _statistics = _load(_year)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _StatisticsYearHeader(
                  year: statistics.year,
                  years: statistics.yearOptions.isEmpty
                      ? [_year]
                      : statistics.yearOptions,
                  onChanged: _selectYear,
                  onExport: () => _exportPdf(statistics),
                  isExporting: _exporting,
                ),
                const SizedBox(height: 16),
                _AnnualSummaryCard(statistics: statistics),
                const SizedBox(height: 16),
                _MonthlyTrendCard(statistics: statistics),
                const SizedBox(height: 16),
                _CategoryTables(statistics: statistics),
                if (statistics.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SuggestionsCard(suggestions: statistics.suggestions),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatisticsYearHeader extends StatelessWidget {
  final int year;
  final List<int> years;
  final ValueChanged<int> onChanged;
  final VoidCallback onExport;
  final bool isExporting;

  const _StatisticsYearHeader({
    required this.year,
    required this.years,
    required this.onChanged,
    required this.onExport,
    required this.isExporting,
  });

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Tahunan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analisis keuangan dan kinerja anggaran tahun $year',
            style: TextStyle(color: context.appMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Tahun', style: TextStyle(color: context.appMuted)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: years.contains(year) ? year : years.first,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: context.appSurfaceAlt,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.appBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.appBorder),
                    ),
                  ),
                  dropdownColor: context.appSurface,
                  style: TextStyle(color: context.appText),
                  items: years
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text('$item')),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isExporting ? null : onExport,
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(isExporting ? 'Menyiapkan PDF...' : 'Ekspor PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnualSummaryCard extends StatelessWidget {
  final KeuanganAnnualStatistics statistics;
  const _AnnualSummaryCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return _StatsCard(
      child: Column(
        children: [
          _MetricTile(
            label: 'Total Pemasukan',
            value: _statisticsIdr.format(statistics.totalIncome),
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Total Pengeluaran',
            value: _statisticsIdr.format(statistics.totalExpenses),
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Saldo (Netto)',
            value: _statisticsIdr.format(statistics.totalNet),
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: statistics.isDeficit
                ? 'Savings Rate · Defisit'
                : 'Tingkat Tabungan',
            value:
                '${(statistics.savingsRate * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
            color: statistics.isDeficit
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Rata-rata Pemasukan / bulan',
            value: _statisticsIdr.format(statistics.averageIncome),
            color: context.appMuted,
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: 'Rata-rata Pengeluaran / bulan',
            value: _statisticsIdr.format(statistics.averageExpenses),
            color: context.appMuted,
          ),
          const SizedBox(height: 10),
          _MetricTile(
            label: statistics.projectionLabel,
            value: _statisticsIdr.format(statistics.yearEndProjection),
            color: context.appMuted,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: context.appText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  final KeuanganAnnualStatistics statistics;
  const _MonthlyTrendCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    final labels = statistics.labels.isEmpty
        ? const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agu',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ]
        : statistics.labels;
    return _StatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tren Bulanan', style: _sectionStyle(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _LegendDot(color: Color(0xFF10B981), label: 'Pemasukan'),
              _LegendDot(color: Color(0xFFEF4444), label: 'Pengeluaran'),
              _LegendDot(color: Color(0xFF6366F1), label: 'Netto'),
              _LegendDot(color: Color(0xFFF59E0B), label: 'Saldo kumulatif'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: LayoutBuilder(
              builder: (context, constraints) => CustomPaint(
                size: Size(constraints.maxWidth, 230),
                painter: _MonthlyTrendPainter(
                  labels: labels,
                  income: statistics.incomeByMonth,
                  expenses: statistics.expensesByMonth,
                  net: statistics.netByMonth,
                  balance: statistics.balanceByMonth,
                  textColor: context.appMuted,
                  gridColor: context.appBorder,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: context.appMuted, fontSize: 10)),
    ],
  );
}

class _MonthlyTrendPainter extends CustomPainter {
  final List<String> labels;
  final List<double> income;
  final List<double> expenses;
  final List<double> net;
  final List<double> balance;
  final Color textColor;
  final Color gridColor;

  _MonthlyTrendPainter({
    required this.labels,
    required this.income,
    required this.expenses,
    required this.net,
    required this.balance,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final count = labels.length;
    if (count == 0 || chartWidth <= 0 || chartHeight <= 0) return;

    final maxAmount = [
      ...income,
      ...expenses,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final barMax = maxAmount <= 0 ? 1.0 : maxAmount * 1.15;
    final balanceMaxRaw = [
      ...net,
      ...balance,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final balanceMinRaw = [
      ...net,
      ...balance,
    ].fold<double>(0, (a, b) => a < b ? a : b);
    final balanceRange = (balanceMaxRaw - balanceMinRaw).abs() < 1
        ? 1.0
        : balanceMaxRaw - balanceMinRaw;
    final slot = chartWidth / count;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .65)
      ..strokeWidth = 1;
    final axisText = TextStyle(color: textColor, fontSize: 9);
    for (var row = 0; row <= 4; row++) {
      final y = top + chartHeight * row / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final amount = barMax * (4 - row) / 4;
      _drawText(
        canvas,
        _compactAmount(amount),
        Offset(0, y - 6),
        axisText,
        maxWidth: left - 3,
      );
    }

    final incomePaint = Paint()..color = const Color(0xFF10B981);
    final expensePaint = Paint()..color = const Color(0xFFEF4444);
    final lineNet = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final lineBalance = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final netPath = Path();
    final balancePath = Path();
    for (var i = 0; i < count; i++) {
      final centerX = left + slot * (i + .5);
      final incomeValue = i < income.length ? income[i] : 0.0;
      final expenseValue = i < expenses.length ? expenses[i] : 0.0;
      final barWidth = slot * .22;
      final incomeHeight = chartHeight * incomeValue / barMax;
      final expenseHeight = chartHeight * expenseValue / barMax;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth - 1,
            top + chartHeight - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(2),
        ),
        incomePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + 1,
            top + chartHeight - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(2),
        ),
        expensePaint,
      );

      final netValue = i < net.length ? net[i] : 0.0;
      final balanceValue = i < balance.length ? balance[i] : 0.0;
      final netY =
          top + chartHeight * (1 - (netValue - balanceMinRaw) / balanceRange);
      final balanceY =
          top +
          chartHeight * (1 - (balanceValue - balanceMinRaw) / balanceRange);
      if (i == 0) {
        netPath.moveTo(centerX, netY);
        balancePath.moveTo(centerX, balanceY);
      } else {
        netPath.lineTo(centerX, netY);
        balancePath.lineTo(centerX, balanceY);
      }
      canvas.drawCircle(
        Offset(centerX, netY),
        2.5,
        Paint()..color = const Color(0xFF6366F1),
      );
      canvas.drawCircle(
        Offset(centerX, balanceY),
        2.5,
        Paint()..color = const Color(0xFFF59E0B),
      );
      _drawText(
        canvas,
        labels[i],
        Offset(centerX - slot / 2, size.height - bottom + 5),
        axisText,
        maxWidth: slot,
      );
    }
    canvas.drawPath(netPath, lineNet);
    canvas.drawPath(balancePath, lineBalance);
  }

  void _drawText(
    Canvas canvas,
    String value,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  String _compactAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(0)}jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
    return amount.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) =>
      oldDelegate.income != income ||
      oldDelegate.expenses != expenses ||
      oldDelegate.net != net ||
      oldDelegate.balance != balance ||
      oldDelegate.textColor != textColor ||
      oldDelegate.gridColor != gridColor;
}

class _CategoryTables extends StatelessWidget {
  final KeuanganAnnualStatistics statistics;
  const _CategoryTables({required this.statistics});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _CategoryCard(
        title: 'Top Kategori Pengeluaran',
        entries: statistics.topExpenseCategories,
      ),
      const SizedBox(height: 14),
      _CategoryCard(
        title: 'Top Kategori Pemasukan',
        entries: statistics.topIncomeCategories,
      ),
    ],
  );
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final Map<String, double> entries;
  const _CategoryCard({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) => _StatsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _sectionStyle(context)),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Text('Tidak ada data', style: TextStyle(color: context.appMuted))
        else
          ...entries.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(color: context.appText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statisticsIdr.format(entry.value),
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _SuggestionsCard extends StatelessWidget {
  final List<String> suggestions;
  const _SuggestionsCard({required this.suggestions});

  @override
  Widget build(BuildContext context) => _StatsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saran Otomatis', style: _sectionStyle(context)),
        const SizedBox(height: 8),
        ...suggestions.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: context.appPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(color: context.appText, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatisticsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _StatisticsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.query_stats_rounded, size: 42, color: context.appMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMuted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}

class _StatsCard extends StatelessWidget {
  final Widget child;
  const _StatsCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appCardShadow,
    ),
    child: child,
  );
}

TextStyle _sectionStyle(BuildContext context) => GoogleFonts.plusJakartaSans(
  fontSize: 16,
  fontWeight: FontWeight.w800,
  color: context.appText,
);
