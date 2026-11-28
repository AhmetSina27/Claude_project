import 'package:odaklanma_zamani/data/ambient.dart';
import 'package:odaklanma_zamani/models/phase.dart';
import 'package:odaklanma_zamani/models/settings.dart';
import 'package:odaklanma_zamani/services/audio_service.dart';
import 'package:odaklanma_zamani/services/background_store.dart';

import 'dart:typed_data';

import 'package:odaklanma_zamani/services/focus_mode_service.dart';
import 'package:odaklanma_zamani/services/notification_service.dart';
import 'package:odaklanma_zamani/services/storage.dart';
import 'package:odaklanma_zamani/state/pomodoro_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudio extends AudioService {
  final events = <String>[];
  @override
  Future<void> init() async {}
  @override
  Future<void> playAmbient(AmbientSound sound, double volume) async => events.add('ambient:${sound.name}');
  @override
  Future<void> pauseAmbient() async => events.add('pause');
  @override
  Future<void> bell(double volume, [BellSound sound = BellSound.okul]) async => events.add('bell:${sound.name}');
  @override
  Future<void> chime(double volume) async => events.add('chime');
  @override
  Future<void> applause(double volume) async => events.add('applause');
}

class FakeNotifications extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> schedule(DateTime at, String title, String body) async {}
  @override
  Future<void> showNow(String title, String body) async {}
  @override
  Future<void> cancel() async {}
  final reminders = <(int, bool)>[];
  @override
  Future<void> scheduleDailyReminder(int minutes, {required bool skipToday}) async =>
      reminders.add((minutes, skipToday));
  @override
  Future<void> cancelDailyReminder() async {}
  @override
  Future<void> showLiveTimer({required DateTime anchor, required bool countDown, required String title}) async {}
  @override
  Future<void> hideLiveTimer() async {}
}

class FakeBackgrounds extends BackgroundStore {
  FakeBackgrounds(super.storage);
  @override
  Future<Uint8List?> load() async => null;
  @override
  Future<String?> loadVideoPath() async => null;
}

class FakeFocusMode extends FocusModeService {
  bool on = false;
  @override
  bool get isSupported => true;
  @override
  Future<bool> enable() async => on = true;
  @override
  Future<void> disable() async => on = false;
}

void main() {
  late DateTime now;
  late FakeAudio audio;
  late FakeFocusMode dnd;
  late FakeNotifications notes;

  Future<PomodoroController> make({AppSettings settings = const AppSettings(keepScreenOn: false)}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.open();
    await storage.saveSettings(settings);
    audio = FakeAudio();
    dnd = FakeFocusMode();
    final c = PomodoroController(
      storage: storage,
      audio: audio,
      notifications: notes = FakeNotifications(),
      focusMode: dnd,
      backgrounds: FakeBackgrounds(storage),
      clock: () => now,
    );
    await c.load();
    return c;
  }

  Future<void> advance(WidgetTester tester, Duration d) async {
    now = now.add(d);
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() => now = DateTime(2026, 11, 24, 10));

  testWidgets('odak bitince sayım artar, zil çalar, tebrik hazırlanır ve kısa molaya geçilir', (tester) async {
    final c = await make();
    expect(c.tasks, isEmpty); // ilk açılışta örnek görev yok
    c.addTask('Fizik: elektrik konusu');
    expect(c.activeTask!.title, 'Fizik: elektrik konusu');
    expect(c.phase, Phase.focus);
    expect(c.remaining, const Duration(minutes: 25));

    await c.start();
    expect(audio.events, contains('ambient:yagmur'));
    await advance(tester, const Duration(minutes: 25));

    expect(c.phase, Phase.shortBreak);
    expect(c.isRunning, isFalse);
    expect(c.today.focusSessions, 1);
    expect(c.today.focusSeconds, 25 * 60);
    expect(audio.events, contains('bell:okul'));
    expect(c.pendingCelebration, isNotNull);
    expect(c.pendingCelebration!.today.focusSessions, 1);
    expect(c.activeTask!.pomodoros, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(audio.events, contains('applause'));
  });

  testWidgets('mola bitince mola sayısı artar ve çan çalar', (tester) async {
    final c = await make();
    c.selectPhase(Phase.shortBreak);
    await c.start();
    await advance(tester, const Duration(minutes: 5));
    expect(c.phase, Phase.focus);
    expect(c.today.breaks, 1);
    expect(c.today.breakSeconds, 300);
    expect(audio.events, contains('bell:okul')); // mola bitince de zil çalar
  });

  testWidgets('4 pomodorodan sonra uzun molaya geçilir', (tester) async {
    final c = await make();
    for (var i = 0; i < 4; i++) {
      expect(c.phase, Phase.focus, reason: 'tur $i');
      await c.start();
      await advance(tester, const Duration(minutes: 25));
      if (i < 3) {
        expect(c.phase, Phase.shortBreak);
        c.skip();
      }
    }
    expect(c.phase, Phase.longBreak);
    expect(c.today.focusSessions, 4);
    c.skip();
    expect(c.completedInCycle, 0);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('duraklatınca süre durur, devam edince kaldığı yerden sürer', (tester) async {
    final c = await make();
    await c.start();
    await advance(tester, const Duration(minutes: 10));
    c.pause();
    now = now.add(const Duration(minutes: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(c.remaining, const Duration(minutes: 15));
    expect(c.phase, Phase.focus);
  });

  testWidgets('odakta Rahatsız Etme açılır, durunca kapanır', (tester) async {
    final c = await make(settings: const AppSettings(keepScreenOn: false, doNotDisturb: true));
    await c.start();
    await tester.pump();
    expect(dnd.on, isTrue);
    c.pause();
    expect(dnd.on, isFalse);
  });

  testWidgets('atlanan odakta en az 1 dakikalık süre etüde eklenir ama pomodoro sayılmaz', (tester) async {
    final c = await make();
    await c.start();
    await advance(tester, const Duration(minutes: 7));
    c.skip();
    expect(c.today.focusSeconds, 7 * 60);
    expect(c.today.focusSessions, 0);
    expect(c.phase, Phase.shortBreak);
  });

  testWidgets('ayarlar kaydedilip yeniden yüklenir', (tester) async {
    final c = await make();
    c.updateSettings(c.settings.copyWith(focusMinutes: 50, accent: AccentTheme.okyanus, focusSound: AmbientSound.ates));
    expect(c.remaining, const Duration(minutes: 50));
    final storage2 = await Storage.open();
    final again = PomodoroController(
      storage: storage2,
      audio: audio,
      notifications: FakeNotifications(),
      focusMode: dnd,
      backgrounds: FakeBackgrounds(storage2),
      clock: () => now,
    );
    await again.load();
    expect(again.settings.focusMinutes, 50);
    expect(again.settings.accent, AccentTheme.okyanus);
    expect(again.settings.focusSound, AmbientSound.ates);
  });

  testWidgets('hazır süre seçilince sayaç yeni süreye ayarlanır', (tester) async {
    final c = await make();
    c.setFocusDuration(90);
    expect(c.total, const Duration(minutes: 90));
    expect(c.display, const Duration(minutes: 90));
    await c.start();
    await advance(tester, const Duration(minutes: 90));
    expect(c.today.focusSeconds, 90 * 60);
    expect(c.pendingCelebration!.sessionMinutes, 90);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('serbest odak ileri sayar, duraklatmayı korur ve bitirince kaydeder', (tester) async {
    final c = await make();
    c.setFocusDuration(null);
    expect(c.isFree, isTrue);
    expect(c.display, Duration.zero);
    await c.start();
    await advance(tester, const Duration(minutes: 40));
    expect(c.display, const Duration(minutes: 40));
    c.pause();
    now = now.add(const Duration(minutes: 30)); // duraklatılmışken geçen süre sayılmaz
    await tester.pump(const Duration(seconds: 1));
    expect(c.display, const Duration(minutes: 40));
    await c.start();
    await advance(tester, const Duration(minutes: 35));
    c.skip(); // Bitir
    expect(c.phase, Phase.shortBreak);
    expect(c.today.focusSessions, 1);
    expect(c.today.focusSeconds, 75 * 60);
    expect(c.pendingCelebration!.sessionMinutes, 75);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('serbest odakta 1 dakikadan kısa çalışma kaydedilmez', (tester) async {
    final c = await make();
    c.setFocusDuration(null);
    await c.start();
    await advance(tester, const Duration(seconds: 30));
    c.skip();
    expect(c.phase, Phase.focus);
    expect(c.today.focusSessions, 0);
    expect(c.display, Duration.zero);
  });

  testWidgets('seçilen guguk zili odak sonunda çalar', (tester) async {
    final c = await make(settings: const AppSettings(keepScreenOn: false, bellSound: BellSound.guguk));
    await c.start();
    await advance(tester, const Duration(minutes: 25));
    expect(audio.events, contains('bell:guguk'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('günlük hatırlatma: odak bitince bugünkü hatırlatma atlanır', (tester) async {
    final c = await make(
      settings: const AppSettings(keepScreenOn: false, reminderEnabled: true, reminderMinutes: 20 * 60),
    );
    expect(notes.reminders.last, (20 * 60, false)); // bugün henüz çalışılmadı
    await c.start();
    await advance(tester, const Duration(minutes: 25));
    expect(notes.reminders.last, (20 * 60, true)); // bugün çalışıldı, yarına kaydı
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('kısa mola süresi ayarlanınca bekleyen mola yeni süreye geçer', (tester) async {
    final c = await make();
    c.selectPhase(Phase.shortBreak);
    c.setBreakDuration(Phase.shortBreak, 12);
    expect(c.settings.shortBreakMinutes, 12);
    expect(c.display, const Duration(minutes: 12));
    c.setFocusDuration(37);
    expect(c.settings.focusMinutes, 37);
    expect(c.display, const Duration(minutes: 12)); // mola sürerken odak süresi sayacı değiştirmez
  });

  testWidgets('hedef: ekle, düzenle, sil ve geri al', (tester) async {
    final c = await make();
    final a = c.addTask('Fizik tekrarı', target: 3)!;
    final b = c.addTask('Tarih okuma')!;
    expect(c.activeTask!.id, a.id);
    expect(a.target, 3);
    c.updateTask(b, title: 'Tarih: Kurtuluş Savaşı', target: 2);
    expect(b.title, 'Tarih: Kurtuluş Savaşı');
    final removed = c.deleteTask(a)!;
    expect(c.activeTask!.id, b.id); // silinen etkin hedefin yerine sıradaki geçer
    c.restoreTask(removed);
    expect(c.tasks.first.id, a.id);
    expect(c.activeTask!.id, a.id);
  });
}
