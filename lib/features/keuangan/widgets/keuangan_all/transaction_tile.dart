import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';
import 'package:mobile_ver/features/keuangan/utils/category_icon_resolver.dart';

class AllTransactionTile extends StatelessWidget {
  final KeuanganTransaction item;
  final NumberFormat formatter;

  const AllTransactionTile({
    super.key,
    required this.item,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = item.jenis == 'pemasukan';
    final dateText = DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggal);
    final subtitle = (item.deskripsi ?? '').trim().isEmpty
        ? item.jenis
        : item.deskripsi!.trim();
    final icon = resolveKeuanganCategoryIcon(
      kategori: item.kategori,
      jenis: item.jenis,
      emptyFallback: Icons.receipt_long_outlined,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFF1F5F9),
            foregroundColor: isIncome
                ? const Color(0xFF16A34A)
                : const Color(0xFF475569),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kategori,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateText • $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${formatter.format(item.nominal)}',
            style: TextStyle(
              color: isIncome
                  ? const Color(0xFF166534)
                  : const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
