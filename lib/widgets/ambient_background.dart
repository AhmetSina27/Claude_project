import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../data/ambient.dart';

/// Seçilen ortam sesine göre arka planda oynayan görsel efekt
/// (yağmur, ateş, orman, dere, dalgalar, karlı kulübe, tik tak).
///
/// Parçacıklar durumsuzdur: her birinin konumu tohum değeri ve geçen süreden
/// hesaplanır, bu yüzden bellek ve işlemci yükü düşüktür.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.sound, required this.dark, this.intensity = 1});

  final AmbientSound sound;
  final bool dark;

  /// 0..1 arası; sayaç durmuşken efekt daha soluk görünür.
  final double intensity;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6);
    _syncTicker();
  }

  @override
  void didUpdateWidget(AmbientBackground old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  void _syncTicker() {
    final shouldRun = widget.sound != AmbientSound.none;
    if (shouldRun && !_ticker.isActive) _ticker.start();
    if (!shouldRun && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sound == AmbientSound.none) return const SizedBox.expand();
    final reduce = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedOpacity(
          opacity: widget.intensity.clamp(0.0, 1.0),
          duration: const Duration(milliseconds: 600),
          child: CustomPaint(
            size: Size.infinite,
            painter: _AmbientPainter(sound: widget.sound, dark: widget.dark, time: reduce ? null : _time),
          ),
        ),
      ),
    );
  }
}

/// 0..1 arası sabit sözde rastgele sayı.
double _r(int i, int salt) {
  final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({required this.sound, required this.dark, ValueNotifier<double>? time})
    : _time = time,
      super(repaint: time);

  final AmbientSound sound;
  final bool dark;
  final ValueNotifier<double>? _time;

  double get t => _time?.value ?? 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    switch (sound) {
      case AmbientSound.yagmur:
        _rain(canvas, size);
      case AmbientSound.ates:
        _fire(canvas, size);
      case AmbientSound.kulube:
        _cabin(canvas, size);
      case AmbientSound.orman:
        _forest(canvas, size);
      case AmbientSound.doga:
        _water(canvas, size);
      case AmbientSound.dalga:
        _water(canvas, size);
      case AmbientSound.kahverengi:
      case AmbientSound.sinav:
      case AmbientSound.gece:
      case AmbientSound.ruzgar:
      case AmbientSound.sualti:
        break;
      case AmbientSound.guguklu:
        _pulse(canvas, size);
      case AmbientSound.tiktak:
        _pulse(canvas, size);
      case AmbientSound.none:
        break;
    }
  }

  // ---------- Yağmur ----------
  void _rain(Canvas canvas, Size s) {
    // Hafif mavi-gri sis
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0x00203048), const Color(0x55203048)]
              : [const Color(0x00607890), const Color(0x22607890)],
        ).createShader(Offset.zero & s),
    );
    final count = (s.width * s.height / 5200).clamp(60, 260).toInt();
    const slant = .18; // rüzgârla eğim
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final depth = _r(i, 1); // 0 uzak, 1 yakın
      final speed = s.height * (1.1 + depth * 1.4);
      final len = 14 + depth * 26;
      final travel = s.height + len + s.height * slant;
      final y = ((t * speed + _r(i, 2) * travel) % travel) - len;
      final x = _r(i, 3) * (s.width + s.height * slant) - y * slant;
      p
        ..strokeWidth = .8 + depth * 1.4
        ..color = (dark ? const Color(0xFFB9CBE6) : const Color(0xFF4F6A88)).withValues(alpha: .18 + depth * .32);
      canvas.drawLine(Offset(x, y), Offset(x - len * slant, y + len), p);
    }
    // Yere çarpan damlaların halkaları
    final splash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 18; i++) {
      final period = .7 + _r(i, 4) * .6;
      final phase = ((t + _r(i, 5) * period) % period) / period;
      final cycle = ((t + _r(i, 5) * period) / period).floor();
      final x = _r(i * 31 + cycle, 6) * s.width;
      final y = s.height * (.86 + _r(i * 17 + cycle, 7) * .12);
      splash.color = (dark ? const Color(0xFFB9CBE6) : const Color(0xFF4F6A88)).withValues(alpha: (1 - phase) * .35);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 4 + phase * 26, height: 1.5 + phase * 6), splash);
    }
  }

  // ---------- Şömine ateşi ----------
  void _fire(Canvas canvas, Size s) {
    final flicker = .85 + .15 * sin(t * 7.3) * sin(t * 3.1 + 1);
    final glowR = s.longestSide * .75 * flicker;
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.25),
          radius: 1,
          colors: [
            const Color(0xFFFF7A2E).withValues(alpha: dark ? .38 : .22),
            const Color(0xFFE2401C).withValues(alpha: dark ? .16 : .08),
            const Color(0x00E2401C),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: Offset(s.width / 2, s.height * 1.1), radius: glowR)),
    );
    final count = (s.width / 9).clamp(40, 140).toInt();
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < count; i++) {
      final life = 3 + _r(i, 1) * 4;
      final phase = ((t + _r(i, 2) * life) % life) / life;
      final x0 = s.width * (.15 + _r(i, 3) * .7);
      final x = x0 + sin(phase * 6 + i) * 30 * phase + (_r(i, 4) - .5) * 80 * phase;
      final y = s.height * (1.02 - phase * (.55 + _r(i, 5) * .45));
      final a = (phase < .1 ? phase / .1 : 1 - phase) * .9;
      final hot = _r(i, 6);
      p.color = Color.lerp(const Color(0xFFFFD36B), const Color(0xFFFF5A1F), hot)!.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 1.2 + (1 - phase) * 2.2, p);
    }
  }

  // ---------- Karlı kulübe: kar taneleri + şömine ışıltısı ----------
  void _cabin(Canvas canvas, Size s) {
    final flicker = .85 + .15 * sin(t * 6.1) * sin(t * 2.3 + 1);
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.85, 1.1),
          radius: .9,
          colors: [
            const Color(0xFFFF8A3D).withValues(alpha: (dark ? .30 : .18) * flicker),
            const Color(0x00FF8A3D),
          ],
        ).createShader(Offset.zero & s),
    );
    final count = (s.width * s.height / 6500).clamp(50, 220).toInt();
    final flake = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    for (var i = 0; i < count; i++) {
      final depth = _r(i, 1);
      final speed = 18 + depth * 55;
      final size = 1.2 + depth * 2.8;
      final travel = s.height + 20;
      final y = ((t * speed + _r(i, 2) * travel) % travel) - 10;
      final x = (_r(i, 3) * s.width + sin(t * (.4 + depth) + i) * (10 + depth * 18) + t * 6) % s.width;
      flake.color = (dark ? Colors.white : const Color(0xFF8A98AE)).withValues(alpha: .35 + depth * .5);
      canvas.drawCircle(Offset(x, y), size, flake);
    }
  }

  // ---------- Orman ----------
  void _forest(Canvas canvas, Size s) {
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0x00163A2A), const Color(0x66163A2A)]
              : [const Color(0x002E6B4A), const Color(0x1F2E6B4A)],
        ).createShader(Offset.zero & s),
    );
    // Ağaç silüetleri
    final tree = Paint()
      ..color = (dark ? const Color(0xFF0E241A) : const Color(0xFF2E6B4A)).withValues(alpha: dark ? .55 : .10);
    for (var i = 0; i < 9; i++) {
      final x = s.width * (i / 8) + (_r(i, 1) - .5) * 40;
      final h = s.height * (.18 + _r(i, 2) * .16);
      final w = h * .42;
      final path = Path()
        ..moveTo(x, s.height - h)
        ..lineTo(x - w / 2, s.height)
        ..lineTo(x + w / 2, s.height)
        ..close();
      canvas.drawPath(path, tree);
    }
    // Ateş böcekleri
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final core = Paint();
    final n = (s.width / 18).clamp(18, 60).toInt();
    for (var i = 0; i < n; i++) {
      final sp = .05 + _r(i, 3) * .08;
      final x = s.width * (_r(i, 4) + .08 * sin(t * sp * 6 + i)) % s.width;
      final y = s.height * (.25 + .7 * _r(i, 5)) + 26 * sin(t * sp * 9 + i * 2);
      final blink = (.5 + .5 * sin(t * (1 + _r(i, 6) * 2) + i * 3)).clamp(0.0, 1.0);
      final c = (dark ? const Color(0xFFD9F27A) : const Color(0xFF7FA21E)).withValues(alpha: blink * (dark ? .85 : .6));
      glow.color = c.withValues(alpha: c.a * .6);
      core.color = c;
      canvas.drawCircle(Offset(x, y), 6, glow);
      canvas.drawCircle(Offset(x, y), 1.8, core);
    }
    // Süzülen yapraklar
    final leaf = Paint();
    for (var i = 0; i < 10; i++) {
      final life = 9 + _r(i, 7) * 6;
      final phase = ((t + _r(i, 8) * life) % life) / life;
      final x = s.width * _r(i, 9) + sin(phase * 9 + i) * 40;
      final y = -20 + phase * (s.height + 40);
      leaf.color = (dark ? const Color(0xFF6FA36A) : const Color(0xFF5E8F4A)).withValues(alpha: .35);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * 12 + i);
      canvas.drawOval(const Rect.fromLTWH(-7, -3, 14, 6), leaf);
      canvas.restore();
    }
  }

  // ---------- Doğa (dere) ----------
  void _water(Canvas canvas, Size s) {
    final base = dark ? const Color(0xFF6FC3C9) : const Color(0xFF2E8C95);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var k = 0; k < 7; k++) {
      final y0 = s.height * (.62 + k * .055);
      final amp = 6 + k * 2.2;
      final speed = .6 + k * .25;
      p.color = base.withValues(alpha: .10 + k * .045);
      final path = Path()..moveTo(0, y0);
      for (double x = 0; x <= s.width; x += 8) {
        path.lineTo(x, y0 + sin(x / (60 + k * 14) + t * speed + k) * amp + sin(x / 23 - t * 1.7) * 2);
      }
      canvas.drawPath(path, p);
    }
    // Su üstünde parıltılar
    final spark = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 30; i++) {
      final a = (sin(t * (1.5 + _r(i, 1) * 2) + i * 4) * .5 + .5);
      spark.color = Colors.white.withValues(alpha: a * (dark ? .35 : .5));
      canvas.drawCircle(Offset(s.width * _r(i, 2), s.height * (.64 + _r(i, 3) * .34)), 2.2, spark);
    }
  }

  // ---------- Tik tak ----------
  void _pulse(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final p = Paint()..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      final phase = ((t - k / 3) % 1 + 1) % 1;
      p
        ..strokeWidth = 1.5
        ..color = (dark ? Colors.white : const Color(0xFF3A3F55)).withValues(alpha: (1 - phase) * (dark ? .12 : .10));
      canvas.drawCircle(c, s.shortestSide * (.25 + phase * .5), p);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.sound != sound || old.dark != dark || old._time != _time;
}
