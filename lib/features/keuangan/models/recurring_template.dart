class RecurringTemplate {
  final int id;
  final String jenis;
  final String kategori;
  final double nominal;
  final String frequency;
  DateTime nextRun;
  bool active;

  RecurringTemplate({
    required this.id,
    required this.jenis,
    required this.kategori,
    required this.nominal,
    required this.frequency,
    required this.nextRun,
    required this.active,
  });

  String get frequencyLabel {
    if (frequency == 'daily') return 'Harian';
    if (frequency == 'weekly') return 'Mingguan';
    return 'Bulanan';
  }
}
