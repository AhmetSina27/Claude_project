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

  static const _dailyId = 2001;
  static const _countdownId = 3001;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Her gün [minutes] (gece yarısından itibaren dakika) saatinde çalışma hatırlatması.
  /// [skipToday] true ise ilk hatırlatma yarın gelir (bugün zaten çalışıldıysa).
  Future<void> scheduleDailyReminder(int minutes, {required bool skipToday}) async {
    if (!_ready || !canSchedule) return;
    try {
      await _plugin.cancel(id: _dailyId);
      final now = tz.TZDateTime.now(tz.local);
      var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
      if (skipToday || !at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: 'Odaklanma zamanı 🔥',
        body: 'Bugünkü odak oturumunu henüz yapmadın. Serini korumak için 25 dakika yeter.',
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_v1',
            'Günlük hatırlatma',
            channelDescription: 'Her gün seçtiğin saatte çalışmayı hatırlatır.',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Hatırlatma zamanlanamadı: $e');
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _dailyId);
    } catch (_) {}
  }

  /// Android: uygulama arka plandayken bildirim çubuğunda canlı sayaç.
  /// [countDown] true ise [anchor] bitiş anıdır; false ise (serbest odak) başlangıç anıdır.
  Future<void> showLiveTimer({required DateTime anchor, required bool countDown, required String title}) async {
    if (!_ready || !_isAndroid) return;
    try {
      await _plugin.show(
        id: _countdownId,
        title: title,
        body: countDown ? 'Kalan süre' : 'Geçen süre',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'live_timer_v1',
            'Canlı sayaç',
            channelDescription: 'Uygulama arka plandayken kalan süreyi gösterir.',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            playSound: false,
            enableVibration: false,
            showWhen: true,
            when: anchor.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: countDown,
            category: AndroidNotificationCategory.stopwatch,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Canlı sayaç gösterilemedi: $e');
    }
  }

  Future<void> hideLiveTimer() async {
    if (!_ready || !_isAndroid) return;
    try {
      await _plugin.cancel(id: _countdownId);
    } catch (_) {}
  }

  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
