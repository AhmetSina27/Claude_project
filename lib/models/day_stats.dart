/// Bir günün etüt (odak) ve mola sayımları.
class DayStats {
  DayStats({this.focusSessions = 0, this.focusSeconds = 0, this.breaks = 0, this.breakSeconds = 0});

  int focusSessions;
  int focusSeconds;
  int breaks;
  int breakSeconds;

  bool get isEmpty => focusSessions == 0 && focusSeconds == 0 && breaks == 0;

  Map<String, dynamic> toJson() => {'fs': focusSessions, 'fsec': focusSeconds, 'b': breaks, 'bsec': breakSeconds};

  factory DayStats.fromJson(Map<String, dynamic> j) => DayStats(
    focusSessions: j['fs'] as int? ?? 0,
    focusSeconds: j['fsec'] as int? ?? 0,
    breaks: j['b'] as int? ?? 0,
    breakSeconds: j['bsec'] as int? ?? 0,
  );

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// "1 sa 25 dk" gibi okunur süre.
String formatDuration(int seconds) {
  final m = seconds ~/ 60;
  if (m < 60) return '$m dk';
  final h = m ~/ 60;
  final r = m % 60;
  return r == 0 ? '$h sa' : '$h sa $r dk';
}
