import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// 0..1 arası sabit sözde rastgele sayı.
double rnd(int i, int salt) {
  final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// Bir sahnenin katmanları. Arka ve ön katmanlar sabittir ve bir kez resme çevrilip
/// önbelleğe alınır; aradaki ve en üstteki katmanlar her karede yeniden çizilir.
abstract class ScenePainter {
  const ScenePainter();

  /// Sabit arka plan (gökyüzü, uzak dağlar...).
  void back(Canvas c, Size s) {}

  /// Hareketli orta katman (yıldızlar, alevler, sis...).
  void mid(Canvas c, Size s, double t) {}

  /// Sabit ön katman (yakın dağlar, odunlar, pencere çerçevesi...).
  void front(Canvas c, Size s) {}

  /// Hareketli üst katman (kıvılcımlar, kuşlar, kar...).
  void top(Canvas c, Size s, double t) {}

  bool get hasFront => true;
}

// ---------------------------------------------------------------- yardımcılar

void fillGradient(Canvas c, Rect r, List<Color> colors, {List<double>? stops, bool vertical = true}) {
  c.drawRect(
    r,
    Paint()
      ..shader = ui.Gradient.linear(
        vertical ? r.topCenter : r.centerLeft,
        vertical ? r.bottomCenter : r.centerRight,
        colors,
        stops,
      ),
  );
}

void glow(Canvas c, Offset center, double radius, Color color, {BlendMode blend = BlendMode.srcOver}) {
  c.drawCircle(
    center,
    radius,
    Paint()
      ..blendMode = blend
      ..shader = ui.Gradient.radial(center, radius, [color, color.withValues(alpha: 0)]),
  );
}

/// Dalgalı dağ sırtı. [base] sırtın ortalama yüksekliği (0..1), [amp] dalga boyu.
Path ridge(Size s, double base, double amp, int seed, {double roughness = 1}) {
  final p = Path()..moveTo(0, s.height);
  final f1 = 1.5 + rnd(seed, 1) * 2, f2 = 4 + rnd(seed, 2) * 4, f3 = 11 + rnd(seed, 3) * 9;
  final o1 = rnd(seed, 4) * 6, o2 = rnd(seed, 5) * 6, o3 = rnd(seed, 6) * 6;
  for (double x = 0; x <= s.width + 6; x += 6) {
    final u = x / s.width;
    final v = .55 * sin(u * f1 * pi + o1) + .30 * sin(u * f2 * pi + o2) + .15 * roughness * sin(u * f3 * pi + o3);
    p.lineTo(x, s.height * (base - amp * v));
  }
  p
    ..lineTo(s.width, s.height)
    ..close();
  return p;
}

/// Kademeli çam ağacı silüeti.
Path pine(double x, double baseY, double h) {
  final w = h * .38;
  final p = Path();
  const tiers = 5;
  for (var i = 0; i < tiers; i++) {
    final ty = baseY - h * (i / tiers) * .92;
    final tw = w * (1 - i / tiers * .75);
    final top = baseY - h * ((i + 1.6) / tiers) * .92;
    p
      ..moveTo(x - tw / 2, ty)
      ..lineTo(x, max(top, baseY - h))
      ..lineTo(x + tw / 2, ty)
      ..close();
  }
  p.addRect(Rect.fromLTWH(x - w * .05, baseY - h * .08, w * .1, h * .08));
  return p;
}

// ================================================================ 1. Yıldız kayması

class NightSkyScene extends ScenePainter {
  const NightSkyScene();

  @override
  void back(Canvas c, Size s) {
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF050817), Color(0xFF111A3D), Color(0xFF2B2E5E), Color(0xFF4A3F6E)],
      stops: const [0, .45, .75, 1],
    );
    // Samanyolu bandı
    c.save();
    c.translate(s.width * .5, s.height * .35);
    c.rotate(-.5);
    final band = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, s.shortestSide * .08);
    band.color = const Color(0xFF9FA8FF).withValues(alpha: .10);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s.longestSide * 1.4, height: s.shortestSide * .22), band);
    band.color = const Color(0xFFFFE3F2).withValues(alpha: .06);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s.longestSide * .9, height: s.shortestSide * .08), band);
    c.restore();
    // Ay
    final moon = Offset(s.width * .78, s.height * .2);
    final mr = s.shortestSide * .055;
    glow(c, moon, mr * 6, const Color(0xFFBFD0FF).withValues(alpha: .25));
    c.drawCircle(moon, mr, Paint()..color = const Color(0xFFF4F1E6));
    c.drawCircle(moon + Offset(mr * .3, -mr * .2), mr * .18, Paint()..color = const Color(0xFFE2DDCB));
    c.drawCircle(moon + Offset(-mr * .35, mr * .3), mr * .12, Paint()..color = const Color(0xFFE2DDCB));
  }

  @override
  void mid(Canvas c, Size s, double t) {
    final p = Paint();
    final n = (s.width * s.height / 4200).clamp(120, 420).toInt();
    for (var i = 0; i < n; i++) {
      final x = rnd(i, 1) * s.width;
      final y = rnd(i, 2) * s.height * .78;
      final big = rnd(i, 3);
      final tw = .45 + .55 * (.5 + .5 * sin(t * (.6 + rnd(i, 4) * 2.4) + i));
      p.color = Color.lerp(
        const Color(0xFFFFFFFF),
        const Color(0xFFBFD4FF),
        rnd(i, 5),
      )!.withValues(alpha: tw * (.35 + big * .6));
      c.drawCircle(Offset(x, y), .5 + big * big * 1.6, p);
    }
    // Kayan yıldızlar
    for (var k = 0; k < 2; k++) {
      final period = k == 0 ? 6.0 : 9.5;
      final tt = t + k * 3.1;
      final cycle = (tt / period).floor();
      final phase = (tt % period) / period;
      if (phase > .16) continue;
      final pr = phase / .16;
      final start = Offset(s.width * (.25 + rnd(cycle, 11 + k) * .7), s.height * (.05 + rnd(cycle, 13 + k) * .3));
      final ang = pi * (.78 + rnd(cycle, 15) * .12);
      final dir = Offset(cos(ang), sin(ang));
      final dist = s.shortestSide * (.35 + rnd(cycle, 17) * .25);
      final head = start + dir * dist * pr;
      final tail = head - dir * s.shortestSide * .18 * min(1, pr * 3);
      final fade = pr < .8 ? 1.0 : (1 - pr) / .2;
      c.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(tail, head, [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .9 * fade),
          ]),
      );
      glow(c, head, 8, Colors.white.withValues(alpha: .7 * fade));
    }
  }

  @override
  void front(Canvas c, Size s) {
    c.drawPath(ridge(s, .74, .08, 3), Paint()..color = const Color(0xFF2A2852));
    c.drawPath(ridge(s, .82, .07, 7), Paint()..color = const Color(0xFF1A1A3A));
    c.drawPath(ridge(s, .9, .05, 11, roughness: 2), Paint()..color = const Color(0xFF0D0E22));
    // Tepedeki küçük gözlemci
    final hx = s.width * .3, hy = s.height * .87;
    final h = s.shortestSide * .025;
    final ink = Paint()..color = const Color(0xFF0D0E22);
    c.drawCircle(Offset(hx, hy - h * 2.4), h * .35, ink);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(hx - h * .3, hy - h * 2, h * .6, h * 1.6), Radius.circular(h * .2)),
      ink,
    );
  }
}

// ================================================================ 2. Kuzey ışıkları

class AuroraScene extends ScenePainter {
  const AuroraScene();

  @override
  void back(Canvas c, Size s) {
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF020A14), Color(0xFF06202E), Color(0xFF0E3440)],
      stops: const [0, .55, 1],
    );
    final p = Paint();
    for (var i = 0; i < 160; i++) {
      p.color = Colors.white.withValues(alpha: .2 + rnd(i, 3) * .5);
      c.drawCircle(Offset(rnd(i, 1) * s.width, rnd(i, 2) * s.height * .6), .4 + rnd(i, 4) * 1.1, p);
    }
  }

  void _ribbons(Canvas c, Size s, double t, {double alpha = 1}) {
    const colors = [Color(0xFF3CFFB0), Color(0xFF59E0FF), Color(0xFFB57BFF)];
    for (var k = 0; k < 3; k++) {
      final top = <Offset>[];
      for (double x = -20; x <= s.width + 20; x += 10) {
        final y =
            s.height * (.16 + k * .07) +
            sin(x / (s.width * .22) + t * (.18 + k * .05) + k * 2) * s.height * .05 +
            sin(x / (s.width * .07) - t * .35 + k) * s.height * .012;
        top.add(Offset(x, y));
      }
      final depth = s.height * (.22 - k * .04);
      final path = Path()..moveTo(top.first.dx, top.first.dy);
      for (final o in top) {
        path.lineTo(o.dx, o.dy);
      }
      for (final o in top.reversed) {
        path.lineTo(o.dx, o.dy + depth);
      }
      path.close();
      final minY = s.height * (.16 + k * .07) - s.height * .07;
      final col = colors[k];
      final pulse = .75 + .25 * sin(t * .5 + k * 1.7);
      c.drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(
            Offset(0, minY),
            Offset(0, minY + depth + s.height * .1),
            [col.withValues(alpha: .0), col.withValues(alpha: .38 * pulse * alpha), col.withValues(alpha: 0)],
            const [0, .25, 1],
          ),
      );
      final edge = Path()..addPolygon(top, false);
      c.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..color = col.withValues(alpha: .45 * pulse * alpha),
      );
    }
  }

  @override
  void mid(Canvas c, Size s, double t) {
    _ribbons(c, s, t);
    // Göldeki yansıma
    final lakeTop = s.height * .8;
    c.save();
    c.clipRect(Rect.fromLTRB(0, lakeTop, s.width, s.height));
    c.translate(0, lakeTop * 2 + s.height * .02);
    c.scale(1, -1);
    _ribbons(c, s, t, alpha: .35);
    c.restore();
  }

  @override
  void front(Canvas c, Size s) {
    final m1 = ridge(s, .66, .1, 21);
    c.drawPath(m1, Paint()..color = const Color(0xFF1B3644));
    // Karlı tepeler
    c.save();
    c.clipPath(m1);
    fillGradient(c, Rect.fromLTWH(0, s.height * .52, s.width, s.height * .12), [
      const Color(0xFFDDEFFF).withValues(alpha: .55),
      const Color(0x00DDEFFF),
    ]);
    c.restore();
    c.drawPath(ridge(s, .76, .05, 25, roughness: 1.6), Paint()..color = const Color(0xFF0C1F28));
    // Göl
    final lake = Rect.fromLTRB(0, s.height * .8, s.width, s.height);
    fillGradient(c, lake, [const Color(0xCC06202E), const Color(0xEE020A14)]);
    final pines = Paint()..color = const Color(0xFF040D12);
    for (var i = 0; i < 26; i++) {
      final x = rnd(i, 31) * s.width;
      c.drawPath(pine(x, s.height * .805, s.height * (.05 + rnd(i, 32) * .06)), pines);
    }
  }
}

// ================================================================ 3. Şömine

class FireplaceScene extends ScenePainter {
  const FireplaceScene();

  Rect _opening(Size s) {
    final w = min(s.width * .62, s.height * .9);
    final h = min(s.height * .5, w * .78);
    return Rect.fromLTWH((s.width - w) / 2, s.height * .9 - h, w, h);
  }

  Path _arch(Rect r) {
    final rr = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + rr * .55)
      ..arcToPoint(Offset(r.right, r.top + rr * .55), radius: Radius.elliptical(rr, rr * .55))
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  void back(Canvas c, Size s) {
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF140B08), Color(0xFF2A1610), Color(0xFF1A0E0A)],
      stops: const [0, .7, 1],
    );
    final o = _opening(s);
    // Tuğlalar
    final bh = max(14.0, o.height * .085);
    final bw = bh * 2.3;
    final mortar = bh * .12;
    final wall = Rect.fromLTRB(o.left - bw * 2.2, o.top - bh * 3.2, o.right + bw * 2.2, s.height * .92);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(wall, Radius.circular(bh)));
    var row = 0;
    for (double y = wall.top; y < wall.bottom; y += bh) {
      final off = row.isOdd ? bw / 2 : 0;
      var col = 0;
      for (double x = wall.left - off; x < wall.right; x += bw) {
        final v = rnd(row * 97 + col, 41);
        final color = Color.lerp(const Color(0xFF7A3B26), const Color(0xFFA2583A), v)!;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + mortar / 2, y + mortar / 2, bw - mortar, bh - mortar),
            Radius.circular(bh * .12),
          ),
          Paint()..color = color,
        );
        col++;
      }
      row++;
    }
    c.restore();
    // Kenarları karartan gölge
    c.drawRect(
      wall,
      Paint()
        ..shader = ui.Gradient.radial(o.center, wall.longestSide * .7, [
          const Color(0x00000000),
          const Color(0xCC0A0504),
        ]),
    );
    // Ocak içi
    final arch = _arch(o);
    c.drawPath(arch, Paint()..color = const Color(0xFF120806));
    c.save();
    c.clipPath(arch);
    for (double y = o.top; y < o.bottom; y += bh * .9) {
      c.drawLine(
        Offset(o.left, y),
        Offset(o.right, y),
        Paint()
          ..color = const Color(0xFF2A1510)
          ..strokeWidth = 1,
      );
    }
    c.restore();
    // Ocak tabanı
    c.drawRect(
      Rect.fromLTRB(wall.left, o.bottom, wall.right, o.bottom + bh * .8),
      Paint()..color = const Color(0xFF3A2219),
    );
  }

  @override
  void mid(Canvas c, Size s, double t) {
    final o = _opening(s);
    final base = o.bottom - o.height * .1;
    final cx = o.center.dx;
    final fw = o.width * .6;
    final fh = o.height * .72;
    c.save();
    c.clipPath(_arch(o));
    final flicker = .85 + .15 * sin(t * 9) * sin(t * 4.3 + 1);
    glow(
      c,
      Offset(cx, base),
      o.width * .7 * flicker,
      const Color(0xFFFF7A1A).withValues(alpha: .45),
      blend: BlendMode.plus,
    );
    for (final layer in [0, 1, 2]) {
      final n = 7 - layer * 2;
      for (var i = 0; i < n; i++) {
        final u = n == 1 ? 0.0 : (i / (n - 1) - .5);
        final noise = .55 + .25 * sin(t * (5.1 + layer) + i * 1.7) + .2 * sin(t * (8.3 + i * .3) + i * 2.9);
        final h = fh * (1 - layer * .28) * (1 - u.abs() * .9) * noise;
        final w = fw * (.28 - layer * .05);
        final x = cx + u * fw * (.9 - layer * .25);
        final sway = sin(t * 3.2 + i * 1.3 + layer) * w * .35;
        final path = Path()
          ..moveTo(x - w / 2, base)
          ..quadraticBezierTo(x - w * .75, base - h * .45, x + sway, base - h)
          ..quadraticBezierTo(x + w * .75, base - h * .45, x + w / 2, base)
          ..close();
        final colors = switch (layer) {
          0 => [const Color(0xFFFF4A10), const Color(0x00C01800)],
          1 => [const Color(0xFFFF9A20), const Color(0x00FF5A10)],
          _ => [const Color(0xFFFFF4B8), const Color(0x00FFC040)],
        };
        c.drawPath(
          path,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.linear(Offset(x, base), Offset(x, base - h), [
              colors[0].withValues(alpha: .85),
              colors[1],
            ]),
        );
      }
    }
    c.restore();
  }

  @override
  void front(Canvas c, Size s) {
    final o = _opening(s);
    final base = o.bottom - o.height * .06;
    final logW = o.width * .42, logH = o.height * .075;
    void log(double cx, double cy, double angle) {
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);
      final r = Rect.fromCenter(center: Offset.zero, width: logW, height: logH);
      c.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(logH / 2)),
        Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF5A3420), Color(0xFF2A160C)]),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(r.right - logH * .4, 0), width: logH * .8, height: logH),
        Paint()..color = const Color(0xFFB07A4E),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(r.right - logH * .4, 0), width: logH * .4, height: logH * .5),
        Paint()..color = const Color(0xFF8A5A36),
      );
      c.restore();
    }

    log(o.center.dx - o.width * .12, base - logH * .6, .18);
    log(o.center.dx + o.width * .12, base - logH * .6, -.18);
    log(o.center.dx, base - logH * 1.3, 0);
    // Közler
    for (var i = 0; i < 30; i++) {
      final x = o.center.dx + (rnd(i, 51) - .5) * o.width * .7;
      glow(c, Offset(x, base + logH * .1), 6 + rnd(i, 52) * 6, const Color(0xFFFF6A1A).withValues(alpha: .7));
    }
  }

  @override
  void top(Canvas c, Size s, double t) {
    final o = _opening(s);
    final flicker = .8 + .2 * sin(t * 7.3) * sin(t * 2.9 + 1);
    // Odaya yayılan sıcak ışık
    glow(
      c,
      Offset(o.center.dx, o.bottom),
      s.longestSide * .8,
      const Color(0xFFFF7A2A).withValues(alpha: .12 * flicker),
      blend: BlendMode.plus,
    );
    // Yükselen kıvılcımlar
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 40; i++) {
      final life = 2.5 + rnd(i, 61) * 3;
      final ph = ((t + rnd(i, 62) * life) % life) / life;
      final x = o.center.dx + (rnd(i, 63) - .5) * o.width * .5 + sin(ph * 8 + i) * 14 * ph;
      final y = o.bottom - o.height * .2 - ph * o.height * (.8 + rnd(i, 64) * .6);
      final a = (ph < .1 ? ph / .1 : 1 - ph);
      p.color = const Color(0xFFFFB347).withValues(alpha: a * .9);
      c.drawCircle(Offset(x, y), 1.2 + (1 - ph) * 1.6, p);
    }
  }
}

// ================================================================ 4. Dağ gölü

class LakeScene extends ScenePainter {
  const LakeScene();

  double _horizon(Size s) => s.height * .62;

  @override
  void back(Canvas c, Size s) {
    final hz = _horizon(s);
    fillGradient(
      c,
      Rect.fromLTWH(0, 0, s.width, hz),
      const [Color(0xFF2D4777), Color(0xFF8E6E9C), Color(0xFFE9A27A), Color(0xFFF7D08A)],
      stops: const [0, .45, .8, 1],
    );
    final sun = Offset(s.width * .62, hz - s.height * .05);
    glow(c, sun, s.shortestSide * .45, const Color(0xFFFFE2A0).withValues(alpha: .55));
    c.drawCircle(sun, s.shortestSide * .045, Paint()..color = const Color(0xFFFFF3CF));
    c.drawPath(ridge(Size(s.width, hz), .72, .16, 41), Paint()..color = const Color(0xFF8A7BA6));
    c.drawPath(ridge(Size(s.width, hz), .84, .12, 43), Paint()..color = const Color(0xFF5E5784));
    c.drawPath(ridge(Size(s.width, hz), .95, .07, 47, roughness: 1.8), Paint()..color = const Color(0xFF3A3A60));
    // Göl ve yansıma
    final lake = Rect.fromLTRB(0, hz, s.width, s.height);
    fillGradient(c, lake, const [Color(0xFFD9A288), Color(0xFF6E6A92), Color(0xFF2A3157)], stops: const [0, .35, 1]);
    c.save();
    c.clipRect(lake);
    c.translate(0, hz * 2);
    c.scale(1, -1);
    c.drawPath(ridge(Size(s.width, hz), .84, .12, 43), Paint()..color = const Color(0xFF5E5784).withValues(alpha: .45));
    c.drawPath(
      ridge(Size(s.width, hz), .95, .07, 47, roughness: 1.8),
      Paint()..color = const Color(0xFF3A3A60).withValues(alpha: .5),
    );
    c.restore();
  }

  @override
  void mid(Canvas c, Size s, double t) {
    final hz = _horizon(s);
    // Bulutlar
    for (var i = 0; i < 6; i++) {
      final w = s.width * (.22 + rnd(i, 71) * .25);
      final speed = 6 + rnd(i, 72) * 10;
      final span = s.width + w * 2;
      final x = (rnd(i, 73) * span + t * speed) % span - w;
      final y = s.height * (.08 + rnd(i, 74) * .28);
      for (var j = 0; j < 4; j++) {
        final center = Offset(x + j * w * .22, y + (j.isOdd ? -w * .03 : w * .01));
        final r = w * (.16 + rnd(i * 7 + j, 75) * .08);
        c.drawCircle(
          center,
          r,
          Paint()..shader = ui.Gradient.radial(center, r, [const Color(0x55FFE6D2), const Color(0x00FFE6D2)]),
        );
      }
    }
    // Su parıltıları
    final sunX = s.width * .62;
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 70; i++) {
      final y = hz + 4 + rnd(i, 81) * (s.height - hz) * .9;
      final spread = (y - hz) / (s.height - hz);
      final x = sunX + (rnd(i, 82) - .5) * s.width * (.06 + spread * .35);
      final a = (.5 + .5 * sin(t * (2 + rnd(i, 83) * 3) + i * 3)) * (1 - spread * .7);
      final len = 6 + rnd(i, 84) * 22 * (1 + spread);
      p
        ..color = const Color(0xFFFFE9B8).withValues(alpha: a * .7)
        ..strokeWidth = 1.5;
      c.drawLine(Offset(x - len / 2, y), Offset(x + len / 2, y), p);
    }
    // Yavaş dalga çizgileri
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .08);
    for (var k = 0; k < 6; k++) {
      final y0 = hz + (s.height - hz) * (.15 + k * .14);
      final path = Path()..moveTo(0, y0);
      for (double x = 0; x <= s.width; x += 12) {
        path.lineTo(x, y0 + sin(x / 50 + t * (.8 + k * .2) + k) * (1.5 + k));
      }
      c.drawPath(path, wave);
    }
  }

  @override
  void front(Canvas c, Size s) {
    final hz = _horizon(s);
    final ink = Paint()..color = const Color(0xFF1C1E36);
    for (var i = 0; i < 7; i++) {
      final x = rnd(i, 91) * s.width * .22;
      c.drawPath(pine(x, hz + s.height * .02, s.height * (.16 + rnd(i, 92) * .12)), ink);
    }
    for (var i = 0; i < 5; i++) {
      final x = s.width * (.86 + rnd(i, 93) * .16);
      c.drawPath(pine(x, hz + s.height * .02, s.height * (.14 + rnd(i, 94) * .14)), ink);
    }
    c.drawRect(Rect.fromLTWH(0, hz, s.width * .24, s.height * .02), ink);
    c.drawRect(Rect.fromLTWH(s.width * .84, hz, s.width * .16, s.height * .02), ink);
  }

  @override
  void top(Canvas c, Size s, double t) {
    // Uçan kuşlar
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2A2440).withValues(alpha: .8);
    const period = 28.0;
    final ph = (t % period) / period;
    for (var i = 0; i < 5; i++) {
      final x = -40 + ph * (s.width + 120) - i * 18 - (i.isOdd ? 6 : 0);
      final y = s.height * .3 + i * 9 * (i.isOdd ? 1 : -.4) + sin(t * .7) * 10;
      final flap = sin(t * 7 + i) * 4;
      final path = Path()
        ..moveTo(x - 7, y - flap)
        ..quadraticBezierTo(x - 3, y - 2, x, y)
        ..quadraticBezierTo(x + 3, y - 2, x + 7, y - flap);
      c.drawPath(path, p);
    }
  }
}

// ================================================================ 5. Sisli orman

class MistyForestScene extends ScenePainter {
  const MistyForestScene();

  void _layer(Canvas c, Size s, int seed, double baseY, double minH, double maxH, Color color, int count) {
    final p = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      final x = (i + rnd(i, seed) * .8) / count * (s.width + 40) - 20;
      c.drawPath(pine(x, s.height * baseY, s.height * (minH + rnd(i, seed + 1) * (maxH - minH))), p);
    }
    c.drawRect(Rect.fromLTRB(0, s.height * baseY, s.width, s.height), p);
  }

  @override
  void back(Canvas c, Size s) {
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF4E6E72), Color(0xFF35545A), Color(0xFF1E3538)],
      stops: const [0, .5, 1],
    );
    glow(c, Offset(s.width * .3, s.height * .15), s.longestSide * .5, const Color(0xFFD8EEE6).withValues(alpha: .22));
    _layer(c, s, 101, .55, .18, .28, const Color(0xFF466569), 22);
    _layer(c, s, 111, .66, .22, .34, const Color(0xFF33504F), 18);
  }

  void _fog(Canvas c, Size s, double t, double y, double alpha, double speed, int seed) {
    for (var i = 0; i < 4; i++) {
      final w = s.width * (.6 + rnd(i, seed) * .5);
      final span = s.width + w;
      final x = (rnd(i, seed + 1) * span + t * speed * (1 + i * .3)) % span - w / 2;
      final center = Offset(x, s.height * (y + (rnd(i, seed + 2) - .5) * .06));
      final r = Rect.fromCenter(center: center, width: w, height: s.height * .14);
      c.drawOval(
        r,
        Paint()
          ..shader = ui.Gradient.radial(center, w / 2, [
            Color(0xFFE6F0EA).withValues(alpha: alpha),
            const Color(0x00E6F0EA),
          ]),
      );
    }
  }

  @override
  void mid(Canvas c, Size s, double t) => _fog(c, s, t, .64, .45, 8, 121);

  @override
  void front(Canvas c, Size s) {
    _layer(c, s, 131, .8, .3, .45, const Color(0xFF1F3734), 14);
    _layer(c, s, 141, .97, .45, .7, const Color(0xFF0C1A15), 8);
  }

  @override
  void top(Canvas c, Size s, double t) => _fog(c, s, t, .9, .22, 5, 151);
}

// ================================================================ 6. Karlı pencere

class SnowyWindowScene extends ScenePainter {
  const SnowyWindowScene();

  Rect _window(Size s) {
    final w = min(s.width * .7, s.height * .75);
    final h = min(s.height * .72, w * 1.05);
    return Rect.fromLTWH((s.width - w) / 2, s.height * .1, w, h);
  }

  Path _shape(Rect r) {
    final rr = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + rr)
      ..arcToPoint(Offset(r.right, r.top + rr), radius: Radius.circular(rr))
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  void _tree(Canvas c, Offset base, double len, double angle, int depth, Paint p) {
    if (depth == 0 || len < 3) return;
    final end = base + Offset(cos(angle), sin(angle)) * len;
    p.strokeWidth = max(.8, depth * .9);
    c.drawLine(base, end, p);
    _tree(c, end, len * .72, angle - .45 - rnd(depth, 7) * .2, depth - 1, p);
    _tree(c, end, len * .7, angle + .4 + rnd(depth, 9) * .2, depth - 1, p);
  }

  @override
  void back(Canvas c, Size s) {
    // Sıcak oda duvarı
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF3B271C), Color(0xFF2A1A12), Color(0xFF1C110C)],
      stops: const [0, .6, 1],
    );
    final win = _window(s);
    final shape = _shape(win);
    // Dışarısı: karlı gece
    c.save();
    c.clipPath(shape);
    fillGradient(c, win, const [Color(0xFF243554), Color(0xFF4C5F82), Color(0xFF8C9BB5)], stops: const [0, .6, 1]);
    final ground = Path()
      ..moveTo(win.left, win.bottom - win.height * .2)
      ..quadraticBezierTo(win.center.dx, win.bottom - win.height * .28, win.right, win.bottom - win.height * .18)
      ..lineTo(win.right, win.bottom)
      ..lineTo(win.left, win.bottom)
      ..close();
    c.drawPath(ground, Paint()..color = const Color(0xFFE4ECF6));
    final branch = Paint()
      ..color = const Color(0xFF3A4660)
      ..strokeCap = StrokeCap.round;
    _tree(c, Offset(win.left + win.width * .32, win.bottom - win.height * .23), win.height * .2, -pi / 2, 7, branch);
    branch.color = const Color(0xFF5A6A88);
    _tree(c, Offset(win.left + win.width * .78, win.bottom - win.height * .21), win.height * .12, -pi / 2, 6, branch);
    // Uzak kulübe ışığı
    glow(
      c,
      Offset(win.left + win.width * .6, win.bottom - win.height * .22),
      win.width * .05,
      const Color(0xFFFFC27A).withValues(alpha: .8),
    );
    c.restore();
  }

  @override
  void mid(Canvas c, Size s, double t) {
    final win = _window(s);
    c.save();
    c.clipPath(_shape(win));
    final p = Paint();
    for (var i = 0; i < 160; i++) {
      final depth = rnd(i, 1);
      final speed = 14 + depth * 40;
      final travel = win.height + 20;
      final y = win.top + ((t * speed + rnd(i, 2) * travel) % travel) - 10;
      final x = win.left + (rnd(i, 3) * win.width + sin(t * (.4 + depth) + i) * (6 + depth * 12)) % win.width;
      p.color = Colors.white.withValues(alpha: .4 + depth * .55);
      c.drawCircle(Offset(x, y), .8 + depth * 2.2, p);
    }
    c.restore();
  }

  @override
  void front(Canvas c, Size s) {
    final win = _window(s);
    final shape = _shape(win);
    // Ahşap çerçeve ve kayıtlar
    final wood = Paint()
      ..color = const Color(0xFF6B4329)
      ..style = PaintingStyle.stroke
      ..strokeWidth = win.width * .035;
    c.drawPath(shape, wood);
    final mull = Paint()
      ..color = const Color(0xFF6B4329)
      ..strokeWidth = win.width * .02;
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), mull);
    c.drawLine(Offset(win.left, win.top + win.width * .5), Offset(win.right, win.top + win.width * .5), mull);
    // Pencere önü minderi
    final seat = Rect.fromLTWH(win.left - win.width * .08, win.bottom, win.width * 1.16, s.height * .07);
    c.drawRRect(RRect.fromRectAndRadius(seat, const Radius.circular(10)), Paint()..color = const Color(0xFFD9C8B4));
    for (var i = 0; i < 3; i++) {
      final pr = Rect.fromLTWH(
        seat.left + seat.width * (.08 + i * .2),
        seat.top - seat.height * .55,
        seat.width * .16,
        seat.height * .7,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(pr, const Radius.circular(12)),
        Paint()..color = [const Color(0xFF8C5A3C), const Color(0xFFC9B39A), const Color(0xFF6E7F6A)][i],
      );
    }
  }

  @override
  void top(Canvas c, Size s, double t) {
    final win = _window(s);
    // Sarkan lambalar
    for (var i = 0; i < 3; i++) {
      final x = s.width * (.1 + i * .06);
      final y = s.height * (.12 + i * .05);
      c.drawLine(
        Offset(x, 0),
        Offset(x, y),
        Paint()
          ..color = const Color(0xFF120A06)
          ..strokeWidth = 1.2,
      );
      final f = .85 + .15 * sin(t * 2.3 + i * 2);
      glow(c, Offset(x, y + 6), 60, const Color(0xFFFFB35C).withValues(alpha: .35 * f), blend: BlendMode.plus);
      c.drawCircle(Offset(x, y + 6), 7, Paint()..color = const Color(0xFFFFD08A));
    }
    // Pencere kenarındaki mum
    final mx = win.right + win.width * .02, my = win.bottom - 4;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(mx - 7, my - 34, 14, 34), const Radius.circular(3)),
      Paint()..color = const Color(0xFFF1E6D2),
    );
    final f = sin(t * 11) * 1.5;
    final flame = Path()
      ..moveTo(mx - 4, my - 36)
      ..quadraticBezierTo(mx - 5, my - 46, mx + f, my - 54)
      ..quadraticBezierTo(mx + 5, my - 46, mx + 4, my - 36)
      ..close();
    c.drawPath(flame, Paint()..color = const Color(0xFFFFC45A));
    glow(c, Offset(mx, my - 44), 90 + f * 4, const Color(0xFFFF9A3C).withValues(alpha: .3), blend: BlendMode.plus);
  }
}

// ================================================================ 7. Gün batımı denizi

class SunsetSeaScene extends ScenePainter {
  const SunsetSeaScene();

  double _horizon(Size s) => s.height * .58;

  @override
  void back(Canvas c, Size s) {
    final hz = _horizon(s);
    fillGradient(
      c,
      Rect.fromLTWH(0, 0, s.width, hz),
      const [Color(0xFF2B1B4A), Color(0xFF8A3A6B), Color(0xFFE8664A), Color(0xFFFFB45A)],
      stops: const [0, .45, .8, 1],
    );
    final sun = Offset(s.width * .5, hz);
    glow(c, sun, s.shortestSide * .6, const Color(0xFFFFC27A).withValues(alpha: .5));
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, s.width, hz));
    c.drawCircle(sun, s.shortestSide * .11, Paint()..color = const Color(0xFFFFE3A6));
    c.restore();
    // İnce bulut çizgileri
    final cl = Paint()..color = const Color(0xFF6A2E5A).withValues(alpha: .45);
    for (var i = 0; i < 6; i++) {
      final y = hz * (.25 + rnd(i, 201) * .55);
      final w = s.width * (.2 + rnd(i, 202) * .4);
      final x = rnd(i, 203) * s.width - w / 2;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 4 + rnd(i, 204) * 6), const Radius.circular(6)), cl);
    }
    fillGradient(
      c,
      Rect.fromLTRB(0, hz, s.width, s.height),
      const [Color(0xFF6B3A6A), Color(0xFF2A1C45), Color(0xFF120E26)],
      stops: const [0, .4, 1],
    );
  }

  @override
  void mid(Canvas c, Size s, double t) {
    final hz = _horizon(s);
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 120; i++) {
      final y = hz + 3 + pow(rnd(i, 211), 1.6) * (s.height - hz);
      final spread = (y - hz) / (s.height - hz);
      final x = s.width * .5 + (rnd(i, 212) - .5) * s.width * (.12 + spread * .5);
      final a = (.5 + .5 * sin(t * (1.5 + rnd(i, 213) * 3) + i * 2.3));
      final len = 8 + rnd(i, 214) * 30 * (1 + spread * 2);
      p
        ..strokeWidth = 1.2 + spread * 2
        ..color = const Color(0xFFFFD08A).withValues(alpha: a * (.8 - spread * .5));
      c.drawLine(Offset(x - len / 2, y), Offset(x + len / 2, y), p);
    }
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var k = 0; k < 9; k++) {
      final f = k / 8;
      final y0 = hz + (s.height - hz) * (.08 + f * f * .9);
      wave.color = const Color(0xFFFFB0A0).withValues(alpha: .06 + f * .08);
      final path = Path()..moveTo(0, y0);
      for (double x = 0; x <= s.width; x += 10) {
        path.lineTo(x, y0 + sin(x / (40 + k * 12) + t * (.6 + k * .1) + k) * (1 + k * .8));
      }
      c.drawPath(path, wave);
    }
  }

  @override
  bool get hasFront => false;

  @override
  void top(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2A1630).withValues(alpha: .85);
    for (var i = 0; i < 3; i++) {
      final period = 22.0 + i * 5;
      final ph = ((t + i * 7) % period) / period;
      final x = s.width + 40 - ph * (s.width + 80);
      final y = s.height * (.2 + i * .07) + sin(t * .6 + i) * 14;
      final flap = sin(t * 5 + i * 2) * 5;
      final path = Path()
        ..moveTo(x - 10, y - flap)
        ..quadraticBezierTo(x - 4, y - 3, x, y)
        ..quadraticBezierTo(x + 4, y - 3, x + 10, y - flap);
      c.drawPath(path, p);
    }
  }
}

// ================================================================ 8. Sakin

class CalmScene extends ScenePainter {
  const CalmScene();

  @override
  void back(Canvas c, Size s) => fillGradient(c, Offset.zero & s, const [Color(0xFF141834), Color(0xFF1E1A3A)]);

  @override
  bool get hasFront => false;

  @override
  void mid(Canvas c, Size s, double t) {
    const colors = [Color(0xFF3FB8AF), Color(0xFF7B5CD6), Color(0xFFE88A7A), Color(0xFF3A6FD8), Color(0xFFD6B35C)];
    for (var i = 0; i < colors.length; i++) {
      final sp = .04 + rnd(i, 301) * .05;
      final center = Offset(
        s.width * (.5 + .38 * sin(t * sp + i * 1.9)),
        s.height * (.5 + .36 * cos(t * sp * 1.3 + i * 2.7)),
      );
      final r = s.longestSide * (.35 + .1 * sin(t * .1 + i));
      c.drawCircle(
        center,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = ui.Gradient.radial(center, r, [colors[i].withValues(alpha: .55), colors[i].withValues(alpha: 0)]),
      );
    }
    final p = Paint();
    for (var i = 0; i < 40; i++) {
      final life = 14 + rnd(i, 311) * 10;
      final ph = ((t + rnd(i, 312) * life) % life) / life;
      final x = rnd(i, 313) * s.width + sin(ph * 6 + i) * 20;
      final y = s.height * (1.05 - ph * 1.1);
      p.color = Colors.white.withValues(alpha: sin(ph * pi) * .35);
      c.drawCircle(Offset(x, y), 1.2 + rnd(i, 314) * 1.5, p);
    }
  }
}
