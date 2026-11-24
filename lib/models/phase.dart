import 'package:material_ui/material_ui.dart';

/// Pomodoro döngüsündeki aşamalar.
enum Phase {
  focus('Odaklanma', 'Odak'),
  shortBreak('Kısa mola', 'Kısa mola'),
  longBreak('Uzun mola', 'Uzun mola');

  const Phase(this.label, this.shortLabel);
  final String label;
  final String shortLabel;

  bool get isBreak => this != Phase.focus;

  /// Aşamanın rengi. Odak rengi kullanıcının seçtiği temadan gelir.
  Color color(Color focusColor, Brightness b) {
    final dark = b == Brightness.dark;
    return switch (this) {
      Phase.focus => focusColor,
      Phase.shortBreak => dark ? const Color(0xFF5DB48F) : const Color(0xFF3F8A6B),
      Phase.longBreak => dark ? const Color(0xFF7C9BE0) : const Color(0xFF3C5FA8),
    };
  }
}
