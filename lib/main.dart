import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/audio_service.dart';
import 'services/focus_mode_service.dart';
import 'services/notification_service.dart';
import 'services/storage.dart';
import 'state/pomodoro_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.open();
  final audio = AudioService();
  final notifications = NotificationService();
  await Future.wait([audio.init(), notifications.init()]);
  final controller = PomodoroController(
    storage: storage,
    audio: audio,
    notifications: notifications,
    focusMode: FocusModeService(),
  );
  await controller.load();
  runApp(OdaklanmaApp(controller: controller));
}
