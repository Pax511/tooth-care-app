import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'reminders_channel_alarm_v2';
  static const String _channelName = 'Reminders (Alarm)';
  static const String _channelDesc = 'Scheduled reminders for tooth-care app';
  static const String _payloadPrefix = 'notif_payload_';
  static const String _dailyPrefix = 'notif_daily_';
  static bool useAlarmManager = false; // Toggle to enable/disable AlarmManager scheduling on Android


  static Future<void> init() async {
    if (_initialized) return;

    // Timezone init
    tz.initializeTimeZones();
    // Note: We are not using flutter_native_timezone here to avoid plugin build issues.
    // tz.local will be used as provided by the timezone package.

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit =
        const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
  await _plugin.initialize(settings);
  print('[NotificationService] Initialized plugin');

    // Android 13+ requires runtime permission
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      print('[NotificationService] Android notifications permission granted=$granted');
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
        ),
      );
      print('[NotificationService] Channel created: id=$_channelId');
    }

    _initialized = true;
    // Capability probe for Android exact alarms
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final canExact = await androidImpl.canScheduleExactNotifications() ?? false;
        print('[NotificationService] init complete (canScheduleExact=$canExact)');
      } else {
        print('[NotificationService] init complete (androidImpl=null)');
      }
    } catch (e) {
      print('[NotificationService] init complete (capability check error: $e)');
    }
  }

  // Store title/body so AlarmManager background callback can retrieve them
  static Future<void> _savePayload({required int id, required String title, required String body}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_payloadPrefix}${id}_title', title);
      await prefs.setString('${_payloadPrefix}${id}_body', body);
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] _savePayload error: $e');
    }
  }

  static Future<(String, String)?> _loadPayload(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final title = prefs.getString('${_payloadPrefix}${id}_title');
      final body = prefs.getString('${_payloadPrefix}${id}_body');
      if (title != null && body != null) return (title, body);
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] _loadPayload error: $e');
    }
    return null;
  }

  static Future<void> _clearPayload(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_payloadPrefix}${id}_title');
      await prefs.remove('${_payloadPrefix}${id}_body');
    } catch (_) {}
  }

  static Future<void> _saveDailyMeta({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_dailyPrefix}${id}_hour', hour);
      await prefs.setInt('${_dailyPrefix}${id}_minute', minute);
      await prefs.setString('${_dailyPrefix}${id}_title', title);
      await prefs.setString('${_dailyPrefix}${id}_body', body);
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] _saveDailyMeta error: $e');
    }
  }

  static Future<(int, int)?> _loadDailyTime(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('${_dailyPrefix}${id}_hour');
      final minute = prefs.getInt('${_dailyPrefix}${id}_minute');
      if (hour != null && minute != null) return (hour, minute);
    } catch (e) {}
    return null;
  }


  // Attempt to schedule using Android AlarmManager for reliability with app killed
  static Future<bool> _scheduleWithAlarmManagerAt({
    required int id,
    required DateTime scheduledAt,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await AndroidAlarmManager.oneShotAt(
        scheduledAt,
        id,
        notificationAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: false,
      );
      // ignore: avoid_print
      print('[NotificationService] AlarmManager scheduled=$ok at $scheduledAt (id=$id)');
      return ok;
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] AlarmManager schedule error: $e');
      return false;
    }
  }

  // Returns whether notifications are currently enabled (Android-specific implementation)
  static Future<bool> areNotificationsEnabled() async {
    await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled() ?? true;
      return enabled;
    }
    // For iOS/macOS, assume enabled if initialized
    return true;
  }

  // Attempts to request/ensure permissions and returns final enabled status
  static Future<bool> ensurePermissions() async {
    await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission() ?? true;
      return granted;
    }
    return true;
  }

  // Note: Opening OS notification settings is platform-specific and may
  // require an additional plugin. Not implemented here to avoid extra deps.

  // Quick one-off test: schedule after X seconds
  static Future<void> scheduleInSeconds({
    required int id,
    required int seconds,
    required String title,
    required String body,
  }) async {
    await init();
  final now = tz.TZDateTime.now(tz.local);
  final when = now.add(Duration(seconds: seconds));
  print('[NotificationService] scheduleInSeconds: now=$now when=$when (+$seconds s)');

    if (Platform.isAndroid && useAlarmManager) {
      await _savePayload(id: id, title: title, body: body);
      final amOk = await _scheduleWithAlarmManagerAt(
        id: id,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(when.millisecondsSinceEpoch),
      );
      if (amOk) return;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );
    final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Try exact first, then alarmClock, then inexact
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('[NotificationService] scheduled (seconds) with exactAllowWhileIdle');
      return;
    } catch (e) {
      final msg = e.toString();
      print('[NotificationService] exactAllowWhileIdle failed: $msg');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
        print('[NotificationService] scheduled (seconds) with alarmClock');
        return;
      } catch (e2) {
        final msg2 = e2.toString();
        print('[NotificationService] alarmClock failed: $msg2');
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        print('[NotificationService] scheduled (seconds) with inexactAllowWhileIdle');
      }
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    await init();
  final tz.TZDateTime when = tz.TZDateTime.from(scheduledAt, tz.local);
  print('[NotificationService] scheduleNotification: at=$when (from ${scheduledAt.toIso8601String()})');

    if (Platform.isAndroid && useAlarmManager) {
      await _savePayload(id: id, title: title, body: body);
      final amOk = await _scheduleWithAlarmManagerAt(
        id: id,
        scheduledAt: scheduledAt,
      );
      if (amOk) return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('[NotificationService] scheduled (one-off) with exactAllowWhileIdle');
      return;
    } catch (e) {
      final msg = e.toString();
      print('[NotificationService] exactAllowWhileIdle (one-off) failed: $msg');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
        print('[NotificationService] scheduled (one-off) with alarmClock');
        return;
      } catch (e2) {
        final msg2 = e2.toString();
        print('[NotificationService] alarmClock (one-off) failed: $msg2');
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        print('[NotificationService] scheduled (one-off) with inexactAllowWhileIdle');
      }
    }
  }

  // Schedule a daily notification at a specific local time.
  static Future<void> scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    print('[NotificationService] scheduleDaily: now=$now firstRun=$scheduled (h=$hour m=$minute)');

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('[NotificationService] scheduled (daily) with exactAllowWhileIdle');
      // Save daily meta and payload for AlarmManager rescheduling fallback
      if (Platform.isAndroid) {
        await _saveDailyMeta(id: id, hour: hour, minute: minute, title: title, body: body);
      }
      return;
    } catch (e) {
      final msg = e.toString();
      print('[NotificationService] exactAllowWhileIdle (daily) failed: $msg');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
        print('[NotificationService] scheduled (daily) with alarmClock');
        if (Platform.isAndroid) {
          await _saveDailyMeta(id: id, hour: hour, minute: minute, title: title, body: body);
        }
        return;
      } catch (e2) {
        final msg2 = e2.toString();
        print('[NotificationService] alarmClock (daily) failed: $msg2');
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        print('[NotificationService] scheduled (daily) with inexactAllowWhileIdle');
        if (Platform.isAndroid) {
          await _saveDailyMeta(id: id, hour: hour, minute: minute, title: title, body: body);
        }
      }
    }
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();

  // Diagnostics: list pending notifications
  static Future<List<PendingNotificationRequest>> pending() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  // Android 12+: Request exact alarms special access (opens OS settings)
  static Future<bool> requestExactAlarmsPermission() async {
    await init();
    try {
      final dynamic androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) return false;
      final res = await androidImpl.requestExactAlarmsPermission();
      print('[NotificationService] requestExactAlarmsPermission result=$res');
      if (res is bool) return res;
    } catch (e) {
      print('[NotificationService] requestExactAlarmsPermission error: $e');
    }
    return false;
  }

  // Show an immediate notification to verify basic functionality
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
    );
    final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details);
  }
}

// Top-level background entrypoint for Android AlarmManager
@pragma('vm:entry-point')
void notificationAlarmCallback(int id) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init();
    final tuple = await NotificationService._loadPayload(id);
    final title = tuple?.$1 ?? 'Reminder';
    final body = tuple?.$2 ?? "It's time for your reminder";
    await NotificationService.showNow(id: id, title: title, body: body);
    await NotificationService._clearPayload(id);
    // If this id corresponds to a daily reminder, schedule for next day
    final tm = await NotificationService._loadDailyTime(id);
    if (tm != null && Platform.isAndroid && NotificationService.useAlarmManager) {
      final now = DateTime.now();
      var next = DateTime(now.year, now.month, now.day, tm.$1, tm.$2).add(const Duration(days: 1));
      final ok = await AndroidAlarmManager.oneShotAt(
        next,
        id,
        notificationAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: false,
      );
      // ignore: avoid_print
      print('[NotificationService] Rescheduled daily via AlarmManager ok=$ok for $next (id=$id)');
    }
  } catch (e) {
    // ignore: avoid_print
    print('[NotificationService] notificationAlarmCallback error: $e');
  }
}
