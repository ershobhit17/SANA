import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/reminder_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open DayFlow');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create high-importance Alarm channel on Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
          'dayflow_alarm_channel_v1',
          'DayFlow Loud Alarms & Reminders',
          description: 'High-priority sound alarms for habits and reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        await androidImpl?.createNotificationChannel(alarmChannel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification service init notice: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidImplementation?.requestNotificationsPermission();
        try {
          await androidImplementation?.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  Future<void> scheduleReminderNotification(ReminderItem reminder) async {
    if (!_isInitialized || !reminder.isEnabled) return;

    try {
      final scheduledTzTime = tz.TZDateTime.from(
        reminder.dateTime,
        tz.local,
      );

      // If scheduled time is in the past for a one-time reminder, skip
      if (reminder.repeat == ReminderRepeat.none &&
          scheduledTzTime.isBefore(tz.TZDateTime.now(tz.local))) {
        return;
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'dayflow_alarm_channel_v1',
        'DayFlow Loud Alarms & Reminders',
        channelDescription:
            'Notifications and sound alarms for scheduled daily tasks, habits, and reminders.',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList([4]), // Repeat alarm until dismissed
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      if (reminder.repeat == ReminderRepeat.none) {
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.title,
          body: reminder.description ?? 'Scheduled Reminder in DayFlow',
          scheduledDate: scheduledTzTime,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } else if (reminder.repeat == ReminderRepeat.daily) {
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.title,
          body: reminder.description ?? 'Daily Reminder in DayFlow',
          scheduledDate: _nextInstanceOfTime(
              reminder.dateTime.hour, reminder.dateTime.minute),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else if (reminder.repeat == ReminderRepeat.weekly) {
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.title,
          body: reminder.description ?? 'Weekly Reminder in DayFlow',
          scheduledDate: _nextInstanceOfWeekdayTime(
            reminder.dateTime.weekday,
            reminder.dateTime.hour,
            reminder.dateTime.minute,
          ),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelReminderNotification(int notificationId) async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'dayflow_general_channel',
        'DayFlow Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details =
          NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }
}
