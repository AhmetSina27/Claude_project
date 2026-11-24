import 'dart:math';

import 'package:material_ui/material_ui.dart';

/// Tebrik ekranındaki konfeti yağmuru.
class Confetti extends StatefulWidget {
  const Confetti({super.key, required this.colors});
  final List<Color> colors;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Piece {
  _Piece(Random r, this.color)
    : x = r.nextDouble(),
      delay = r.nextDouble() * .35,
      speed = .55 + r.nextDouble() * .6,
      drift = (r.nextDouble() - .5) * .25,
      spin = (r.nextDouble() - .5) * 14,
      w = 6 + r.nextDouble() * 6,
      h = 10 + r.nextDouble() * 8;
  final double x, delay, speed, drift, spin, w, h;
  final Color color;
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _pieces = List.generate(90, (i) => _Piece(r, widget.colors[i % widget.colors.length]));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final y = -20 + lt * p.speed * (size.height + 60) * 1.3;
      final x = (p.x + p.drift * lt + sin(lt * 10 + p.x * 6) * .02) * size.width;
      final opacity = lt > .8 ? (1 - lt) / .2 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * lt);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h * (.4 + .6 * cos(lt * 12 + p.x * 9).abs())),
        Paint()..color = p.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
