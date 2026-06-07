import 'package:intl/intl.dart';

import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';

class KeuanganAllExporter {
  const KeuanganAllExporter();

  double? parseMoney(String raw) {
    var cleaned = raw.trim().replaceAll(RegExp(r'[^0-9,\.\-]'), '');
    if (cleaned.isEmpty) {
      return null;
    }

    final isNegative = cleaned.startsWith('-');
    cleaned = cleaned.replaceAll('-', '');
    if (cleaned.isEmpty) {
      return null;
    }

    final dotCount = '.'.allMatches(cleaned).length;
    final commaCount = ','.allMatches(cleaned).length;

    String normalized = cleaned;
    if (dotCount > 0 && commaCount > 0) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      final decimalSeparator = lastDot > lastComma ? '.' : ',';
      final thousandSeparator = decimalSeparator == '.' ? ',' : '.';

      normalized = cleaned.replaceAll(thousandSeparator, '');
      if (decimalSeparator == ',') {
        normalized = normalized.replaceAll(',', '.');
      }
    } else if (commaCount > 0) {
      normalized = _normalizeSingleSeparator(cleaned, ',');
    } else if (dotCount > 0) {
      normalized = _normalizeSingleSeparator(cleaned, '.');
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return null;
    }
    return isNegative ? -parsed : parsed;
  }

  String buildCsv(List<KeuanganTransaction> rows) {
    final buffer = StringBuffer();
    buffer.writeln('id,tanggal,jenis,kategori,deskripsi,nominal');

    for (final row in rows) {
      buffer.writeln(
        '${row.id},${DateFormat('yyyy-MM-dd').format(row.tanggal)},${_escapeCsv(row.jenis)},${_escapeCsv(row.kategori)},${_escapeCsv(row.deskripsi ?? '')},${row.nominal.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  String buildPdfStyleReport({
    required List<KeuanganTransaction> rows,
    required NumberFormat formatter,
  }) {
    final totalIn = rows
        .where((item) => item.jenis == 'pemasukan')
        .fold<double>(0, (sum, item) => sum + item.nominal);
    final totalOut = rows
        .where((item) => item.jenis == 'pengeluaran')
        .fold<double>(0, (sum, item) => sum + item.nominal);

    final buffer = StringBuffer();
    buffer.writeln('POLYLIFE - LAPORAN KEUANGAN');
    buffer.writeln(
      'Tanggal cetak: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
    );
    buffer.writeln('Jumlah transaksi: ${rows.length}');
    buffer.writeln('Pemasukan: ${formatter.format(totalIn)}');
    buffer.writeln('Pengeluaran: ${formatter.format(totalOut)}');
    buffer.writeln('Saldo: ${formatter.format(totalIn - totalOut)}');
    buffer.writeln('');
    buffer.writeln('DETAIL TRANSAKSI');

    for (final row in rows) {
      buffer.writeln(
        '- ${DateFormat('yyyy-MM-dd').format(row.tanggal)} | ${row.jenis.toUpperCase()} | ${row.kategori} | ${formatter.format(row.nominal)}',
      );
    }

    return buffer.toString();
  }

  String currentMonthKey() {
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _normalizeSingleSeparator(String source, String separator) {
    final parts = source.split(separator);
    if (parts.length == 1) {
      return source;
    }

    if (parts.length == 2) {
      final whole = parts.first;
      final fraction = parts.last;
      if (fraction.isEmpty) {
        return whole;
      }

      // Money decimals typically use at most 2 digits. Otherwise treat as thousands separator.
      if (fraction.length <= 2) {
        return '$whole.$fraction';
      }
      return '$whole$fraction';
    }

    final head = parts.sublist(0, parts.length - 1).join('');
    final tail = parts.last;

    if (tail.isEmpty) {
      return head;
    }
    if (tail.length <= 2) {
      return '$head.$tail';
    }
    return '$head$tail';
  }
}
