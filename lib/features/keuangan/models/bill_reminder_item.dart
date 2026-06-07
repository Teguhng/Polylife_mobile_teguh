class BillReminderItem {
  final int id;
  final String name;
  final double amount;
  final DateTime dueDate;
  bool paid;

  BillReminderItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.paid,
  });
}
