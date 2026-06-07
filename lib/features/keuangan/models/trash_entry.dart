import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';

class TrashEntry {
  final KeuanganTransaction item;
  final DateTime deletedAt;

  TrashEntry({required this.item, required this.deletedAt});
}
