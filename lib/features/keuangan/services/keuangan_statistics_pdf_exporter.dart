import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_statistics_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class KeuanganStatisticsPdfExporter {
  const KeuanganStatisticsPdfExporter();

  Future<Uint8List> build(KeuanganAnnualStatistics statistics) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final labels = statistics.labels.length == 12
        ? statistics.labels
        : const [
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
          ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 38, 36, 38),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'POLYLIFE  •  LAPORAN KEUANGAN',
            style: pw.TextStyle(
              color: PdfColors.blueGrey600,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(
              color: PdfColors.blueGrey500,
              fontSize: 8,
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Statistik Keuangan ${statistics.year}',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Dibuat ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
              color: PdfColors.blueGrey600,
              fontSize: 9,
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Ringkasan Tahunan'),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _metric(
                    'Total pemasukan',
                    formatter.format(statistics.totalIncome),
                    PdfColors.green800,
                  ),
                  _metric(
                    'Total pengeluaran',
                    formatter.format(statistics.totalExpenses),
                    PdfColors.red800,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _metric(
                    'Saldo (netto)',
                    formatter.format(statistics.totalNet),
                    PdfColors.indigo800,
                  ),
                  _metric(
                    'Tingkat tabungan',
                    '${(statistics.savingsRate * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                    PdfColors.orange800,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _metric(
                    'Rata-rata pemasukan / bulan',
                    formatter.format(statistics.averageIncome),
                    PdfColors.blueGrey800,
                  ),
                  _metric(
                    'Rata-rata pengeluaran / bulan',
                    formatter.format(statistics.averageExpenses),
                    PdfColors.blueGrey800,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _metric(
                    statistics.projectionLabel,
                    formatter.format(statistics.yearEndProjection),
                    PdfColors.blueGrey800,
                  ),
                  _metric(
                    'Status',
                    statistics.isDeficit ? 'Defisit' : 'Surplus',
                    statistics.isDeficit
                        ? PdfColors.red800
                        : PdfColors.green800,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Tren Bulanan'),
          pw.SizedBox(height: 7),
          _table(
            headers: const [
              'Bulan',
              'Pemasukan',
              'Pengeluaran',
              'Netto',
              'Saldo kumulatif',
            ],
            rows: List.generate(
              12,
              (index) => [
                labels[index],
                formatter.format(_at(statistics.incomeByMonth, index)),
                formatter.format(_at(statistics.expensesByMonth, index)),
                formatter.format(_at(statistics.netByMonth, index)),
                formatter.format(_at(statistics.balanceByMonth, index)),
              ],
            ),
            numericColumns: const {1, 2, 3, 4},
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Kategori Pengeluaran Teratas'),
          pw.SizedBox(height: 7),
          _categoryTable(statistics.topExpenseCategories, formatter),
          pw.SizedBox(height: 18),
          _sectionTitle('Kategori Pemasukan Teratas'),
          pw.SizedBox(height: 7),
          _categoryTable(statistics.topIncomeCategories, formatter),
          if (statistics.suggestions.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Saran Otomatis'),
            pw.SizedBox(height: 7),
            ...statistics.suggestions.map(
              (suggestion) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Bullet(
                  text: suggestion,
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _metric(String label, String value, PdfColor color) => pw.Container(
    margin: const pw.EdgeInsets.all(3),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(color: PdfColors.blueGrey700, fontSize: 8),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  pw.Widget _sectionTitle(String title) => pw.Text(
    title,
    style: pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    ),
  );

  pw.Widget _categoryTable(
    Map<String, double> categories,
    NumberFormat formatter,
  ) {
    if (categories.isEmpty) {
      return pw.Text(
        'Tidak ada data',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600),
      );
    }
    return _table(
      headers: const ['Kategori', 'Total'],
      rows: categories.entries
          .map((entry) => [entry.key, formatter.format(entry.value)])
          .toList(),
      numericColumns: const {1},
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required Set<int> numericColumns,
  }) => pw.Table(
    border: pw.TableBorder(
      horizontalInside: const pw.BorderSide(
        color: PdfColors.grey300,
        width: .5,
      ),
      bottom: const pw.BorderSide(color: PdfColors.grey400, width: .7),
    ),
    columnWidths: {
      for (var i = 0; i < headers.length; i++)
        i: i == 0 ? const pw.FlexColumnWidth(1.1) : const pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          for (var i = 0; i < headers.length; i++)
            _cell(
              headers[i],
              bold: true,
              alignRight: numericColumns.contains(i),
            ),
        ],
      ),
      for (final row in rows)
        pw.TableRow(
          children: [
            for (var i = 0; i < headers.length; i++)
              _cell(row[i], alignRight: numericColumns.contains(i)),
          ],
        ),
    ],
  );

  pw.Widget _cell(String value, {bool bold = false, bool alignRight = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Align(
          alignment: alignRight
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );

  double _at(List<double> values, int index) =>
      index < values.length ? values[index] : 0;
}
