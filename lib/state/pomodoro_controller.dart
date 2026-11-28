import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/ambient.dart';
import '../data/quotes.dart';
import '../models/day_stats.dart';
import '../models/phase.dart';
import '../models/settings.dart';
import '../models/task.dart';
import '../scenes/scenes.dart';
import '../services/audio_service.dart';
import '../services/background_store.dart';
import '../services/focus_mode_service.dart';
import '../services/notification_service.dart';
import '../services/storage.dart';

/// Odak bitince gösterilen tebrik ekranının verisi.
class Celebration {
  Celebration({
    required this.today,
    required this.quote,
    required this.sessionMinutes,
    required this.goal,
    this.streak = 1,
  });
  final DayStats today;
  final Quote quote;
  final int sessionMinutes;
  final int goal;

  /// Kaç gündür üst üste çalışılıyor (bugün dahil).
  final int streak;
}

/// Zamanlayıcının, görevlerin, ayarların ve istatistiklerin tek kaynağı.
class PomodoroController extends ChangeNotifier {
  PomodoroController({
    required Storage storage,
    required AudioService audio,
    required NotificationService notifications,
    required FocusModeService focusMode,
    BackgroundStore? backgrounds,
    DateTime Function()? clock,
  }) : _storage = storage,
       _backgrounds = backgrounds ?? BackgroundStore(storage),
       _audio = audio,
       _notifications = notifications,
       _focusMode = focusMode,
       _now = clock ?? DateTime.now;

  final Storage _storage;
  final AudioService _audio;
  final NotificationService _notifications;
  final FocusModeService _focusMode;
  final BackgroundStore _backgrounds;
  final DateTime Function() _now;

  Uint8List? _customBackground;

  /// Kullanıcının cihazından seçtiği arka plan görseli (yoksa null).
  Uint8List? get customBackground => _customBackground;

  String? _customVideoPath;

  /// Kullanıcının cihazından seçtiği arka plan videosu (yoksa null).
  String? get customVideoPath => _customVideoPath;
  bool get hasCustomBackground => _customBackground != null || _customVideoPath != null;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  List<FocusTask> _tasks = [];
  List<FocusTask> get tasks => List.unmodifiable(_tasks);
  String? _activeTaskId;
  FocusTask? get activeTask {
    for (final t in _tasks) {
      if (t.id == _activeTaskId && !t.done) return t;
    }
    return null;
  }

  Map<String, DayStats> _stats = {};

  Phase _phase = Phase.focus;
  Phase get phase => _phase;

  int _completedInCycle = 0;
  int get completedInCycle => _completedInCycle;

  bool _running = false;
  bool get isRunning => _running;

  DateTime? _endAt;
  Duration _remaining = Duration.zero;
  Duration get remaining => _remaining;
  Duration get total => Duration(minutes: _minutesFor(_phase));

  /// Serbest odak (ileri sayan kronometre) şu an etkin mi?
  bool get isFree => _phase == Phase.focus && _settings.freeFocus;

  // Serbest odakta: duraklatmalar arasında biriken süre ve son başlatma anı.
  Duration _freeBase = Duration.zero;
  DateTime? _freeRunStart;
  Duration _freeElapsed() => _freeBase + (_freeRunStart == null ? Duration.zero : _now().difference(_freeRunStart!));

  /// Sayaçta gösterilecek süre: geri sayımda kalan, serbest odakta geçen süre.
  Duration get display => isFree ? _freeElapsed() : _remaining;

  /// 1.0 = dolu, 0.0 = bitti. Serbest odakta ilerleme çubuğu boştur.
  double get progress => isFree || total.inMilliseconds == 0 ? 1 : _remaining.inMilliseconds / total.inMilliseconds;
  bool get isPristine => isFree ? !_running && _freeBase == Duration.zero : !_running && _remaining == total;

  Celebration? _pendingCelebration;
  Celebration? get pendingCelebration => _pendingCelebration;

  bool _inBackground = false;
  bool _askedNotificationPermission = false;
  bool _dndActive = false;
  Timer? _ticker;
  int _lastShownSecond = -1;

  // ---------- Başlatma ----------

  Future<void> load() async {
    _settings = _storage.loadSettings();
    _stats = _storage.loadStats();
    // İlk açılışta görev listesi boştur; kullanıcı kendi görevlerini ekler.
    _tasks = _storage.loadTasks() ?? [];
    _activeTaskId = _storage.loadActiveTask();
    _remaining = total;
    _restoreTimer();
    _customVideoPath = await _backgrounds.loadVideoPath();
    _customBackground = _customVideoPath == null ? await _backgrounds.load() : null;
    if (_settings.backgroundId == 'custom' && !hasCustomBackground) {
      _settings = _settings.copyWith(backgroundId: 'none');
    }
    _onboarded = _storage.loadString('onboarded') == '1';
    // Sürüm 2: sahne seçildiğinde ses de sahneye uyar. Daha önce sahne seçmiş kullanıcılar için bir kez eşle.
    if (_storage.loadString('sahneSesEsli') != '1') {
      final id = _settings.backgroundId;
      if (id.startsWith('scene:')) {
        final scene = Scene.fromName(id.substring(6));
        if (scene != null) _settings = _settings.copyWith(focusSound: scene.sound);
        _storage.saveSettings(_settings);
      }
      _storage.saveString('sahneSesEsli', '1');
    }
    _syncReminder();
    notifyListeners();
  }

  // ---------- İlk açılış rehberi ----------

  bool _onboarded = true;

  /// İlk açılış rehberi görüldü mü?
  bool get onboarded => _onboarded;

  void completeOnboarding() {
    _onboarded = true;
    _storage.saveString('onboarded', '1');
    unawaited(_notifications.requestPermission());
    _askedNotificationPermission = true;
    notifyListeners();
  }

  // ---------- Günlük hatırlatma ----------

  void _syncReminder() {
    if (_settings.reminderEnabled) {
      _notifications.scheduleDailyReminder(_settings.reminderMinutes, skipToday: today.focusSessions > 0);
    } else {
      _notifications.cancelDailyReminder();
    }
  }

  /// Cihazdan arka plan görseli seçtirir. Seçilirse hemen uygulanır.
  Future<bool> pickCustomBackground() async {
    final bytes = await _backgrounds.pick();
    if (bytes == null) return false;
    _customBackground = bytes;
    _customVideoPath = null;
    updateSettings(_settings.copyWith(backgroundId: 'custom'));
    return true;
  }

  /// Cihazdan arka plan videosu seçtirir (mobil ve Mac).
  Future<bool> pickCustomVideo() async {
    final path = await _backgrounds.pickVideo();
    if (path == null) return false;
    _customVideoPath = path;
    _customBackground = null;
    updateSettings(_settings.copyWith(backgroundId: 'custom'));
    return true;
  }

  Future<void> removeCustomBackground() async {
    await _backgrounds.remove();
    _customBackground = null;
    _customVideoPath = null;
    if (_settings.backgroundId == 'custom') {
      updateSettings(_settings.copyWith(backgroundId: 'none'));
    } else {
      notifyListeners();
    }
  }

  void _restoreTimer() {
    final t = _storage.loadTimer();
    if (t == null) return;
    _phase = Phase.values.firstWhere((p) => p.name == t['phase'], orElse: () => Phase.focus);
    _completedInCycle = (t['cycle'] as int? ?? 0).clamp(0, _settings.longBreakInterval);
    final endMs = t['endAt'] as int?;
    final remMs = t['remaining'] as int?;
    if (isFree) {
      _freeBase = Duration(milliseconds: t['freeBase'] as int? ?? 0);
      final rs = t['freeRunStart'] as int?;
      if (t['running'] == true && rs != null) {
        _freeRunStart = DateTime.fromMillisecondsSinceEpoch(rs);
        _running = true;
        _startTicker();
        _applyRunningSideEffects();
      }
      return;
    }
    if (t['running'] == true && endMs != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(endMs);
      if (end.isAfter(_now())) {
        _endAt = end;
        _remaining = end.difference(_now());
        _running = true;
        _startTicker();
        _applyRunningSideEffects();
      } else {
        // Uygulama kapalıyken süre dolmuş: sayıma ekle, sessizce sonraki aşamaya geç.
        _remaining = Duration.zero;
        _complete(silent: true);
      }
    } else {
      _remaining = remMs != null ? Duration(milliseconds: remMs) : total;
      if (_remaining > total) _remaining = total;
    }
  }

  void _persistTimer() {
    _storage.saveTimer({
      'phase': _phase.name,
      'cycle': _completedInCycle,
      'running': _running,
      'endAt': _endAt?.millisecondsSinceEpoch,
      'remaining': _remaining.inMilliseconds,
      'freeBase': _freeBase.inMilliseconds,
      'freeRunStart': _freeRunStart?.millisecondsSinceEpoch,
    });
  }

  int _minutesFor(Phase p) => switch (p) {
    Phase.focus => _settings.focusMinutes,
    Phase.shortBreak => _settings.shortBreakMinutes,
    Phase.longBreak => _settings.longBreakMinutes,
  };

  // ---------- İstatistik ----------

  DayStats statsFor(DateTime day) => _stats[DayStats.keyFor(day)] ?? DayStats();
  DayStats get today => statsFor(_now());

  DayStats _todayMutable() => _stats.putIfAbsent(DayStats.keyFor(_now()), DayStats.new);

  /// Son [days] günün istatistikleri, eskiden yeniye.
  List<(DateTime, DayStats)> lastDays(int days) {
    final n = _now();
    final base = DateTime(n.year, n.month, n.day);
    return [
      for (var i = days - 1; i >= 0; i--)
        (base.subtract(Duration(days: i)), statsFor(base.subtract(Duration(days: i)))),
    ];
  }

  int get streakDays {
    var streak = 0;
    final n = _now();
    var d = DateTime(n.year, n.month, n.day);
    if (statsFor(d).focusSessions == 0) d = d.subtract(const Duration(days: 1));
    while (statsFor(d).focusSessions > 0) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _recordFocus(Duration elapsed, {required bool completed}) {
    if (elapsed.inSeconds < 60 && !completed) return;
    final s = _todayMutable();
    s.focusSeconds += elapsed.inSeconds;
    if (completed) {
      s.focusSessions++;
      if (_settings.reminderEnabled) {
        _notifications.scheduleDailyReminder(_settings.reminderMinutes, skipToday: true);
      }
      activeTask?.pomodoros++;
      _saveTasks();
    }
    _storage.saveStats(_stats);
  }

  void _recordBreak(Duration elapsed, {required bool completed}) {
    if (elapsed.inSeconds < 30 && !completed) return;
    final s = _todayMutable();
    s.breakSeconds += elapsed.inSeconds;
    s.breaks++;
    _storage.saveStats(_stats);
  }

  // ---------- Zamanlayıcı ----------

  void toggle() => _running ? pause() : start();

  Future<void> start() async {
    if (_running) return;
    _running = true;
    if (isFree) {
      _freeRunStart = _now();
    } else {
      if (_remaining <= Duration.zero) _remaining = total;
      _endAt = _now().add(_remaining);
    }
    _startTicker();
    _persistTimer();
    notifyListeners();
    _applyRunningSideEffects();
    if (!_askedNotificationPermission) {
      _askedNotificationPermission = true;
      unawaited(_notifications.requestPermission());
    }
  }

  void pause() {
    if (!_running) return;
    _syncRemaining();
    _foldFree();
    _running = false;
    _endAt = null;
    _ticker?.cancel();
    _persistTimer();
    _applyStoppedSideEffects();
    notifyListeners();
  }

  /// Bulunulan aşamayı baştan başlatır (geçen süre sayıma eklenir).
  void reset() {
    _syncRemaining();
    _foldFree();
    _recordElapsed(completed: false);
    _running = false;
    _endAt = null;
    _ticker?.cancel();
    _remaining = total;
    _freeBase = Duration.zero;
    _persistTimer();
    _applyStoppedSideEffects();
    notifyListeners();
  }

  /// Bulunulan aşamayı bitirmeden sonrakine geçer.
  /// Serbest odakta "Bitir" anlamına gelir: en az 1 dakika çalışıldıysa oturum tamamlanmış sayılır.
  void skip() {
    if (isFree) {
      _foldFree();
      if (_freeBase >= const Duration(minutes: 1)) {
        _complete();
      } else {
        reset();
      }
      return;
    }
    _syncRemaining();
    _recordElapsed(completed: false);
    _ticker?.cancel();
    final wasRunning = _running;
    _running = false;
    _endAt = null;
    _advance(fromCompletion: false);
    _applyStoppedSideEffects();
    if (wasRunning && _shouldAutoStart()) start();
    notifyListeners();
  }

  void selectPhase(Phase p) {
    if (p == _phase && isPristine) return;
    _syncRemaining();
    _foldFree();
    _recordElapsed(completed: false);
    _freeBase = Duration.zero;
    _ticker?.cancel();
    _running = false;
    _endAt = null;
    _phase = p;
    _remaining = total;
    _persistTimer();
    _applyStoppedSideEffects();
    notifyListeners();
  }

  void _recordElapsed({required bool completed}) {
    final elapsed = isFree ? _freeElapsed() : total - _remaining;
    if (elapsed <= Duration.zero) return;
    if (_phase == Phase.focus) {
      _recordFocus(elapsed, completed: completed);
    } else {
      _recordBreak(elapsed, completed: completed);
    }
  }

  void _syncRemaining() {
    if (_running && _endAt != null) {
      final r = _endAt!.difference(_now());
      _remaining = r.isNegative ? Duration.zero : r;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (isFree) {
      final sec = _freeElapsed().inSeconds;
      if (sec != _lastShownSecond) {
        _lastShownSecond = sec;
        notifyListeners();
      }
      return;
    }
    _syncRemaining();
    if (_remaining <= Duration.zero) {
      _complete();
      return;
    }
    final sec = _remaining.inSeconds;
    if (sec != _lastShownSecond) {
      _lastShownSecond = sec;
      notifyListeners();
    }
  }

  void _complete({bool silent = false}) {
    _ticker?.cancel();
    _foldFree();
    final sessionMinutes = isFree ? _freeBase.inMinutes : _settings.focusMinutes;
    _running = false;
    _endAt = null;
    _remaining = Duration.zero;
    final finished = _phase;
    _recordElapsed(completed: true);

    if (finished == Phase.focus && _settings.celebrationEnabled && !silent) {
      _pendingCelebration = Celebration(
        today: DayStats.fromJson(today.toJson()),
        quote: randomQuote(Random()),
        sessionMinutes: sessionMinutes,
        goal: _settings.dailyGoal,
        streak: streakDays,
      );
    }

    _advance(fromCompletion: true);
    _applyStoppedSideEffects();

    if (!silent) {
      final playSoundInApp = !_inBackground || !_notifications.canSchedule;
      if (playSoundInApp && _settings.bellEnabled) {
        // Odak bitince de mola bitince de seçilen zil çalar (okul zili ya da guguk).
        _audio.bell(_settings.bellVolume, _settings.bellSound);
      }
      if (_pendingCelebration != null && _settings.applauseEnabled && !_inBackground) {
        Future.delayed(const Duration(milliseconds: 2600), () => _audio.applause(_settings.bellVolume));
      }
      if (_inBackground && !_notifications.canSchedule) {
        final (title, body) = _notificationTextFor(finished);
        _notifications.showNow(title, body);
      }
    }

    if (!silent && _shouldAutoStart()) {
      start();
    } else {
      _persistTimer();
    }
    notifyListeners();
  }

  bool _shouldAutoStart() => _phase.isBreak ? _settings.autoStartBreaks : _settings.autoStartFocus;

  void _advance({required bool fromCompletion}) {
    if (_phase == Phase.focus) {
      if (fromCompletion) _completedInCycle++;
      final reachedLong = fromCompletion
          ? _completedInCycle >= _settings.longBreakInterval
          : _completedInCycle + 1 >= _settings.longBreakInterval;
      _phase = reachedLong ? Phase.longBreak : Phase.shortBreak;
    } else {
      if (_phase == Phase.longBreak) _completedInCycle = 0;
      _phase = Phase.focus;
    }
    _remaining = total;
    _freeBase = Duration.zero;
    _freeRunStart = null;
    _lastShownSecond = -1;
    _persistTimer();
  }

  /// Serbest odakta çalışan süreyi birikmiş süreye ekler (duraklatma/bitirme öncesi).
  void _foldFree() {
    if (_freeRunStart != null) {
      _freeBase += _now().difference(_freeRunStart!);
      _freeRunStart = null;
    }
  }

  /// Odak süresini değiştirir; [minutes] null ise serbest odak (ileri sayma) seçilir.
  /// Odak sürerken çağrılırsa geçen süre kaydedilir ve sayaç yeni süreyle baştan hazırlanır.
  void setFocusDuration(int? minutes) {
    if (_phase == Phase.focus) {
      _syncRemaining();
      _foldFree();
      _recordElapsed(completed: false);
      _ticker?.cancel();
      if (_running) _applyStoppedSideEffects();
      _running = false;
      _endAt = null;
      _freeBase = Duration.zero;
    }
    _settings = _settings.copyWith(
      freeFocus: minutes == null,
      focusMinutes: (minutes ?? _settings.focusMinutes).clamp(1, maxFocusMinutes),
    );
    _storage.saveSettings(_settings);
    if (_phase == Phase.focus) _remaining = total;
    _persistTimer();
    notifyListeners();
  }

  /// Kısa ya da uzun mola süresini değiştirir; o mola şu an bekliyorsa sayaç yeni süreye ayarlanır.
  void setBreakDuration(Phase p, int minutes) {
    if (!p.isBreak) return;
    final v = minutes.clamp(1, 90);
    _settings = p == Phase.shortBreak
        ? _settings.copyWith(shortBreakMinutes: v)
        : _settings.copyWith(longBreakMinutes: v);
    _storage.saveSettings(_settings);
    if (_phase == p && !_running) {
      _remaining = total;
      _persistTimer();
    }
    notifyListeners();
  }

  /// Odak süresi için üst sınır (5 saat).
  static const maxFocusMinutes = 300;

  (String, String) _notificationTextFor(Phase finished) => finished == Phase.focus
      ? ('Teneffüs zamanı! 🔔', 'Odak süren bitti. ${_phase.label} başlıyor, biraz dinlen.')
      : ('Mola bitti', 'Yeni bir odak oturumuna hazır mısın?');

  void clearCelebration() {
    _pendingCelebration = null;
    notifyListeners();
  }

  // ---------- Yan etkiler: ses, ekran, Rahatsız Etme ----------

  AmbientSound get _soundForPhase => _phase == Phase.focus ? _settings.focusSound : _settings.breakSound;

  void _applyRunningSideEffects() {
    _audio.playAmbient(_soundForPhase, _settings.ambientVolume);
    if (_settings.keepScreenOn) WakelockPlus.enable().catchError((_) {});
    if (_phase == Phase.focus && _settings.doNotDisturb) {
      _focusMode.enable().then((ok) => _dndActive = ok);
    } else if (_dndActive) {
      _focusMode.disable();
      _dndActive = false;
    }
    if (_inBackground) {
      _scheduleEndNotification();
      _showLiveTimer();
    }
  }

  /// Android: arka plandayken bildirim çubuğunda kalan (ya da geçen) süre.
  void _showLiveTimer() {
    if (!_running) return;
    if (isFree) {
      _notifications.showLiveTimer(anchor: _now().subtract(_freeElapsed()), countDown: false, title: 'Serbest odak');
    } else if (_endAt != null) {
      _notifications.showLiveTimer(anchor: _endAt!, countDown: true, title: _phase.label);
    }
  }

  void _applyStoppedSideEffects() {
    _audio.pauseAmbient();
    WakelockPlus.disable().catchError((_) {});
    if (_dndActive) {
      _focusMode.disable();
      _dndActive = false;
    }
    _notifications.cancel();
    _notifications.hideLiveTimer();
  }

  void _scheduleEndNotification() {
    if (!_running || _endAt == null) return;
    final (title, body) = _notificationTextFor(_phase);
    _notifications.schedule(_endAt!, title, body);
  }

  /// Uygulama arka plana geçti / öne geldi.
  void setInBackground(bool bg) {
    if (bg == _inBackground) return;
    _inBackground = bg;
    if (bg) {
      _scheduleEndNotification();
      _showLiveTimer();
    } else {
      _notifications.cancel();
      _notifications.hideLiveTimer();
      if (_running) _tick();
      notifyListeners();
    }
  }

  // ---------- Görevler ----------

  /// Yeni hedef ekler. Etkin bir hedef yoksa yeni hedef etkin olur.
  FocusTask? addTask(String title, {int target = 1}) {
    final t = title.trim();
    if (t.isEmpty) return null;
    final task = FocusTask(id: _now().microsecondsSinceEpoch.toString(), title: t, target: target.clamp(1, 20));
    _tasks.add(task);
    if (activeTask == null) _activeTaskId = task.id;
    _saveTasks();
    notifyListeners();
    return task;
  }

  void updateTask(FocusTask task, {String? title, int? target}) {
    if (title != null && title.trim().isNotEmpty) task.title = title.trim();
    if (target != null) task.target = target.clamp(1, 20);
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskDone(FocusTask task) {
    task.done = !task.done;
    if (task.done && task.id == _activeTaskId) {
      _activeTaskId = _tasks.where((t) => !t.done).map((t) => t.id).firstOrNull;
    }
    if (!task.done && activeTask == null) _activeTaskId = task.id;
    _saveTasks();
    notifyListeners();
  }

  void selectTask(FocusTask task) {
    if (task.done) return;
    _activeTaskId = task.id;
    _saveTasks();
    notifyListeners();
  }

  /// Hedefi siler; geri almak için silinen hedef ve konumu döner.
  (FocusTask, int, bool)? deleteTask(FocusTask task) {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return null;
    final wasActive = _activeTaskId == task.id;
    _tasks.removeAt(i);
    if (wasActive) _activeTaskId = _tasks.where((t) => !t.done).map((t) => t.id).firstOrNull;
    _saveTasks();
    notifyListeners();
    return (task, i, wasActive);
  }

  /// Silinen hedefi eski yerine geri koyar.
  void restoreTask((FocusTask, int, bool) removed) {
    final (task, i, wasActive) = removed;
    _tasks.insert(i.clamp(0, _tasks.length), task);
    if (wasActive) _activeTaskId = task.id;
    _saveTasks();
    notifyListeners();
  }

  void _saveTasks() => _storage.saveTasks(_tasks, _activeTaskId);

  // ---------- Ayarlar ----------

  void updateSettings(AppSettings s) {
    final old = _settings;
    _settings = s;
    _storage.saveSettings(s);
    if (old.reminderEnabled != s.reminderEnabled || old.reminderMinutes != s.reminderMinutes) _syncReminder();
    _completedInCycle = _completedInCycle.clamp(0, s.longBreakInterval);
    if (!_running &&
        _minutesFor(_phase) != _minutesForSettings(old, _phase) &&
        _remaining == Duration(minutes: _minutesForSettings(old, _phase))) {
      _remaining = total;
    }
    if (_running) {
      if (old.ambientVolume != s.ambientVolume) _audio.setAmbientVolume(s.ambientVolume);
      if (old.focusSound != s.focusSound || old.breakSound != s.breakSound) {
        _audio.playAmbient(_soundForPhase, s.ambientVolume);
      }
      if (old.doNotDisturb != s.doNotDisturb || old.keepScreenOn != s.keepScreenOn) _applyRunningSideEffects();
    }
    _persistTimer();
    notifyListeners();
  }

  static int _minutesForSettings(AppSettings s, Phase p) => switch (p) {
    Phase.focus => s.focusMinutes,
    Phase.shortBreak => s.shortBreakMinutes,
    Phase.longBreak => s.longBreakMinutes,
  };

  AudioService get audio => _audio;
  FocusModeService get focusMode => _focusMode;

  @override
  void dispose() {
    _ticker?.cancel();
    if (_dndActive) _focusMode.disable();
    super.dispose();
  }
}
