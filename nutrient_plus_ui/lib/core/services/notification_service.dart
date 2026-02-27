import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _prefKey = 'water_reminders_enabled';
  static const String _channelId = 'water_reminders';
  static const String _channelName = 'Water Reminders';
  static const String _channelDesc = 'Hourly reminders to drink water throughout the day';
  static const int _baseNotifId = 100;

  static const List<String> _messages = [
    'Time to hydrate! Drink a glass of water 💧',
    'Stay hydrated! Your body needs water 💧',
    'Water break! Keep your energy up 💧',
    'Don\'t forget to drink water! 💧',
    'Hydration check! How much have you had today? 💧',
    'Drink up! Staying hydrated helps digestion 💧',
    'Quick water break — your body will thank you 💧',
  ];

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Re-schedule if reminders were previously enabled
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) ?? false) {
      await _scheduleWaterReminders();
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> enableWaterReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    await _scheduleWaterReminders();
  }

  Future<void> disableWaterReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
    await _cancelWaterReminders();
  }

  Future<void> _scheduleWaterReminders() async {
    await _cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);

    for (int hour = 8; hour <= 20; hour += 2) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final message = _messages[(hour - 8) % _messages.length];

      await _plugin.zonedSchedule(
        _baseNotifId + (hour - 8),
        'Drink Water',
        message,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _cancelWaterReminders() async {
    for (int i = _baseNotifId; i < _baseNotifId + 7; i++) {
      await _plugin.cancel(i);
    }
  }
}
