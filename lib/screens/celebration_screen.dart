import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../util/turkce.dart';
import '../data/quotes.dart';
import '../models/day_stats.dart';
import '../state/pomodoro_controller.dart';
import '../widgets/confetti.dart';

/// Odak bitince açılan motivasyon ekranı: tebrik, gün serisi, ünlü birinin sözü,
/// bugünkü etüt ve mola özeti. Arkada seçili hareketli sahne oynamaya devam eder.
class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key, required this.data});
  final Celebration data;

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void initState() {
    super.initState();
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.read(context);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final accent = scheme.primary;
    final d = widget.data;
    final s = d.today;
    final goalDone = d.goal > 0 && s.focusSessions >= d.goal;
    final hasScene = c.settings.backgroundId != 'none';
    final reduce = MediaQuery.of(context).disableAnimations;
    final muted = scheme.onSurface.withValues(alpha: .72);

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(goalDone ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded, size: 52, color: accent),
        const SizedBox(height: 6),
        Text(
          goalDone ? 'Hedefe ulaştın!' : 'Tebrikler!',
          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Odak oturumunu tamamladın: ${formatDuration(d.sessionMinutes * 60)}',
          textAlign: TextAlign.center,
          style: t.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: 14),
        _StreakChip(days: d.streak),
        const SizedBox(height: 22),
        // Motivasyon sözü: ekranın odağı
        _QuoteBlock(quote: d.quote, accent: accent, animate: !reduce),
        const SizedBox(height: 24),
        Divider(color: scheme.onSurface.withValues(alpha: .12), height: 1),
        const SizedBox(height: 18),
        Text(
          'BUGÜN',
          style: t.labelMedium?.copyWith(letterSpacing: 2, color: muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final items = [
              _CountUp(
                value: s.focusSeconds.toDouble(),
                label: 'toplam etüt',
                color: accent,
                seconds: true,
                animate: !reduce,
              ),
              _CountUp(value: s.focusSessions.toDouble(), label: 'oturum', color: accent, animate: !reduce),
              _CountUp(value: s.breaks.toDouble(), label: 'mola', color: scheme.onSurface, animate: !reduce),
              _CountUp(
                value: s.breakSeconds.toDouble(),
                label: 'mola süresi',
                color: scheme.onSurface,
                seconds: true,
                animate: !reduce,
              ),
            ];
            if (box.maxWidth >= 420) {
              return Row(children: [for (final i in items) Expanded(child: i)]);
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: items[0]),
                    Expanded(child: items[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: items[2]),
                    Expanded(child: items[3]),
                  ],
                ),
              ],
            );
          },
        ),
        if (d.goal > 0) ...[
          const SizedBox(height: 18),
          _GoalBar(done: s.focusSessions, goal: d.goal, color: accent, animate: !reduce),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              if (!c.isRunning) c.start();
              Navigator.of(context).pop();
            },
            child: Text(
              c.isRunning ? 'Devam' : '${c.phase.label} başlat',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kapat')),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Arkadaki sahne görünür kalsın: hafif bulanıklık ve hafif karartma.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: hasScene ? 3 : 10, sigmaY: hasScene ? 3 : 10),
              child: ColoredBox(
                color: hasScene
                    ? Colors.black.withValues(alpha: .28)
                    : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: .8),
              ),
            ),
          ),
          Positioned.fill(
            child: Confetti(
              colors: [
                accent,
                const Color(0xFFF2B33D),
                const Color(0xFF5DB48F),
                const Color(0xFF7C9BE0),
                const Color(0xFFE86FA0),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, .04),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
                            decoration: BoxDecoration(
                              color: hasScene
                                  ? const Color(0xFF14121C).withValues(alpha: .55)
                                  : scheme.surface.withValues(alpha: .92),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: hasScene ? .14 : .06)),
                            ),
                            child: card,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 gündür üst üste çalışıyorsun" etiketi.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    const flame = Color(0xFFFF8A3D);
    final text = days >= 2 ? '$days gündür üst üste çalışıyorsun' : 'Serin başladı, yarın da devam et';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: flame.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: flame.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: flame, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: flame, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Büyük, serif yazıyla kelime kelime beliren motivasyon sözü.
class _QuoteBlock extends StatefulWidget {
  const _QuoteBlock({required this.quote, required this.accent, required this.animate});
  final Quote quote;
  final Color accent;
  final bool animate;

  @override
  State<_QuoteBlock> createState() => _QuoteBlockState();
}

class _QuoteBlockState extends State<_QuoteBlock> with SingleTickerProviderStateMixin {
  late final List<String> _words = widget.quote.text.split(' ');
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 500 + _words.length * 140),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _c.forward();
      });
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final n = _words.length;
    final width = MediaQuery.sizeOf(context).width;
    final size = width < 400 ? 22.0 : 26.0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            trUpper(widget.quote.theme.label),
            style: TextStyle(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '“',
          style: TextStyle(fontFamily: 'Lora', fontSize: 54, height: .6, color: widget.accent.withValues(alpha: .8)),
        ),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value * (n + 2);
            return Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < n; i++)
                    TextSpan(
                      text: i == n - 1 ? _words[i] : '${_words[i]} ',
                      style: TextStyle(color: ink.withValues(alpha: (v - i).clamp(0.0, 1.0))),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lora',
                fontStyle: FontStyle.italic,
                fontVariations: const [FontVariation('wght', 500)],
                fontSize: size,
                height: 1.35,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Opacity(opacity: ((_c.value - .85) / .15).clamp(0.0, 1.0), child: child),
          child: Text(
            '— ${widget.quote.author}',
            style: TextStyle(
              color: ink.withValues(alpha: .7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Sıfırdan yukarı sayan istatistik.
class _CountUp extends StatelessWidget {
  const _CountUp({
    required this.value,
    required this.label,
    required this.color,
    required this.animate,
    this.seconds = false,
  });
  final double value;
  final String label;
  final Color color;
  final bool seconds;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: animate ? const Duration(milliseconds: 1400) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Column(
        children: [
          Text(
            seconds ? formatDuration(v.round()) : '${v.round()}',
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
          ),
        ],
      ),
    );
  }
}

/// Dolarak ilerleyen günlük hedef çubuğu.
class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.done, required this.goal, required this.color, required this.animate});
  final int done, goal;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final target = (done / goal).clamp(0.0, 1.0);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .7);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? ((done - 1) / goal).clamp(0.0, 1.0) : target, end: target),
      duration: animate ? const Duration(milliseconds: 1200) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            done >= goal
                ? 'Günlük hedef tamam: $done/$goal oturum'
                : 'Günlük hedef: $done/$goal oturum · ${goal - done} kaldı',
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
