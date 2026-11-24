import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/day_stats.dart';
import '../models/settings.dart';
import '../models/task.dart';

/// Ayarları, görevleri, istatistikleri ve süren zamanlayıcıyı cihazda saklar.
class Storage {
  Storage(this._prefs);
  final SharedPreferences _prefs;

  static Future<Storage> open() async => Storage(await SharedPreferences.getInstance());

  static const _kSettings = 'settings';
  static const _kTasks = 'tasks';
  static const _kActiveTask = 'activeTask';
  static const _kStats = 'stats';
  static const _kTimer = 'timer';

  Map<String, dynamic>? _json(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  AppSettings loadSettings() {
    final j = _json(_kSettings);
    return j == null ? const AppSettings() : AppSettings.fromJson(j);
  }

  Future<void> saveSettings(AppSettings s) => _prefs.setString(_kSettings, jsonEncode(s.toJson()));

  List<FocusTask>? loadTasks() {
    final raw = _prefs.getString(_kTasks);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).map((e) => FocusTask.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTasks(List<FocusTask> tasks, String? activeId) async {
    await _prefs.setString(_kTasks, jsonEncode(tasks.map((t) => t.toJson()).toList()));
    if (activeId == null) {
      await _prefs.remove(_kActiveTask);
    } else {
      await _prefs.setString(_kActiveTask, activeId);
    }
  }

  String? loadActiveTask() => _prefs.getString(_kActiveTask);

  Map<String, DayStats> loadStats() {
    final j = _json(_kStats) ?? {};
    return j.map((k, v) => MapEntry(k, DayStats.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> saveStats(Map<String, DayStats> stats) {
    // Son 120 günü tut.
    final keys = stats.keys.toList()..sort();
    final keep = keys.length > 120 ? keys.sublist(keys.length - 120) : keys;
    return _prefs.setString(_kStats, jsonEncode({for (final k in keep) k: stats[k]!.toJson()}));
  }

  String? loadString(String key) => _prefs.getString(key);
  Future<void> saveString(String key, String value) => _prefs.setString(key, value);
  Future<void> removeKey(String key) => _prefs.remove(key);

  Map<String, dynamic>? loadTimer() => _json(_kTimer);
  Future<void> saveTimer(Map<String, dynamic> t) => _prefs.setString(_kTimer, jsonEncode(t));
}
