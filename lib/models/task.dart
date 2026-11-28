/// Kullanıcının çalışma hedefi (ör. "Fizik: elektrik tekrarı", 3 oturum).
class FocusTask {
  FocusTask({required this.id, required this.title, this.done = false, this.pomodoros = 0, this.target = 1});

  final String id;
  String title;
  bool done;

  /// Bu hedefte tamamlanan odak oturumu sayısı.
  int pomodoros;

  /// Planlanan oturum sayısı.
  int target;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done, 'pomodoros': pomodoros, 'target': target};

  factory FocusTask.fromJson(Map<String, dynamic> j) => FocusTask(
    id: j['id'] as String,
    title: j['title'] as String,
    done: j['done'] as bool? ?? false,
    pomodoros: j['pomodoros'] as int? ?? 0,
    target: (j['target'] as int? ?? 1).clamp(1, 20),
  );
}
