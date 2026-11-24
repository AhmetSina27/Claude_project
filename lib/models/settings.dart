import 'package:material_ui/material_ui.dart';

import '../data/ambient.dart';

/// Kullanıcının seçebileceği tema renkleri.
enum AccentTheme {
  kirmizi('Kırmızı', Color(0xFFD2462F), Color(0xFFF0664C)),
  gunbatimi('Gün batımı', Color(0xFFC2620E), Color(0xFFF0954A)),
  orman('Orman', Color(0xFF2E7D4F), Color(0xFF5DB48F)),
  okyanus('Okyanus', Color(0xFF1F6FA8), Color(0xFF5AA9E0)),
  lavanta('Lavanta', Color(0xFF6A4FB3), Color(0xFFA48BEA)),
  gece('Gece', Color(0xFF3B4466), Color(0xFF9AA6D6)),
  pembe('Gül', Color(0xFFB83B6E), Color(0xFFEB7AA6));

  const AccentTheme(this.label, this.light, this.dark);
  final String label;
  final Color light;
  final Color dark;

  Color forBrightness(Brightness b) => b == Brightness.dark ? dark : light;

  static AccentTheme fromName(String? n) =>
      AccentTheme.values.firstWhere((t) => t.name == n, orElse: () => AccentTheme.kirmizi);
}

@immutable
class AppSettings {
  const AppSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakInterval = 4,
    this.dailyGoal = 8,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
    this.accent = AccentTheme.kirmizi,
    this.themeMode = ThemeMode.system,
    this.focusSound = AmbientSound.yagmur,
    this.breakSound = AmbientSound.none,
    this.ambientVolume = 0.6,
    this.bellEnabled = true,
    this.bellVolume = 0.9,
    this.celebrationEnabled = true,
    this.applauseEnabled = true,
    this.doNotDisturb = false,
    this.keepScreenOn = true,
    this.backgroundId = 'auto',
    this.backgroundDim = .25,
    this.backgroundBlur = 0,
    this.freeFocus = false,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakInterval;
  final int dailyGoal;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final AccentTheme accent;
  final ThemeMode themeMode;
  final AmbientSound focusSound;
  final AmbientSound breakSound;
  final double ambientVolume;
  final bool bellEnabled;
  final double bellVolume;
  final bool celebrationEnabled;
  final bool applauseEnabled;
  final bool doNotDisturb;
  final bool keepScreenOn;

  /// 'none', 'custom' (cihazdan seçilen) veya hazır görselin kimliği.
  final String backgroundId;

  /// Görselin üstüne serilen perde (0 = yok, 1 = tamamen örtülü). Yazıların okunması için.
  final double backgroundDim;

  /// Bulanıklık miktarı (0-20).
  final double backgroundBlur;

  /// Serbest odak: süre sınırı olmadan ileri sayan kronometre.
  final bool freeFocus;

  AppSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
    int? dailyGoal,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    AccentTheme? accent,
    ThemeMode? themeMode,
    AmbientSound? focusSound,
    AmbientSound? breakSound,
    double? ambientVolume,
    bool? bellEnabled,
    double? bellVolume,
    bool? celebrationEnabled,
    bool? applauseEnabled,
    bool? doNotDisturb,
    bool? keepScreenOn,
    String? backgroundId,
    double? backgroundDim,
    double? backgroundBlur,
    bool? freeFocus,
  }) => AppSettings(
    focusMinutes: focusMinutes ?? this.focusMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    longBreakInterval: longBreakInterval ?? this.longBreakInterval,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
    autoStartFocus: autoStartFocus ?? this.autoStartFocus,
    accent: accent ?? this.accent,
    themeMode: themeMode ?? this.themeMode,
    focusSound: focusSound ?? this.focusSound,
    breakSound: breakSound ?? this.breakSound,
    ambientVolume: ambientVolume ?? this.ambientVolume,
    bellEnabled: bellEnabled ?? this.bellEnabled,
    bellVolume: bellVolume ?? this.bellVolume,
    celebrationEnabled: celebrationEnabled ?? this.celebrationEnabled,
    applauseEnabled: applauseEnabled ?? this.applauseEnabled,
    doNotDisturb: doNotDisturb ?? this.doNotDisturb,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    backgroundId: backgroundId ?? this.backgroundId,
    backgroundDim: backgroundDim ?? this.backgroundDim,
    backgroundBlur: backgroundBlur ?? this.backgroundBlur,
    freeFocus: freeFocus ?? this.freeFocus,
  );

  Map<String, dynamic> toJson() => {
    'focusMinutes': focusMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'longBreakInterval': longBreakInterval,
    'dailyGoal': dailyGoal,
    'autoStartBreaks': autoStartBreaks,
    'autoStartFocus': autoStartFocus,
    'accent': accent.name,
    'themeMode': themeMode.name,
    'focusSound': focusSound.name,
    'breakSound': breakSound.name,
    'ambientVolume': ambientVolume,
    'bellEnabled': bellEnabled,
    'bellVolume': bellVolume,
    'celebrationEnabled': celebrationEnabled,
    'applauseEnabled': applauseEnabled,
    'doNotDisturb': doNotDisturb,
    'keepScreenOn': keepScreenOn,
    'backgroundId': backgroundId,
    'backgroundDim': backgroundDim,
    'backgroundBlur': backgroundBlur,
    'freeFocus': freeFocus,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    int i(String k, int def) => (j[k] as num?)?.toInt() ?? def;
    bool b(String k, bool def) => j[k] as bool? ?? def;
    double v(String k, double def) => (j[k] as num?)?.toDouble() ?? def;
    return AppSettings(
      focusMinutes: i('focusMinutes', d.focusMinutes),
      shortBreakMinutes: i('shortBreakMinutes', d.shortBreakMinutes),
      longBreakMinutes: i('longBreakMinutes', d.longBreakMinutes),
      longBreakInterval: i('longBreakInterval', d.longBreakInterval),
      dailyGoal: i('dailyGoal', d.dailyGoal),
      autoStartBreaks: b('autoStartBreaks', d.autoStartBreaks),
      autoStartFocus: b('autoStartFocus', d.autoStartFocus),
      accent: AccentTheme.fromName(j['accent'] as String?),
      themeMode: ThemeMode.values.firstWhere((m) => m.name == j['themeMode'], orElse: () => ThemeMode.system),
      focusSound: j.containsKey('focusSound') ? AmbientSound.fromName(j['focusSound'] as String?) : d.focusSound,
      breakSound: AmbientSound.fromName(j['breakSound'] as String?),
      ambientVolume: v('ambientVolume', d.ambientVolume),
      bellEnabled: b('bellEnabled', d.bellEnabled),
      bellVolume: v('bellVolume', d.bellVolume),
      celebrationEnabled: b('celebrationEnabled', d.celebrationEnabled),
      applauseEnabled: b('applauseEnabled', d.applauseEnabled),
      doNotDisturb: b('doNotDisturb', d.doNotDisturb),
      keepScreenOn: b('keepScreenOn', d.keepScreenOn),
      backgroundId: j['backgroundId'] as String? ?? d.backgroundId,
      backgroundDim: v('backgroundDim', d.backgroundDim),
      backgroundBlur: v('backgroundBlur', d.backgroundBlur),
      freeFocus: b('freeFocus', d.freeFocus),
    );
  }
}
