import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class Reminder {
  final int id;
  String title;
  int hour;
  int minute;
  bool enabled;

  Reminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  factory Reminder.newFor({
    required String title,
    required int hour,
    required int minute,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    return Reminder(id: id, title: title, hour: hour, minute: minute);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  static Reminder fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as int,
        title: j['title'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        enabled: (j['enabled'] as bool?) ?? true,
      );
}

class ReminderStore {
  static const _key = 'daily_reminders_v1';

  static Future<List<Reminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  static Future<void> _save(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(reminders.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<void> add(Reminder r) async {
    final list = await load();
    list.add(r);
    await _save(list);
    if (r.enabled) {
      try {
        print('[ReminderStore] Scheduling new reminder id=${r.id} at ${r.hour}:${r.minute}');
        await NotificationService.scheduleDailyNotification(
          id: r.id,
          hour: r.hour,
          minute: r.minute,
          title: 'Reminder',
          body: r.title,
        );
      } catch (e) {
        print('[ReminderStore] scheduleDailyNotification failed: $e');
      }
    }
  }

  static Future<void> update(Reminder updated) async {
    final list = await load();
    final idx = list.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    list[idx] = updated;
    await _save(list);
    // Re-schedule safely
    try {
      print('[ReminderStore] Cancel existing schedule id=${updated.id}');
      await NotificationService.cancel(updated.id);
    } catch (e) {
      print('[ReminderStore] cancel failed: $e');
    }
    if (updated.enabled) {
      try {
        print('[ReminderStore] Re-scheduling id=${updated.id} at ${updated.hour}:${updated.minute}');
        await NotificationService.scheduleDailyNotification(
          id: updated.id,
          hour: updated.hour,
          minute: updated.minute,
          title: 'Reminder',
          body: updated.title,
        );
      } catch (e) {
        print('[ReminderStore] reschedule failed: $e');
      }
    }
  }

  static Future<void> remove(int id) async {
    final list = await load();
    list.removeWhere((e) => e.id == id);
    await _save(list);
    try {
      print('[ReminderStore] Cancel schedule id=$id');
      await NotificationService.cancel(id);
    } catch (e) {
      print('[ReminderStore] cancel failed: $e');
    }
  }

  static Future<void> toggle(int id, bool enabled) async {
    final list = await load();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final r = list[idx];
    r.enabled = enabled;
    await _save(list);
    if (enabled) {
      try {
        print('[ReminderStore] Toggle ON id=${r.id} ${r.hour}:${r.minute}');
        await NotificationService.scheduleDailyNotification(
          id: r.id,
          hour: r.hour,
          minute: r.minute,
          title: 'Reminder',
          body: r.title,
        );
      } catch (e) {
        print('[ReminderStore] toggle schedule failed: $e');
      }
    } else {
      try {
        print('[ReminderStore] Toggle OFF id=${r.id}');
        await NotificationService.cancel(r.id);
      } catch (e) {
        print('[ReminderStore] toggle cancel failed: $e');
      }
    }
  }
}
