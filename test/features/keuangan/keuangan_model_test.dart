import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';
import 'package:mobile_ver/features/keuangan/models/recurring_template.dart';

void main() {
  group('Keuangan model', () {
    test('parses transaction wire payload and builds API payload', () {
      final transaction = KeuanganTransaction.fromJson({
        'id': '15',
        'sync_uuid': 'finance-uuid',
        'server_version': '4',
        'jenis': 'pemasukan',
        'kategori': 'Gaji',
        'deskripsi': 'Part time',
        'nominal': '1250000.50',
        'tanggal': '2026-05-13',
      });

      expect(transaction.id, 15);
      expect(transaction.serverId, 15);
      expect(transaction.serverVersion, 4);
      expect(transaction.localUuid, 'finance-uuid');
      expect(transaction.isPemasukan, isTrue);
      expect(transaction.nominal, 1250000.50);
      expect(transaction.tanggal, DateTime(2026, 5, 13));
      expect(transaction.toPayload(), {
        'jenis': 'pemasukan',
        'kategori': 'Gaji',
        'deskripsi': 'Part time',
        'nominal': 1250000.50,
        'tanggal': '2026-05-13',
      });
    });

    test('uses safe defaults when transaction payload is incomplete', () {
      final transaction = KeuanganTransaction.fromJson({});

      expect(transaction.id, 0);
      expect(transaction.serverId, isNull);
      expect(transaction.serverVersion, 1);
      expect(transaction.jenis, 'pengeluaran');
      expect(transaction.kategori, '');
      expect(transaction.nominal, 0);
      expect(transaction.isPemasukan, isFalse);
    });

    test('parses summary and month option payloads', () {
      final summary = KeuanganSummary.fromJson({
        'total_pemasukan': '500000',
        'total_pengeluaran': 125000,
        'saldo': '375000.25',
      });
      final month = KeuanganMonthOption.fromJson({
        'value': '2026-05',
        'label': 'Mei 2026',
      });

      expect(summary.totalPemasukan, 500000);
      expect(summary.totalPengeluaran, 125000);
      expect(summary.saldo, 375000.25);
      expect(month.value, '2026-05');
      expect(month.label, 'Mei 2026');
    });

    test('maps recurring frequency labels', () {
      final daily = RecurringTemplate(
        id: 1,
        jenis: 'pengeluaran',
        kategori: 'Kopi',
        nominal: 15000,
        frequency: 'daily',
        nextRun: DateTime(2026, 5, 13),
        active: true,
      );
      final weekly = RecurringTemplate(
        id: 2,
        jenis: 'pengeluaran',
        kategori: 'Transport',
        nominal: 50000,
        frequency: 'weekly',
        nextRun: DateTime(2026, 5, 13),
        active: true,
      );
      final monthly = RecurringTemplate(
        id: 3,
        jenis: 'pemasukan',
        kategori: 'Gaji',
        nominal: 1000000,
        frequency: 'monthly',
        nextRun: DateTime(2026, 5, 13),
        active: true,
      );

      expect(daily.frequencyLabel, 'Harian');
      expect(weekly.frequencyLabel, 'Mingguan');
      expect(monthly.frequencyLabel, 'Bulanan');
    });
  });
}
