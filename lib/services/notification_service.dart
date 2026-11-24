import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Aşama bittiğinde uygulama arka plandaysa bildirim gösterir.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 1001;

  bool get _supported => !kIsWeb;

  /// Zamanlanmış bildirimi destekleyen platformlar. Windows ve Linux'ta uygulama
  /// arka planda çalışmaya devam ettiği için bildirim süre dolunca anında gösterilir.
  bool get canSchedule =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (!_supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
          linux: LinuxInitializationSettings(defaultActionName: 'Aç'),
          windows: WindowsInitializationSettings(
            appName: 'Odaklanma Zamanı',
            appUserModelId: 'com.odaklanmazamani.OdaklanmaZamani',
            guid: '6f1c2b0e-8a43-4c1e-9b5d-2f7a1d3e4c90',
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Bildirimler başlatılamadı: $e');
    }
  }

  /// İlk zamanlayıcı başlatılırken bildirim izni ister.
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        sound: true,
      );
      await _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        sound: true,
      );
    } catch (_) {}
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'phase_end_v1',
      'Aşama bitişi',
      channelDescription: 'Odak veya mola süresi dolduğunda haber verir.',
      importance: Importance.high,
      priority: Priority.high,
      // "Alarm" kategorisi, Rahatsız Etme modu açıkken de bildirimin gelmesini sağlar.
      category: AndroidNotificationCategory.alarm,
      sound: RawResourceAndroidNotificationSound('zil'),
    ),
    iOS: DarwinNotificationDetails(presentSound: true),
    macOS: DarwinNotificationDetails(presentSound: true),
  );

  Future<void> schedule(DateTime at, String title, String body) async {
    if (!_ready || !canSchedule) return;
    try {
      var mode = AndroidScheduleMode.inexactAllowWhileIdle;
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null && (await android.canScheduleExactNotifications() ?? false)) {
        mode = AndroidScheduleMode.exactAllowWhileIdle;
      }
      await _plugin.zonedSchedule(
        id: _id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: mode,
      );
    } catch (e) {
      debugPrint('Bildirim zamanlanamadı: $e');
    }
  }

  Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(id: _id, title: title, body: body, notificationDetails: _details);
    } catch (e) {
      debugPrint('Bildirim gösterilemedi: $e');
    }
  }

  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
