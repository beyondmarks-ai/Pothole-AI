import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showRepairCompleted(RoadIncident incident) async {
    await initialize();
    const android = AndroidNotificationDetails(
      'roadcare_repair_updates',
      'Road repair updates',
      channelDescription: 'Updates when reported road repairs are completed',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
    );
    await _plugin.show(
      id: incident.id.hashCode & 0x7fffffff,
      title: 'Road repair completed',
      body:
          '${incident.roadName}, ${incident.area} has been repaired and verified.',
      notificationDetails: const NotificationDetails(android: android),
      payload: incident.id,
    );
  }
}
