import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      if (kDebugMode) {
        print('Error setting local timezone: $e');
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification click
      },
    );

    // Request permissions for Android 13+
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskNotifications({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return;
    try {
      final timesBefore = [
        const Duration(days: 1),
        const Duration(hours: 1),
        const Duration(minutes: 15),
        Duration.zero,
      ];
      
      for (int i = 0; i < timesBefore.length; i++) {
        DateTime notifyTime = scheduledDate.subtract(timesBefore[i]);
        
        DateTime now = DateTime.now();
        DateTime nowTruncated = DateTime(now.year, now.month, now.day, now.hour, now.minute);
        
        // Sadece dakikayı referans al (O anki dakika ile hedef dakika aynıysa anında çal)
        if (notifyTime.isAtSameMomentAs(nowTruncated)) {
          notifyTime = now.add(const Duration(seconds: 2));
        }

        final contextualBody = timesBefore[i] == const Duration(days: 1)
            ? 'Yarınki planınızı hatırlatmak istedik.'
            : timesBefore[i] == const Duration(hours: 1)
                ? 'Planınıza sadece 1 saat kaldı.'
                : timesBefore[i] == const Duration(minutes: 15)
                    ? 'Hazırlanın, planınızın başlamasına 15 dakika kaldı!'
                    : 'Plan zamanı geldi, başlıyoruz!';

        if (notifyTime.isAfter(DateTime.now())) {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id * 10 + i,
            timesBefore[i] == const Duration(days: 1) ? 'Yarın: $title' : 
            timesBefore[i] == const Duration(hours: 1) ? '1 Saat Sonra: $title' : 
            timesBefore[i] == const Duration(minutes: 15) ? '15 Dakika Sonra: $title' : 
            'Şimdi: $title',
            body.isNotEmpty ? body : contextualBody,
            tz.TZDateTime.from(notifyTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'todo_channel_id',
                'To-Do Notifications',
                channelDescription: 'Notifications for upcoming to-do plan',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  Future<void> cancelTaskNotifications(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id * 10);
    await flutterLocalNotificationsPlugin.cancel(id * 10 + 1);
    await flutterLocalNotificationsPlugin.cancel(id * 10 + 2);
    await flutterLocalNotificationsPlugin.cancel(id * 10 + 3);
  }
}
