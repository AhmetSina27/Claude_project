class FocusTask {
  FocusTask({required this.id, required this.title, this.done = false, this.pomodoros = 0});

  final String id;
  String title;
  bool done;
  int pomodoros;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done, 'pomodoros': pomodoros};

  factory FocusTask.fromJson(Map<String, dynamic> j) => FocusTask(
    id: j['id'] as String,
    title: j['title'] as String,
    done: j['done'] as bool? ?? false,
    pomodoros: j['pomodoros'] as int? ?? 0,
  );
}
