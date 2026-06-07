import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';

class AllSummaryCard extends StatelessWidget {
  final List<KeuanganTransaction> items;
  final NumberFormat formatter;

  const AllSummaryCard({
    super.key,
    required this.items,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final totalIn = items
        .where((item) => item.jenis == 'pemasukan')
        .fold<double>(0, (sum, item) => sum + item.nominal);
    final totalOut = items
        .where((item) => item.jenis == 'pengeluaran')
        .fold<double>(0, (sum, item) => sum + item.nominal);
    final saldo = totalIn - totalOut;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Seluruh Data',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Saldo: ${formatter.format(saldo)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pemasukan ${formatter.format(totalIn)} • Pengeluaran ${formatter.format(totalOut)}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
