import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../data/ambient.dart';
import '../models/phase.dart';
import '../widgets/ambient_background.dart';
import 'home_screen.dart' show toggleWithReminder;
import '../widgets/background_image.dart';
import '../widgets/flip_clock.dart';
import '../widgets/timer_shortcuts.dart';
import '../widgets/sound_picker.dart';

Future<void> openFocusScreen(BuildContext context) => Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, a, _) => FadeTransition(opacity: a, child: const FocusScreen()),
    transitionDuration: const Duration(milliseconds: 350),
  ),
);

/// Tam ekran odak görünümü: lacivert zemin, büyük çevirmeli saat, arka plan efekti.
/// Tablet yatay konumda masaya konduğunda masa saati gibi kullanılır.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const _bgTop = Color(0xFF151A33);
  static const _bgBottom = Color(0xFF0B0E1E);
  static const _ink = Color(0xFFE9EAF2);
  static const _muted = Color(0xFF9AA0BC);

  late final Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _clock.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _pickSound(BuildContext context) {
    final c = AppScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C2140),
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: c,
        builder: (ctx, _) {
          final focus = c.phase == Phase.focus;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  focus ? 'Odak sesi ve efekti' : 'Mola sesi ve efekti',
                  style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Theme(
                  data: ThemeData(
                    brightness: Brightness.dark,
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Theme.of(context).colorScheme.primary,
                      brightness: Brightness.dark,
                    ),
                  ),
                  child: SoundPicker(
                    color: Theme.of(context).colorScheme.primary,
                    selected: focus ? c.settings.focusSound : c.settings.breakSound,
                    onSelected: (s) => c.updateSettings(
                      focus ? c.settings.copyWith(focusSound: s) : c.settings.copyWith(breakSound: s),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final accent = c.phase.color(c.settings.accent.forBrightness(Brightness.dark), Brightness.dark);
    final sound = c.phase == Phase.focus ? c.settings.focusSound : c.settings.breakSound;
    final task = c.activeTask;
    final bgImage = backgroundFor(c.settings, c, sound);

    Widget iconBtn(IconData icon, String tip, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, color: _muted),
      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .06)),
    );

    return TimerShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () => toggleWithReminder(context, c),
        const SingleActivator(LogicalKeyboardKey.keyR): c.reset,
        const SingleActivator(LogicalKeyboardKey.keyS): c.skip,
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.keyF): () => Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: _bgBottom,
          body: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_bgTop, _bgBottom],
                    ),
                  ),
                ),
              ),
              if (bgImage != null)
                Positioned.fill(
                  child: BackgroundLayer(
                    source: bgImage,
                    // Tam ekranda yazılar beyaz; okunabilmesi için en az %35 karartma.
                    dim: .15 + c.settings.backgroundDim * .6,
                    blur: c.settings.backgroundBlur,
                    scrim: _bgBottom,
                  ),
                ),
              Positioned.fill(
                child: AmbientBackground(
                  sound: (bgImage?.scene?.ownsEffectOf(sound) ?? false) ? AmbientSound.none : sound,
                  dark: true,
                  intensity: c.isRunning ? 1 : .5,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Üst çubuk
                      Row(
                        children: [
                          iconBtn(Icons.arrow_back_ios_new_rounded, 'Geri', () => Navigator.of(context).maybePop()),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final p in Phase.values)
                                  GestureDetector(
                                    onTap: () => c.selectPhase(p),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: p == c.phase ? Colors.white.withValues(alpha: .85) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        p.shortLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: p == c.phase ? const Color(0xFF151A33) : _muted,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          iconBtn(sound.icon, 'Ses ve efekt', () => _pickSound(context)),
                        ],
                      ),
                      // Saat
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final maxCard = (box.maxHeight * .62).clamp(80.0, 520.0);
                            return Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatClockLine(_now),
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: .5,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    if (c.phase == Phase.focus && task != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(task.title, style: const TextStyle(color: _muted, fontSize: 13)),
                                      ),
                                    SizedBox(height: box.maxHeight * .04),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 1100),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: FlipClock(
                                          duration: c.display,
                                          maxCardSize: maxCard,
                                          labelColor: _ink,
                                          glass: bgImage != null,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: box.maxHeight * .05),
                                    // Hap şeklinde başlat/duraklat
                                    Semantics(
                                      button: true,
                                      label: c.isRunning ? 'Duraklat' : 'Başlat',
                                      child: InkWell(
                                        onTap: () => toggleWithReminder(context, c),
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          width: 132,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: .10),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.white.withValues(alpha: .55), width: 1.5),
                                          ),
                                          child: Icon(
                                            c.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            color: _ink,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (var i = 0; i < c.settings.longBreakInterval; i++)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: i < c.completedInCycle ? accent : Colors.transparent,
                                              border: Border.all(
                                                color: i < c.completedInCycle ? accent : _muted,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Alt köşeler
                      Row(
                        children: [
                          iconBtn(Icons.replay_rounded, 'Sıfırla', c.reset),
                          const Spacer(),
                          iconBtn(
                            c.isFree ? Icons.stop_rounded : Icons.skip_next_rounded,
                            c.isFree ? 'Bitir' : 'Atla',
                            c.skip,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
