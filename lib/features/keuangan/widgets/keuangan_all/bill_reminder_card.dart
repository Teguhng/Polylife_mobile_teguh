import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/features/keuangan/models/bill_reminder_item.dart';

class BillReminderCard extends StatelessWidget {
  final List<BillReminderItem> billReminders;
  final VoidCallback onAddBillReminder;
  final Function(BillReminderItem) onPayBill;
  final NumberFormat formatter;

  const BillReminderCard({
    super.key,
    required this.billReminders,
    required this.onAddBillReminder,
    required this.onPayBill,
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
                  'Reminder Tagihan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                onPressed: onAddBillReminder,
                child: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (billReminders.isEmpty)
            const Text(
              'Belum ada reminder tagihan.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            Column(
              children: billReminders.map((item) {
                final overdue =
                    !item.paid && item.dueDate.isBefore(DateTime.now());
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: overdue
                        ? const Color(0xFFFFE4E6)
                        : const Color(0xFFEEF2FF),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: overdue
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF4F46E5),
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${formatter.format(item.amount)} • jatuh tempo ${DateFormat('dd MMM yyyy', 'id_ID').format(item.dueDate)}',
                  ),
                  trailing: item.paid
                      ? const Text(
                          'Lunas',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : TextButton(
                          onPressed: () => onPayBill(item),
                          child: const Text('Bayar'),
                        ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
