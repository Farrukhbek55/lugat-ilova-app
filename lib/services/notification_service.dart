import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dictionary_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId   = 'lughat_daily_word';
  static const _channelName = "Kunlik So'z";
  static const _channelDesc = "Har kuni yangi o'zbek so'zi";

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// SQLite dan random so'z olib, har kuni 9:00 da yuboradi
  Future<void> scheduleDailyWordNotification() async {
    await init();

    // Random so'z olish — getById orqali
    final dict = DictionaryService();
    await dict.load();
    final randomId = Random().nextInt(dict.totalWords) + 1;
    final word = await dict.getById(randomId);

    final title = word != null
        ? '📖 ${word.word}${word.pronunciation.isNotEmpty ? "  ${word.pronunciation}" : ""}'
        : '📖 LugHat — Bugungi so\'z';
    final body = word != null && word.mainDefinition.isNotEmpty
        ? '🔤 ${word.mainDefinition}'
        : 'Lug\'hatni oching va yangi so\'z o\'rganing!';

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    final now  = tz.TZDateTime.now(tz.local);
    var sched  = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (sched.isBefore(now)) sched = sched.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      0, title, body, sched,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Test xabari — darhol yuboradi
  Future<void> showTestNotification() async {
    await init();
    await requestPermission();

    final dict = DictionaryService();
    await dict.load();
    final word = await dict.getById(244); // 'olma'

    final title = word != null
        ? '📖 ${word.word}${word.pronunciation.isNotEmpty ? "  ${word.pronunciation}" : ""}'
        : '📖 LugHat';
    final body = word != null && word.mainDefinition.isNotEmpty
        ? '🔤 ${word.mainDefinition}'
        : 'Test xabari';

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      1, title, body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
