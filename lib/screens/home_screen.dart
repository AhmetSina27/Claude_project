import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../util/turkce.dart';
import '../data/ambient.dart';
import '../models/day_stats.dart';
import '../models/phase.dart';
import '../state/pomodoro_controller.dart';
import '../widgets/ambient_background.dart';
import '../widgets/background_image.dart';
import '../widgets/flip_clock.dart';
import '../widgets/goals.dart';
import '../widgets/timer_shortcuts.dart';
import '../widgets/sound_picker.dart';
import 'celebration_screen.dart';
import 'focus_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../widgets/duration_chips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showingCelebration = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.of(context);
    if (c.pendingCelebration != null && !_showingCelebration) {
      _showingCelebration = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCelebration(c));
    }
  }

  Future<void> _showCelebration(PomodoroController c) async {
    final data = c.pendingCelebration;
    if (data == null || !mounted) {
      _showingCelebration = false;
      return;
    }
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        pageBuilder: (_, a, _) => FadeTransition(
          opacity: a,
          child: CelebrationScreen(data: data),
        ),
      ),
    );
    c.clearCelebration();
    _showingCelebration = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final b = Theme.of(context).brightness;
    final phaseColor = c.phase.color(c.settings.accent.forBrightness(b), b);
    final sound = c.phase == Phase.focus ? c.settings.focusSound : c.settings.breakSound;
    final bgImage = backgroundFor(c.settings, c, sound);

    return TimerShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () => toggleWithReminder(context, c),
        const SingleActivator(LogicalKeyboardKey.keyR): c.reset,
        const SingleActivator(LogicalKeyboardKey.keyS): c.skip,
        const SingleActivator(LogicalKeyboardKey.keyF): () => openFocusScreen(context),
      },
      child: Focus(
        autofocus: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: Color.alphaBlend(
            phaseColor.withValues(alpha: b == Brightness.dark ? .10 : .07),
            Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Stack(
            children: [
              if (bgImage != null)
                Positioned.fill(
                  child: BackgroundLayer(
                    source: bgImage,
                    dim: c.settings.backgroundDim,
                    blur: c.settings.backgroundBlur,
                    scrim: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              Positioned.fill(
                child: AmbientBackground(
                  sound: (bgImage?.scene?.ownsEffectOf(sound) ?? false) ? AmbientSound.none : sound,
                  dark: b == Brightness.dark,
                  intensity: c.isRunning ? 1 : .55,
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final wide = box.maxWidth >= 860;
                      final side = _SideSection(color: phaseColor, wide: wide);
                      return Column(
                        children: [
                          _TopBar(color: phaseColor),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, area) => SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Sayaç ilk ekranın tamamını kaplar; diğer kartlar aşağı kaydırınca gelir.
                                    SizedBox(
                                      height: area.maxHeight,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                        child: _TimerSection(color: phaseColor),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: wide ? 1200 : 560),
                                          child: side,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final today = c.today;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Odaklanma '),
                TextSpan(
                  text: 'Zamanı',
                  style: TextStyle(color: color),
                ),
              ],
            ),
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
          ),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width >= 480)
            Tooltip(
              message: 'Bugün',
              child: Text(
                '${today.focusSessions} oturum · ${formatDuration(today.focusSeconds)}',
                style: t.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          IconButton(
            tooltip: 'İstatistikler',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

class _TimerSection extends StatelessWidget {
  const _TimerSection({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, box) {
        // Yatay geniş ekranda (tablet, bilgisayar) üst kısım tek satıra iner, sayaç büyür.
        final landscape = box.maxWidth >= 700 && box.maxWidth > box.maxHeight * 1.15;
        final hasTaskLine = c.phase == Phase.focus;
        // Saatin dışındaki öğelerin kapladığı yaklaşık yükseklik.
        final chrome = landscape ? (hasTaskLine ? 200.0 : 172.0) : 368.0;
        const cards = 3;
        final byHeight = (box.maxHeight - chrome) / 1.18;
        final byWidth = (box.maxWidth - 24) / cards;
        final card = byHeight.clamp(70.0, byWidth.clamp(70.0, 460.0));
        final phases = SegmentedButton<Phase>(
          segments: [for (final p in Phase.values) ButtonSegment(value: p, label: Text(p.shortLabel))],
          selected: {c.phase},
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(selectedBackgroundColor: color, selectedForegroundColor: Colors.white),
          onSelectionChanged: (s) => c.selectPhase(s.first),
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (landscape)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  phases,
                  if (c.phase == Phase.focus) DurationChips(color: color, inline: true),
                ],
              )
            else ...[
              phases,
              const SizedBox(height: 12),
              if (c.phase == Phase.focus) DurationChips(color: color) else const SizedBox(height: 36),
              const SizedBox(height: 14),
              Text(
                trUpper(c.isFree ? 'Serbest odak' : c.phase.label),
                style: t.labelMedium?.copyWith(letterSpacing: 2.5, color: muted, fontWeight: FontWeight.w700),
              ),
              if (c.isPristine && !c.isFree)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: muted),
                      const SizedBox(width: 4),
                      Text('Süreyi değiştirmek için sayaca dokun', style: t.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                ),
            ],
            SizedBox(height: landscape ? 10 : 14),
            Tooltip(
              message: c.isRunning || c.isFree ? '' : 'Süreyi değiştirmek için dokun',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: c.isRunning || c.isFree ? null : () => showCustomDurationDialog(context, c),
                child: FlipClock(duration: c.display, maxCardSize: card, glass: c.settings.backgroundId != 'none'),
              ),
            ),
            SizedBox(height: landscape ? 8 : 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: landscape ? card * 3 : 520),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1 - c.progress,
                  minHeight: 4,
                  color: color,
                  backgroundColor: color.withValues(alpha: .15),
                ),
              ),
            ),
            if (c.phase == Phase.focus)
              Padding(
                padding: EdgeInsets.only(top: landscape ? 6 : 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: GoalLine(color: color),
                ),
              ),
            SizedBox(height: landscape ? 12 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(tooltip: 'Sıfırla (R)', onPressed: c.reset, icon: const Icon(Icons.replay_rounded)),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 160,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                    onPressed: () => toggleWithReminder(context, c),
                    icon: Icon(c.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      c.isRunning ? 'Duraklat' : (c.isPristine ? 'Başlat' : 'Devam et'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  tooltip: c.isFree ? 'Bitir ve kaydet (S)' : 'Atla (S)',
                  onPressed: c.skip,
                  icon: Icon(c.isFree ? Icons.stop_rounded : Icons.skip_next_rounded),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: 'Tam ekran (F)',
                  onPressed: () => openFocusScreen(context),
                  icon: const Icon(Icons.fullscreen_rounded),
                ),
              ],
            ),
            SizedBox(height: landscape ? 8 : 16),
            _CycleDots(done: c.completedInCycle, total: c.settings.longBreakInterval, color: color),
            if (c.isRunning && c.phase == Phase.focus && c.settings.doNotDisturb)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.do_not_disturb_on_rounded, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      c.focusMode.isSupported ? 'Bildirimler susturuldu' : 'Rahatsız Etme: sistem ayarından aç',
                      style: t.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CycleDots extends StatelessWidget {
  const _CycleDots({required this.done, required this.total, required this.color});
  final int done, total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Turda $done / $total oturum tamamlandı',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tur', style: TextStyle(color: muted)),
          const SizedBox(width: 8),
          for (var i = 0; i < total; i++)
            Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? color : Colors.transparent,
                border: Border.all(color: i < done ? color : muted, width: 1.5),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '$done/$total',
            style: TextStyle(color: muted, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _SideSection extends StatelessWidget {
  const _SideSection({required this.color, this.wide = false});
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final today = c.today;
    final goal = c.settings.dailyGoal;
    final items = <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bugün', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(label: 'Etüt süresi', value: formatDuration(today.focusSeconds)),
                  _Stat(label: 'Oturum', value: '${today.focusSessions}/$goal'),
                  _Stat(label: 'Mola', value: '${today.breaks}'),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal == 0 ? 0 : (today.focusSessions / goal).clamp(0, 1),
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: .15),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.phase == Phase.focus ? 'Odak sesi' : 'Mola sesi',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SoundPicker(
                color: color,
                selected: c.phase == Phase.focus ? c.settings.focusSound : c.settings.breakSound,
                onSelected: (s) => c.updateSettings(
                  c.phase == Phase.focus ? c.settings.copyWith(focusSound: s) : c.settings.copyWith(breakSound: s),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Card(
        child: Padding(padding: EdgeInsets.all(16), child: GoalsPanel()),
      ),
    ];
    if (!wide) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
    final cards = items.where((w) => w is! SizedBox).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, w) in cards.indexed) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: w)],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(label, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Başlat/duraklat; odak başlarken ve bildirimler uygulama tarafından kapatılamıyorsa
/// (iPad, iPhone, Mac, Windows, web) Rahatsız Etme'yi açmayı hatırlatır.
void toggleWithReminder(BuildContext context, PomodoroController c) {
  final starting = !c.isRunning && c.phase == Phase.focus;
  c.toggle();
  if (starting && c.settings.doNotDisturb && !c.focusMode.isSupported) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.do_not_disturb_on_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(c.focusMode.startReminder)),
            ],
          ),
          duration: const Duration(seconds: 7),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
