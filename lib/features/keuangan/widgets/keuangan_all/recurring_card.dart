import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/features/keuangan/models/recurring_template.dart';

class RecurringCard extends StatelessWidget {
  final List<RecurringTemplate> recurringTemplates;
  final VoidCallback onAddRecurring;
  final VoidCallback onProcessDue;
  final Function(RecurringTemplate) onToggleActive;
  final Function(RecurringTemplate) onRunNow;
  final NumberFormat formatter;

  const RecurringCard({
    super.key,
    required this.recurringTemplates,
    required this.onAddRecurring,
    required this.onProcessDue,
    required this.onToggleActive,
    required this.onRunNow,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transaksi Berulang',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                onPressed: onAddRecurring,
                child: const Text('Tambah'),
              ),
              OutlinedButton(
                onPressed: onProcessDue,
                child: const Text('Proses'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (recurringTemplates.isEmpty)
            const Text(
              'Belum ada template berulang.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            Column(
              children: recurringTemplates.map((item) {
                return SwitchListTile(
                  value: item.active,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    item.active =
                        value; // Update the reference directly or wait for callback
                    onToggleActive(item);
                  },
                  title: Text(
                    '${item.kategori} (${item.frequencyLabel})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.jenis} • ${formatter.format(item.nominal)} • next ${DateFormat('dd MMM yyyy', 'id_ID').format(item.nextRun)}',
                  ),
                  secondary: IconButton(
                    tooltip: 'Jalankan sekarang',
                    onPressed: () => onRunNow(item),
                    icon: const Icon(Icons.play_circle_outline),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
