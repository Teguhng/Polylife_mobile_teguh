class ReminderOptionItem {
  final int id;
  final String label;

  const ReminderOptionItem({required this.id, required this.label});

  factory ReminderOptionItem.fromJson(Map<String, dynamic> json) {
    return ReminderOptionItem(
      id: _toInt(json['id']),
      label: json['label']?.toString() ?? '',
    );
  }
}

class ReminderTargetOption {
  final String key;
  final String label;
  final String helper;
  final List<ReminderOptionItem> options;

  const ReminderTargetOption({
    required this.key,
    required this.label,
    required this.helper,
    required this.options,
  });

  factory ReminderTargetOption.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    return ReminderTargetOption(
      key: json['key']?.toString() ?? 'todolist',
      label: json['label']?.toString() ?? 'To-Do',
      helper: json['helper']?.toString() ?? '',
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map(
                  (item) => ReminderOptionItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <ReminderOptionItem>[],
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
