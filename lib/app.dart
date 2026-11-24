import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'state/pomodoro_controller.dart';

/// Denetleyiciyi ağaçtaki tüm ekranlara ulaştırır.
class AppScope extends InheritedNotifier<PomodoroController> {
  const AppScope({super.key, required PomodoroController controller, required super.child})
    : super(notifier: controller);

  static PomodoroController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Yeniden çizim tetiklemeden erişim (buton callback'leri için).
  static PomodoroController read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class OdaklanmaApp extends StatefulWidget {
  const OdaklanmaApp({super.key, required this.controller});
  final PomodoroController controller;

  @override
  State<OdaklanmaApp> createState() => _OdaklanmaAppState();
}

class _OdaklanmaAppState extends State<OdaklanmaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bg =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached;
    widget.controller.setInBackground(bg);
  }

  ThemeData _theme(Brightness b) {
    final s = widget.controller.settings;
    final seed = s.accent.forBrightness(b);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b).copyWith(primary: seed);
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: b);
    return base.copyWith(
      scaffoldBackgroundColor: b == Brightness.dark ? const Color(0xFF171413) : const Color(0xFFF7F4F2),
      cardTheme: CardThemeData(
        elevation: 0,
        color: b == Brightness.dark ? const Color(0xFF221E1C) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: b == Brightness.dark ? const Color(0xFF39322F) : const Color(0xFFE6E0DC)),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: b == Brightness.dark ? const Color(0xFFF2ECE8) : const Color(0xFF1F1A18),
        displayColor: b == Brightness.dark ? const Color(0xFFF2ECE8) : const Color(0xFF1F1A18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => MaterialApp(
          title: 'Odaklanma Zamanı',
          debugShowCheckedModeBanner: false,
          themeMode: widget.controller.settings.backgroundId == 'none'
              ? widget.controller.settings.themeMode
              : ThemeMode.dark,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
