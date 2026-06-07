import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/reminder/models/reminder_list_item.dart';
import 'package:mobile_ver/features/reminder/models/reminder_target_option.dart';
import 'package:mobile_ver/features/reminder/models/upcoming_reminder.dart';

void main() {
  group('Reminder models', () {
    test('parses reminder list item with active wire variants', () {
      final activeFromString = ReminderListItem.fromJson({
        'id': 7,
        'sync_uuid': 'reminder-uuid',
        'server_version': 4,
        'title': 'Kumpulkan tugas',
        'target_type': 'todo',
        'target_label': 'Tugas UI',
        'target_context': 'Besok',
        'destination': 'todolist',
        'active': '1',
        'scheduled_at': '2026-05-13T09:30:00Z',
        'scheduled_label': '13 Mei 2026 09:30',
      });
      final inactive = ReminderListItem.fromJson({'active': 0});

      expect(activeFromString.id, 7);
      expect(activeFromString.serverId, 7);
      expect(activeFromString.localUuid, 'reminder-uuid');
      expect(activeFromString.serverVersion, 4);
      expect(activeFromString.active, isTrue);
      expect(activeFromString.scheduledAt, isNotNull);
      expect(inactive.active, isFalse);
      expect(inactive.title, 'Reminder');
      expect(inactive.destination, 'todo');
    });

    test('parses upcoming reminder with safe fallback values', () {
      final reminder = UpcomingReminder.fromJson({
        'id': 9,
        'title': 'Bayar kos',
        'target_type': 'finance',
        'scheduled_at': '2026-05-14T10:00:00Z',
        'scheduled_label': 'Besok 10:00',
        'relative_label': 'Besok',
        'time_left_text': '23 jam lagi',
        'seconds_left': 'bad-number',
      });

      expect(reminder.id, 9);
      expect(reminder.title, 'Bayar kos');
      expect(reminder.targetType, 'finance');
      expect(reminder.scheduledAt, isNotNull);
      expect(reminder.secondsLeft, 0);
    });

    test('parses target options and ignores malformed option rows', () {
      final option = ReminderTargetOption.fromJson({
        'key': 'todolist',
        'label': 'To-Do',
        'helper': 'Pilih tugas',
        'options': [
          {'id': 1, 'label': 'Tugas A'},
          'rusak',
          {'id': '2', 'label': 'Tugas B'},
        ],
      });

      expect(option.key, 'todolist');
      expect(option.options, hasLength(2));
      expect(option.options.map((item) => item.label), ['Tugas A', 'Tugas B']);
    });
  });
}
