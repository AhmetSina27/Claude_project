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

  /// Gerçek fotoğraflı sahnelerde zemindeki fotoğrafın asset yolu. Fotoğraf yavaşça
  /// yakınlaşıp uzaklaşır; [mid] ve [top] katmanları (kar, dolu...) üstüne çizilir.
  String? get photo => null;
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

// ================================================================ 9. Kiraz çiçekleri

class SakuraScene extends ScenePainter {
  const SakuraScene();

  @override
  void back(Canvas c, Size s) {
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF2A1E44), Color(0xFF6A3F70), Color(0xFFD88FA0), Color(0xFFF2C1B5)],
      stops: const [0, .45, .8, 1],
    );
    // Dolunay
    final moon = Offset(s.width * .7, s.height * .24);
    final mr = s.shortestSide * .09;
    glow(c, moon, mr * 4, const Color(0xFFFFE6EE).withValues(alpha: .35));
    c.drawCircle(moon, mr, Paint()..color = const Color(0xFFFFF1EC));
    // Karlı tepeli dağ
    final base = s.height * .78;
    final peak = Offset(s.width * .38, s.height * .36);
    final mountain = Path()
      ..moveTo(s.width * -.05, base)
      ..quadraticBezierTo(peak.dx - s.width * .15, peak.dy + s.height * .18, peak.dx, peak.dy)
      ..quadraticBezierTo(peak.dx + s.width * .15, peak.dy + s.height * .18, s.width * .85, base)
      ..close();
    c.drawPath(mountain, Paint()..color = const Color(0xFF5B4A7A));
    c.save();
    c.clipPath(mountain);
    final cap = Path()
      ..moveTo(peak.dx - s.width * .09, peak.dy + s.height * .09)
      ..lineTo(peak.dx, peak.dy - 4)
      ..lineTo(peak.dx + s.width * .09, peak.dy + s.height * .09)
      ..lineTo(peak.dx + s.width * .05, peak.dy + s.height * .07)
      ..lineTo(peak.dx + s.width * .02, peak.dy + s.height * .1)
      ..lineTo(peak.dx - s.width * .03, peak.dy + s.height * .07)
      ..close();
    c.drawPath(cap, Paint()..color = const Color(0xFFF3E6F0));
    c.restore();
    c.drawPath(ridge(s, .84, .04, 61), Paint()..color = const Color(0xFF3B2B55));
    // Pagoda
    final px = s.width * .8, py = s.height * .84;
    final ink = Paint()..color = const Color(0xFF24183A);
    final unit = s.shortestSide * .045;
    for (var i = 0; i < 4; i++) {
      final w = unit * (4 - i * .7);
      final y = py - i * unit * 1.25;
      c.drawRect(Rect.fromCenter(center: Offset(px, y - unit * .35), width: w * .55, height: unit * .7), ink);
      final roof = Path()
        ..moveTo(px - w * .75, y - unit * .7)
        ..quadraticBezierTo(px, y - unit * 1.05, px + w * .75, y - unit * .7)
        ..lineTo(px + w * .45, y - unit * .95)
        ..lineTo(px - w * .45, y - unit * .95)
        ..close();
      c.drawPath(roof, ink);
    }
    c.drawLine(Offset(px, py - unit * 5.3), Offset(px, py - unit * 4.4), ink..strokeWidth = 2);
    c.drawRect(Rect.fromLTRB(0, py, s.width, s.height), Paint()..color = const Color(0xFF24183A));
  }

  @override
  void front(Canvas c, Size s) {
    // Sol üstten uzanan çiçekli dal
    final bark = Paint()
      ..color = const Color(0xFF2B1A24)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pts = <Offset>[];
    void branch(Offset a, Offset b, double w, int depth) {
      bark.strokeWidth = w;
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + w * 1.5);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
        bark,
      );
      pts.add(b);
      if (depth == 0) return;
      final d = b - a;
      branch(b, b + Offset(d.dx * .6, d.dy * .6 + d.distance * .15), w * .6, depth - 1);
      branch(b, b + Offset(d.dx * .45, -d.distance * .25), w * .55, depth - 1);
    }

    final u = s.shortestSide;
    branch(Offset(-u * .05, u * .05), Offset(u * .25, u * .16), u * .022, 3);
    final petal = Paint();
    for (final (i, p) in pts.indexed) {
      for (var k = 0; k < 9; k++) {
        final o = p + Offset((rnd(i * 9 + k, 71) - .5) * u * .09, (rnd(i * 9 + k, 72) - .5) * u * .06);
        petal.color = Color.lerp(const Color(0xFFF7C6D6), const Color(0xFFE88BAA), rnd(i * 9 + k, 73))!;
        c.drawCircle(o, u * (.008 + rnd(i * 9 + k, 74) * .01), petal);
      }
    }
  }

  @override
  void top(Canvas c, Size s, double t) {
    final p = Paint();
    for (var i = 0; i < 46; i++) {
      final life = 9 + rnd(i, 81) * 8;
      final ph = ((t + rnd(i, 82) * life) % life) / life;
      final x = s.width * (rnd(i, 83) * 1.1 - .05) + sin(ph * 7 + i) * 40 + ph * s.width * .15;
      final y = -20 + ph * (s.height + 40);
      p.color = Color.lerp(const Color(0xFFFAD0DD), const Color(0xFFF09AB5), rnd(i, 84))!.withValues(alpha: .9);
      c.save();
      c.translate(x, y);
      c.rotate(ph * 10 + i);
      final sz = 4 + rnd(i, 85) * 4;
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: sz * 1.6, height: sz * (.5 + .5 * cos(ph * 14 + i).abs())),
        p,
      );
      c.restore();
    }
  }
}

// ================================================================ 10. Kütüphane

class LibraryScene extends ScenePainter {
  const LibraryScene();

  Rect _window(Size s) {
    final w = min(s.width * .34, s.height * .42);
    return Rect.fromCenter(center: Offset(s.width / 2, s.height * .38), width: w, height: w * 1.35);
  }

  void _shelf(Canvas c, Rect r, int seed) {
    final wood = Paint()..color = const Color(0xFF3A2416);
    c.drawRect(r, Paint()..color = const Color(0xFF1C110B));
    final rowH = r.height / 5;
    const colors = [
      Color(0xFF7A2E2A),
      Color(0xFF2F5A4A),
      Color(0xFF8A6A3A),
      Color(0xFF34466E),
      Color(0xFF5E3A5A),
      Color(0xFFB08A5A),
    ];
    for (var row = 0; row < 5; row++) {
      final y0 = r.top + row * rowH;
      var x = r.left + 4;
      var k = 0;
      while (x < r.right - 6) {
        final bw = 6 + rnd(seed + row * 50 + k, 91) * 14;
        final bh = rowH * (.62 + rnd(seed + row * 50 + k, 92) * .3);
        final col = colors[(rnd(seed + row * 50 + k, 93) * colors.length).floor()];
        final book = Rect.fromLTWH(x, y0 + rowH - 6 - bh, min(bw, r.right - 6 - x), bh);
        c.drawRect(book, Paint()..color = col);
        c.drawRect(
          Rect.fromLTWH(book.left, book.top + bh * .15, book.width, 2),
          Paint()..color = const Color(0x55E8D2A0),
        );
        x += bw + 1;
        k++;
      }
      c.drawRect(Rect.fromLTWH(r.left, y0 + rowH - 6, r.width, 6), wood);
    }
    c.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = const Color(0xFF3A2416),
    );
  }

  @override
  void back(Canvas c, Size s) {
    fillGradient(c, Offset.zero & s, const [Color(0xFF2A1B12), Color(0xFF1E130C)]);
    final win = _window(s);
    // Raflar
    _shelf(c, Rect.fromLTRB(s.width * .02, s.height * .06, win.left - s.width * .06, s.height * .86), 1);
    _shelf(c, Rect.fromLTRB(win.right + s.width * .06, s.height * .06, s.width * .98, s.height * .86), 500);
    // Pencere: yağmurlu gece
    c.save();
    c.clipRRect(
      RRect.fromRectAndCorners(win, topLeft: Radius.circular(win.width / 2), topRight: Radius.circular(win.width / 2)),
    );
    fillGradient(c, win, const [Color(0xFF0E1A33), Color(0xFF243A5C)]);
    glow(
      c,
      Offset(win.left + win.width * .7, win.top + win.height * .3),
      win.width * .5,
      const Color(0xFFBFD0FF).withValues(alpha: .25),
    );
    c.drawCircle(
      Offset(win.left + win.width * .7, win.top + win.height * .3),
      win.width * .08,
      Paint()..color = const Color(0xFFE8EEF8),
    );
    c.drawPath(
      ridge(Size(win.width, win.height), .88, .05, 95).shift(win.topLeft),
      Paint()..color = const Color(0xFF0A1222),
    );
    c.restore();
    // Masa
    c.drawRect(Rect.fromLTRB(0, s.height * .86, s.width, s.height), Paint()..color = const Color(0xFF3E2618));
    c.drawRect(Rect.fromLTRB(0, s.height * .86, s.width, s.height * .875), Paint()..color = const Color(0xFF5A3A24));
  }

  @override
  void mid(Canvas c, Size s, double t) {
    final win = _window(s);
    c.save();
    c.clipRRect(
      RRect.fromRectAndCorners(win, topLeft: Radius.circular(win.width / 2), topRight: Radius.circular(win.width / 2)),
    );
    final p = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x55BFD0EE);
    for (var i = 0; i < 60; i++) {
      final speed = win.height * (1.2 + rnd(i, 101));
      final y = win.top + ((t * speed + rnd(i, 102) * win.height) % (win.height + 20)) - 10;
      final x = win.left + rnd(i, 103) * win.width;
      c.drawLine(Offset(x, y), Offset(x - 2, y + 12), p);
    }
    c.restore();
  }

  @override
  void front(Canvas c, Size s) {
    final win = _window(s);
    final frame = Paint()
      ..color = const Color(0xFF4A2E1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = win.width * .045;
    final shape = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          win,
          topLeft: Radius.circular(win.width / 2),
          topRight: Radius.circular(win.width / 2),
        ),
      );
    c.drawPath(shape, frame);
    final m = Paint()
      ..color = const Color(0xFF4A2E1C)
      ..strokeWidth = win.width * .025;
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), m);
    c.drawLine(Offset(win.left, win.top + win.height * .55), Offset(win.right, win.top + win.height * .55), m);
    // Masa lambası
    final lx = s.width * .2, ly = s.height * .86;
    final ink = Paint()..color = const Color(0xFF1A2E22);
    c.drawRect(Rect.fromCenter(center: Offset(lx, ly - 4), width: 50, height: 8), ink);
    c.drawLine(
      Offset(lx, ly - 6),
      Offset(lx + 18, ly - 70),
      Paint()
        ..color = const Color(0xFF1A2E22)
        ..strokeWidth = 5,
    );
    final shade = Path()
      ..moveTo(lx - 20, ly - 70)
      ..lineTo(lx + 56, ly - 70)
      ..lineTo(lx + 40, ly - 96)
      ..lineTo(lx - 4, ly - 96)
      ..close();
    c.drawPath(shade, Paint()..color = const Color(0xFF2E6B4A));
    // Masadaki kitap yığını
    for (var i = 0; i < 3; i++) {
      c.drawRect(
        Rect.fromLTWH(s.width * .68 + i * 6, ly - 14 - i * 14, 120 - i * 12, 13),
        Paint()..color = [const Color(0xFF7A2E2A), const Color(0xFF34466E), const Color(0xFF8A6A3A)][i],
      );
    }
  }

  @override
  void top(Canvas c, Size s, double t) {
    final lx = s.width * .2 + 18, ly = s.height * .86 - 70;
    // Lamba ışık konisi
    final cone = Path()
      ..moveTo(lx - 30, ly)
      ..lineTo(lx + 40, ly)
      ..lineTo(lx + s.width * .25, s.height * .86)
      ..lineTo(lx - s.width * .2, s.height * .86)
      ..close();
    c.drawPath(
      cone,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(Offset(lx, ly), Offset(lx, s.height * .86), [
          const Color(0x55FFC877),
          const Color(0x11FFC877),
        ]),
    );
    glow(c, Offset(lx + 5, ly + 4), 60, const Color(0xFFFFD08A).withValues(alpha: .6), blend: BlendMode.plus);
    // Işıkta süzülen toz zerreleri
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 40; i++) {
      final x = lx - s.width * .12 + rnd(i, 111) * s.width * .3 + sin(t * .3 + i) * 12;
      final y = ly + 20 + ((rnd(i, 112) * (s.height * .86 - ly - 20)) + sin(t * .25 + i * 2) * 18);
      final a = (.5 + .5 * sin(t * (.6 + rnd(i, 113)) + i)) * .6;
      p.color = const Color(0xFFFFE2A8).withValues(alpha: a);
      c.drawCircle(Offset(x, y), 1 + rnd(i, 114) * 1.2, p);
    }
  }
}

// ================================================================ 11. Uzay

class SpaceScene extends ScenePainter {
  const SpaceScene();

  Offset _planet(Size s) => Offset(s.width * .78, s.height * .72);
  double _pr(Size s) => s.shortestSide * .22;

  @override
  void back(Canvas c, Size s) {
    fillGradient(c, Offset.zero & s, const [Color(0xFF05060F), Color(0xFF0B0A1E)]);
    final neb = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, s.shortestSide * .12);
    for (final (o, r, col) in [
      (Offset(s.width * .25, s.height * .3), .35, const Color(0x557B4BD6)),
      (Offset(s.width * .45, s.height * .45), .25, const Color(0x403FB8C8)),
      (Offset(s.width * .15, s.height * .65), .22, const Color(0x35E86FA0)),
    ]) {
      c.drawCircle(o, s.shortestSide * r, neb..color = col);
    }
    final p = Paint();
    for (var i = 0; i < 260; i++) {
      p.color = Colors.white.withValues(alpha: .25 + rnd(i, 121) * .6);
      c.drawCircle(Offset(rnd(i, 122) * s.width, rnd(i, 123) * s.height), .4 + pow(rnd(i, 124), 3) * 1.8, p);
    }
  }

  @override
  void mid(Canvas c, Size s, double t) {
    // Göz kırpan parlak yıldızlar
    for (var i = 0; i < 18; i++) {
      final a = (.5 + .5 * sin(t * (.5 + rnd(i, 131)) + i * 2)).clamp(0.0, 1.0);
      final o = Offset(rnd(i, 132) * s.width, rnd(i, 133) * s.height * .6);
      glow(c, o, 8, Colors.white.withValues(alpha: .5 * a));
      c.drawCircle(o, 1.4, Paint()..color = Colors.white.withValues(alpha: a));
    }
    // Ara sıra geçen kuyruklu yıldız
    const period = 14.0;
    final ph = (t % period) / period;
    if (ph < .18) {
      final pr = ph / .18;
      final cycle = (t / period).floor();
      final start = Offset(s.width * (.1 + rnd(cycle, 134) * .4), s.height * (.05 + rnd(cycle, 135) * .2));
      final head = start + Offset(s.width * .45, s.height * .2) * pr;
      final tail = head - Offset(s.width * .12, s.height * .055);
      c.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(tail, head, [
            const Color(0x00A0E8FF),
            Color(0xFFDDF6FF).withValues(alpha: 1 - pr),
          ]),
      );
    }
  }

  void _rings(Canvas c, Size s, {required bool frontHalf}) {
    final pc = _planet(s), r = _pr(s);
    final rect = Rect.fromCenter(center: pc, width: r * 3.6, height: r * .9);
    c.save();
    c.translate(pc.dx, pc.dy);
    c.rotate(-.28);
    c.translate(-pc.dx, -pc.dy);
    c.clipRect(
      frontHalf
          ? Rect.fromLTRB(rect.left - 10, pc.dy, rect.right + 10, rect.bottom + 10)
          : Rect.fromLTRB(rect.left - 10, rect.top - 10, rect.right + 10, pc.dy),
    );
    for (var k = 0; k < 4; k++) {
      c.drawOval(
        rect.deflate(k * r * .07),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .05
          ..color = [
            const Color(0x99E8C9A0),
            const Color(0x66C9A27A),
            const Color(0x88F0DDBF),
            const Color(0x55B08A6A),
          ][k],
      );
    }
    c.restore();
  }

  @override
  void top(Canvas c, Size s, double t) {
    final pc = _planet(s), r = _pr(s);
    _rings(c, s, frontHalf: false);
    // Gezegen: yavaşça kayan bulut bantları
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: pc, radius: r)));
    c.drawCircle(pc, r, Paint()..color = const Color(0xFFB0705A));
    for (var k = 0; k < 9; k++) {
      final y = pc.dy - r + k * r * .24;
      final shift = (t * (6 + k * 1.5)) % (r * 2);
      final band = Paint()
        ..color = [
          const Color(0xFFD49A6E),
          const Color(0xFF9A5A48),
          const Color(0xFFE8BC8A),
        ][k % 3].withValues(alpha: .55);
      for (var j = -1; j < 2; j++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pc.dx - r * 2 + shift + j * r * 2, y, r * 1.6, r * .12),
            Radius.circular(r * .06),
          ),
          band,
        );
      }
    }
    // Gölge
    c.drawCircle(
      pc,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          pc + Offset(-r * .5, -r * .5),
          r * 2,
          [const Color(0x00000000), const Color(0xCC05060F)],
          const [.35, 1],
        ),
    );
    c.restore();
    _rings(c, s, frontHalf: true);
    // Yörüngedeki küçük ay
    final a = t * .15;
    final mo = pc + Offset(cos(a) * r * 2.3, sin(a) * r * .7);
    final behind = sin(a) < 0;
    if (!behind || (mo - pc).distance > r) {
      c.drawCircle(mo, r * .09, Paint()..color = const Color(0xFFD8D8E0));
    }
  }

  @override
  bool get hasFront => false;
}

// ================================================================ 12. Su altı

class UnderwaterScene extends ScenePainter {
  const UnderwaterScene();

  @override
  void back(Canvas c, Size s) {
    fillGradient(
      c,
      Offset.zero & s,
      const [Color(0xFF2B8CA6), Color(0xFF155A78), Color(0xFF07263C)],
      stops: const [0, .45, 1],
    );
  }

  @override
  void mid(Canvas c, Size s, double t) {
    // Yüzeyden süzülen ışık huzmeleri
    for (var i = 0; i < 7; i++) {
      final x = s.width * (rnd(i, 141) * 1.2 - .1) + sin(t * .2 + i) * 30;
      final w = s.width * (.04 + rnd(i, 142) * .06);
      final a = .10 + .06 * sin(t * .5 + i * 2);
      final ray = Path()
        ..moveTo(x - w / 2, 0)
        ..lineTo(x + w / 2, 0)
        ..lineTo(x + w * 2.5 + s.width * .1, s.height)
        ..lineTo(x - w * .5 + s.width * .1, s.height)
        ..close();
      c.drawPath(
        ray,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(Offset(x, 0), Offset(x, s.height), [
            Colors.white.withValues(alpha: a),
            Colors.white.withValues(alpha: 0),
          ]),
      );
    }
    // Uzaktan yüzen balık sürüsü
    final p = Paint()..color = const Color(0xFF0E3A52).withValues(alpha: .8);
    for (var i = 0; i < 14; i++) {
      const period = 40.0;
      final ph = ((t + rnd(i, 143) * 4) % period) / period;
      final x = -40 + ph * (s.width + 80) + rnd(i, 144) * 60;
      final y = s.height * (.35 + rnd(i, 145) * .2) + sin(t * .8 + i) * 8;
      final sz = 7 + rnd(i, 146) * 5;
      final body = Path()
        ..moveTo(x + sz, y)
        ..quadraticBezierTo(x, y - sz * .5, x - sz, y)
        ..quadraticBezierTo(x, y + sz * .5, x + sz, y)
        ..moveTo(x - sz * .8, y)
        ..lineTo(x - sz * 1.5, y - sz * .45)
        ..lineTo(x - sz * 1.5, y + sz * .45)
        ..close();
      c.drawPath(body, p);
    }
  }

  @override
  void front(Canvas c, Size s) {
    final sand = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width + 10; x += 10) {
      sand.lineTo(x, s.height * (.88 + .03 * sin(x / s.width * 5 + 1) + .01 * sin(x / 40)));
    }
    sand
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(sand, Paint()..color = const Color(0xFF3A4A44));
    for (var i = 0; i < 8; i++) {
      final x = rnd(i, 151) * s.width;
      final r = s.shortestSide * (.03 + rnd(i, 152) * .05);
      c.drawOval(
        Rect.fromCenter(center: Offset(x, s.height * .9), width: r * 2.4, height: r * 1.4),
        Paint()..color = const Color(0xFF26343A),
      );
    }
  }

  @override
  void top(Canvas c, Size s, double t) {
    // Sallanan yosunlar
    for (var i = 0; i < 12; i++) {
      final x0 = (i + rnd(i, 161) * .7) / 12 * s.width;
      final h = s.height * (.2 + rnd(i, 162) * .25);
      final path = Path()..moveTo(x0, s.height * .92);
      const seg = 12;
      for (var k = 1; k <= seg; k++) {
        final f = k / seg;
        path.lineTo(x0 + sin(t * .8 + i + f * 3) * 16 * f, s.height * .92 - h * f);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5 + rnd(i, 163) * 4
          ..color = Color.lerp(const Color(0xFF1F5A3A), const Color(0xFF3E8A4A), rnd(i, 164))!,
      );
    }
    // Yükselen kabarcıklar
    final b = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 30; i++) {
      final life = 6 + rnd(i, 171) * 6;
      final ph = ((t + rnd(i, 172) * life) % life) / life;
      final x = rnd(i, 173) * s.width + sin(ph * 12 + i) * 6;
      final y = s.height * .92 * (1 - ph);
      b.color = Colors.white.withValues(alpha: .5 * (1 - ph));
      c.drawCircle(Offset(x, y), 2 + rnd(i, 174) * 4, b);
    }
  }
}

// ================================================================ 13. Lavanta tarlası

class LavenderScene extends ScenePainter {
  const LavenderScene();

  double _horizon(Size s) => s.height * .52;

  @override
  void back(Canvas c, Size s) {
    final hz = _horizon(s);
    fillGradient(
      c,
      Rect.fromLTWH(0, 0, s.width, hz),
      const [Color(0xFF3A3A72), Color(0xFF9A6FB0), Color(0xFFE79A9A), Color(0xFFF7C88E)],
      stops: const [0, .45, .8, 1],
    );
    final sun = Offset(s.width * .3, hz - s.height * .03);
    glow(c, sun, s.shortestSide * .5, const Color(0xFFFFD9A0).withValues(alpha: .55));
    c.drawCircle(sun, s.shortestSide * .05, Paint()..color = const Color(0xFFFFF0CF));
    c.drawPath(ridge(Size(s.width, hz), .93, .06, 181), Paint()..color = const Color(0xFF6E5A8E));
    // Ufuktaki yalnız ağaç
    final tx = s.width * .72, ty = hz;
    final ink = Paint()..color = const Color(0xFF3A2D52);
    c.drawRect(Rect.fromLTWH(tx - 3, ty - s.height * .06, 6, s.height * .06), ink);
    for (final (dx, dy, r) in [(0.0, -.08, .045), (-.03, -.065, .035), (.03, -.066, .033)]) {
      c.drawCircle(Offset(tx + s.width * dx, ty + s.height * dy), s.shortestSide * r, ink);
    }
    // Tarla zemini
    fillGradient(c, Rect.fromLTRB(0, hz, s.width, s.height), const [Color(0xFF6A4E8A), Color(0xFF3E2A5A)]);
    // Ufka doğru daralan lavanta sıraları: her sırada kümelenmiş, hafif dağınık saplar
    final vp = Offset(s.width * .5, hz);
    final stem = Paint()..strokeCap = StrokeCap.round;
    for (var r = -14; r <= 14; r++) {
      final bx = s.width * .5 + r * s.width * .09;
      for (var k = 0; k < 110; k++) {
        final f = pow(k / 110, 1.7).toDouble();
        final base = Offset.lerp(vp, Offset(bx, s.height * 1.05), f)!;
        final spread = 2 + f * 22;
        final p = base + Offset((rnd(r * 1000 + k, 184) - .5) * spread, (rnd(r * 1000 + k, 185) - .5) * spread * .3);
        if (p.dx < -10 || p.dx > s.width + 10) continue;
        final h = (4 + f * 28) * (.7 + rnd(r * 1000 + k, 186) * .6);
        final lean = (rnd(r * 1000 + k, 187) - .5) * h * .25;
        stem
          ..strokeWidth = .8 + f * 4.5
          ..color = Color.lerp(
            const Color(0xFF7E62B4),
            const Color(0xFFC09BEA),
            rnd(r * 100 + k, 182),
          )!.withValues(alpha: .65 + f * .3);
        c.drawLine(p, p + Offset(lean, -h), stem);
      }
    }
  }

  @override
  void mid(Canvas c, Size s, double t) {
    for (var i = 0; i < 4; i++) {
      final w = s.width * (.25 + rnd(i, 191) * .2);
      final span = s.width + w * 2;
      final x = (rnd(i, 192) * span + t * (5 + i * 2)) % span - w;
      final y = s.height * (.08 + rnd(i, 193) * .22);
      for (var j = 0; j < 4; j++) {
        final o = Offset(x + j * w * .22, y + (j.isOdd ? -w * .03 : 0));
        final r = w * .17;
        c.drawCircle(
          o,
          r,
          Paint()..shader = ui.Gradient.radial(o, r, [const Color(0x55FFE6E0), const Color(0x00FFE6E0)]),
        );
      }
    }
  }

  @override
  bool get hasFront => false;

  @override
  void top(Canvas c, Size s, double t) {
    final hz = _horizon(s);
    final g = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 30; i++) {
      final x = (rnd(i, 201) * s.width + sin(t * .2 + i) * 30) % s.width;
      final y = hz + (s.height - hz) * (.1 + rnd(i, 202) * .8) + sin(t * .4 + i * 2) * 14;
      final a = (.5 + .5 * sin(t * (1 + rnd(i, 203)) + i * 3)).clamp(0.0, 1.0);
      g.color = const Color(0xFFFFE9A8).withValues(alpha: a * .8);
      c.drawCircle(Offset(x, y), 2.5, g);
    }
  }
}

// ================================================================ 14-18. Kasaba: hava durumu sahneleri

/// Ortak kasaba çizimi: tepeler, evler ve ağaçlar. Hava durumuna göre renkler,
/// efektler ve fırtınada sallanma değişir.
abstract class VillageScene extends ScenePainter {
  const VillageScene();

  List<Color> get sky;
  Color get hillFar;
  Color get hillNear;
  Color get wall;
  Color get roof;
  Color get windowColor;
  bool get litWindows => false;
  bool get snowy => false;

  /// Evlerin ve ağaçların sallanma genliği (radyan). Fırtınada büyük, diğerlerinde 0.
  double get sway => 0;

  double ground(Size s) => s.height * .78;

  @override
  void back(Canvas c, Size s) {
    fillGradient(c, Offset.zero & s, sky, stops: const [0, .55, 1]);
    c.drawPath(ridge(s, .70, .06, 301), Paint()..color = hillFar);
  }

  /// Gökyüzü ile kasaba arasındaki hareketli katman (bulutlar, güneş, sis...).
  void skyLayer(Canvas c, Size s, double t) {}

  /// Kasabanın önündeki hareketli katman (yağış, şimşek...).
  void weather(Canvas c, Size s, double t) {}

  @override
  bool get hasFront => false;

  @override
  void mid(Canvas c, Size s, double t) {
    skyLayer(c, s, t);
    final g = ground(s);
    // Yakın tepe ve zemin
    final near = Path()..moveTo(0, g);
    for (double x = 0; x <= s.width + 8; x += 8) {
      near.lineTo(x, g - s.height * .025 * sin(x / s.width * 3 + .7));
    }
    near
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(near, Paint()..color = hillNear);
    if (snowy) {
      final cap = Path()..moveTo(0, g);
      for (double x = 0; x <= s.width + 8; x += 8) {
        cap.lineTo(x, g - s.height * .025 * sin(x / s.width * 3 + .7));
      }
      for (double x = s.width; x >= 0; x -= 8) {
        cap.lineTo(x, g - s.height * .025 * sin(x / s.width * 3 + .7) + s.height * .05);
      }
      cap.close();
      c.drawPath(cap, Paint()..color = const Color(0xFFEFF4FA));
    }
    // Ağaçlar ve evler (soldan sağa)
    final u = s.shortestSide;
    final items = <(double, bool, double)>[]; // (x oranı, ev mi, boyut)
    for (var i = 0; i < 11; i++) {
      final x = (i + .2 + rnd(i, 311) * .6) / 11;
      final house = rnd(i, 312) > .38;
      items.add((x, house, .8 + rnd(i, 313) * .5));
    }
    for (final (i, (fx, house, size)) in items.indexed) {
      final x = fx * s.width;
      final baseY = g - s.height * .025 * sin(fx * 3 + .7) + 2;
      final a = sway * sin(t * (2.6 + rnd(i, 314)) + i) + sway * .5 * sin(t * 7.3 + i * 2);
      if (house) {
        _house(c, Offset(x, baseY), u * .11 * size, u * .085 * size, a * .25, i, t);
      } else {
        _tree(c, Offset(x, baseY), u * .14 * size, a, i);
      }
    }
    weather(c, s, t);
  }

  void _house(Canvas c, Offset base, double w, double h, double angle, int i, double t) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
    final wallP = Paint()..color = Color.lerp(wall, const Color(0xFF000000), rnd(i, 321) * .15)!;
    c.drawRect(Rect.fromLTWH(-w / 2, -h, w, h), wallP);
    final roofPath = Path()
      ..moveTo(-w * .62, -h)
      ..lineTo(0, -h - h * .65)
      ..lineTo(w * .62, -h)
      ..close();
    // Baca ve duman
    c.drawRect(Rect.fromLTWH(w * .18, -h - h * .62, w * .12, h * .35), Paint()..color = roof);
    c.drawPath(roofPath, Paint()..color = Color.lerp(roof, const Color(0xFF000000), rnd(i, 322) * .2)!);
    if (snowy) {
      final cap = Path()
        ..moveTo(-w * .62, -h)
        ..lineTo(0, -h - h * .65)
        ..lineTo(w * .62, -h)
        ..lineTo(w * .5, -h + h * .06)
        ..lineTo(0, -h - h * .5)
        ..lineTo(-w * .5, -h + h * .06)
        ..close();
      c.drawPath(cap, Paint()..color = const Color(0xFFF2F6FB));
      // Bacadan duman
      final smoke = Paint();
      for (var k = 0; k < 5; k++) {
        final ph = ((t * .25 + k / 5 + rnd(i, 323)) % 1);
        smoke.color = const Color(0xFFDDE3EC).withValues(alpha: (1 - ph) * .35);
        c.drawCircle(
          Offset(w * .24 + sin(ph * 4 + i) * w * .1 + ph * w * .3, -h - h * .65 - ph * h * 1.4),
          w * (.05 + ph * .1),
          smoke,
        );
      }
    }
    // Pencereler ve kapı
    final win = Paint()..color = windowColor;
    final ws = w * .2;
    c.drawRect(Rect.fromLTWH(-w * .36, -h * .78, ws, ws), win);
    c.drawRect(Rect.fromLTWH(w * .16, -h * .78, ws, ws), win);
    if (litWindows) {
      final flick = .8 + .2 * sin(t * 1.5 + i * 3);
      glow(
        c,
        Offset(-w * .26, -h * .68),
        ws * 2.2,
        const Color(0xFFFFC56B).withValues(alpha: .35 * flick),
        blend: BlendMode.plus,
      );
      glow(
        c,
        Offset(w * .26, -h * .68),
        ws * 2.2,
        const Color(0xFFFFC56B).withValues(alpha: .35 * flick),
        blend: BlendMode.plus,
      );
    }
    c.drawRect(
      Rect.fromLTWH(-w * .1, -h * .45, w * .2, h * .45),
      Paint()..color = Color.lerp(roof, const Color(0xFF000000), .35)!,
    );
    c.restore();
  }

  void _tree(Canvas c, Offset base, double h, double angle, int i) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
    c.drawRect(Rect.fromLTWH(-h * .04, -h * .45, h * .08, h * .45), Paint()..color = const Color(0xFF4A3426));
    final crown = Color.lerp(hillNear, const Color(0xFF000000), .25)!;
    for (final (dx, dy, r) in [(0.0, -.62, .26), (-.14, -.5, .18), (.14, -.5, .18)]) {
      c.drawCircle(Offset(h * dx, h * dy), h * r, Paint()..color = crown);
    }
    if (snowy) {
      c.drawCircle(Offset(0, -h * .78), h * .14, Paint()..color = const Color(0xFFEFF4FA));
    }
    c.restore();
  }
}

// --- 14. Sisli kasaba
class FoggyScene extends VillageScene {
  const FoggyScene();
  @override
  List<Color> get sky => const [Color(0xFF8E9BA6), Color(0xFFB7C1C8), Color(0xFFCDD3D6)];
  @override
  Color get hillFar => const Color(0xFF9DA8AF);
  @override
  Color get hillNear => const Color(0xFF6D7B79);
  @override
  Color get wall => const Color(0xFF8A8F95);
  @override
  Color get roof => const Color(0xFF5E5A63);
  @override
  Color get windowColor => const Color(0xFFE7D9A8);
  @override
  bool get litWindows => true;

  void _fog(Canvas c, Size s, double t, double y, double alpha, double speed, int seed) {
    for (var i = 0; i < 5; i++) {
      final w = s.width * (.7 + rnd(i, seed) * .6);
      final span = s.width + w;
      final x = (rnd(i, seed + 1) * span + t * speed * (1 + i * .25)) % span - w / 2;
      final center = Offset(x, s.height * (y + (rnd(i, seed + 2) - .5) * .08));
      c.drawOval(
        Rect.fromCenter(center: center, width: w, height: s.height * .18),
        Paint()
          ..shader = ui.Gradient.radial(center, w / 2, [
            Color(0xFFE6EBEE).withValues(alpha: alpha),
            const Color(0x00E6EBEE),
          ]),
      );
    }
  }

  @override
  void skyLayer(Canvas c, Size s, double t) => _fog(c, s, t, .62, .55, 7, 401);

  @override
  void weather(Canvas c, Size s, double t) {
    // Sokak lambaları
    for (var i = 0; i < 4; i++) {
      final x = s.width * (.12 + i * .26);
      final y = ground(s) + s.height * .02;
      final lamp = Paint()..color = const Color(0xFF3E4448);
      c.drawRect(Rect.fromLTWH(x - 2, y - s.height * .14, 4, s.height * .14), lamp);
      glow(
        c,
        Offset(x, y - s.height * .145),
        s.shortestSide * .08,
        const Color(0xFFFFE2A0).withValues(alpha: .55),
        blend: BlendMode.plus,
      );
      c.drawCircle(Offset(x, y - s.height * .145), 5, Paint()..color = const Color(0xFFFFF1C8));
    }
    _fog(c, s, t, .86, .5, 4, 411);
  }
}

// --- 16. Güneşli gün
class SunnyScene extends VillageScene {
  const SunnyScene();
  @override
  List<Color> get sky => const [Color(0xFF2F7FD0), Color(0xFF6FB3EA), Color(0xFFBFE2F7)];
  @override
  Color get hillFar => const Color(0xFF7FBF6A);
  @override
  Color get hillNear => const Color(0xFF5AA24E);
  @override
  Color get wall => const Color(0xFFF2E6D0);
  @override
  Color get roof => const Color(0xFFC6483A);
  @override
  Color get windowColor => const Color(0xFF6FA8D6);

  @override
  void skyLayer(Canvas c, Size s, double t) {
    // Dönen ışınlarıyla güneş
    final sun = Offset(s.width * .8, s.height * .18);
    final r = s.shortestSide * .07;
    glow(c, sun, r * 6, const Color(0xFFFFF2B0).withValues(alpha: .55));
    c.save();
    c.translate(sun.dx, sun.dy);
    c.rotate(t * .08);
    final ray = Paint()
      ..color = const Color(0xFFFFE680).withValues(alpha: .55)
      ..strokeWidth = r * .14
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 12; k++) {
      final a = k / 12 * 2 * pi;
      final pulse = 1 + .12 * sin(t * 2 + k);
      c.drawLine(Offset(cos(a), sin(a)) * r * 1.35, Offset(cos(a), sin(a)) * r * 1.9 * pulse, ray);
    }
    c.restore();
    c.drawCircle(sun, r, Paint()..color = const Color(0xFFFFE066));
    // Kayan bulutlar
    for (var i = 0; i < 5; i++) {
      final w = s.width * (.16 + rnd(i, 431) * .14);
      final span = s.width + w * 2;
      final x = (rnd(i, 432) * span + t * (8 + i * 3)) % span - w;
      final y = s.height * (.1 + rnd(i, 433) * .3);
      final cp = Paint()..color = Colors.white.withValues(alpha: .92);
      for (final (dx, dy, rr) in [(0.0, 0.0, .22), (.22, -.08, .26), (.46, 0.0, .2), (.24, .06, .22)]) {
        c.drawCircle(Offset(x + w * dx, y + w * dy), w * rr, cp);
      }
    }
  }

  @override
  void weather(Canvas c, Size s, double t) {
    // Uçan kuşlar
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B3A4A);
    for (var i = 0; i < 4; i++) {
      final ph = ((t + i * 6) % 26) / 26;
      final x = -40 + ph * (s.width + 80);
      final y = s.height * (.3 + i * .04) + sin(t * .8 + i) * 10;
      final f = sin(t * 7 + i) * 5;
      c.drawPath(
        Path()
          ..moveTo(x - 8, y - f)
          ..quadraticBezierTo(x - 3, y - 3, x, y)
          ..quadraticBezierTo(x + 3, y - 3, x + 8, y - f),
        p,
      );
    }
  }
}

// --- 17. Dolu yağışı: koyu bulutlar, buz tanecikleri, sıçrayan ve biriken dolu
class HailScene extends VillageScene {
  const HailScene();
  @override
  List<Color> get sky => const [Color(0xFF1F2A30), Color(0xFF3F5052), Color(0xFF6C7D76)];
  @override
  Color get hillFar => const Color(0xFF44544F);
  @override
  Color get hillNear => const Color(0xFF34463E);
  @override
  Color get wall => const Color(0xFF8C8A84);
  @override
  Color get roof => const Color(0xFF4E3E3A);
  @override
  Color get windowColor => const Color(0xFFF0DCA0);
  @override
  bool get litWindows => true;
  @override
  double get sway => .012;

  @override
  void skyLayer(Canvas c, Size s, double t) {
    // Uzakta sessizce çakan, bulutların içini aydınlatan ışık
    final ph = t % 11;
    final flash = ph < .5 ? sin(ph / .5 * pi) * .35 : 0.0;
    // Ağır ağır akan, kabarık koyu bulutlar
    for (var i = 0; i < 9; i++) {
      final w = s.width * (.35 + rnd(i, 451) * .3);
      final span = s.width + w;
      final x = (rnd(i, 452) * span + t * (6 + rnd(i, 453) * 6)) % span - w / 2;
      final y = s.height * (.04 + rnd(i, 454) * .3);
      final center = Offset(x, y);
      final base = Color.lerp(const Color(0xFF1A2226), const Color(0xFF55646A), rnd(i, 455))!;
      final lit = Color.lerp(base, const Color(0xFFDCE6F0), flash * (1 - y / s.height))!;
      c.drawOval(
        Rect.fromCenter(center: center, width: w, height: w * .42),
        Paint()..shader = ui.Gradient.radial(center, w / 2, [lit.withValues(alpha: .85), lit.withValues(alpha: 0)]),
      );
    }
  }

  @override
  void weather(Canvas c, Size s, double t) {
    final g = ground(s);
    final u = s.shortestSide;
    // Zeminde biriken beyaz dolu tabakası
    c.drawRect(
      Rect.fromLTWH(0, g + s.height * .01, s.width, s.height - g),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, g), Offset(0, s.height),
            const [Color(0x00E8EEF0), Color(0x88E8EEF0), Color(0xAAD8E0E4)], const [0, .25, 1]),
    );
    final pile = Paint();
    for (var i = 0; i < 260; i++) {
      final y = g + s.height * (.015 + rnd(i, 448) * .22);
      final depth = (y - g) / (s.height - g);
      pile.color = Color.lerp(const Color(0xFFC9D3D8), Colors.white, rnd(i, 449))!.withValues(alpha: .8);
      c.drawCircle(Offset(rnd(i, 447) * s.width, y), u * (.002 + depth * .005), pile);
    }
    // Pencerelerin ışığını yansıtan su birikintileri
    for (var i = 0; i < 4; i++) {
      final center = Offset(s.width * (.15 + i * .24 + rnd(i, 456) * .05), g + s.height * (.08 + rnd(i, 457) * .1));
      final w = u * (.16 + rnd(i, 458) * .1);
      final r = Rect.fromCenter(center: center, width: w, height: w * .18);
      c.drawOval(r, Paint()..color = const Color(0xFF2C3A3E));
      c.drawOval(r.deflate(w * .02), Paint()..shader = ui.Gradient.radial(center, w * .5, [const Color(0x55F0DCA0), const Color(0x002C3A3E)]));
      // Birikintiye düşen tanelerin halkaları
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var k = 0; k < 3; k++) {
        final ph = ((t * 1.3 + rnd(i * 3 + k, 459)) % 1);
        final rc = center + Offset((rnd(i * 3 + k, 460) - .5) * w * .6, 0);
        ring.color = Colors.white.withValues(alpha: (1 - ph) * .5);
        c.drawOval(Rect.fromCenter(center: rc, width: w * .25 * ph + 2, height: w * .05 * ph + 1), ring);
      }
    }
    hailFall(c, s, t, g + s.height * .01, g + s.height * .21);
  }
}

/// Düşen buz taneleri: hafif eğik, hız izli; [landTop]..[landBottom] arasında yere çarpıp seker.
void hailFall(Canvas c, Size s, double t, double landTop, double landBottom) {
  final u = s.shortestSide;
  // Düşen buz taneleri: hafif eğik, hız izli; yere çarpınca sekip parlıyor
  final n = (s.width * s.height / 4200).clamp(90, 300).toInt();
  final streak = Paint()..strokeCap = StrokeCap.round;
  final bead = Paint();
  const slant = .22;
  for (var i = 0; i < n; i++) {
    final depth = rnd(i, 441);
    final r = u * (.0025 + depth * .0045);
    final speed = s.height * (1.1 + depth * 1.0);
    final land = landTop + (landBottom - landTop) * depth;
    final fallT = (land + 40) / speed;
    const bounceT = .45;
    final period = fallT + bounceT + rnd(i, 442) * .4;
    final ph = (t + rnd(i, 443) * period) % period;
    final x0 = rnd(i, 444) * (s.width + 200);
    if (ph < fallT) {
      final y = -40 + ph * speed;
      final x = x0 - (y + 40) * slant;
      final len = r * 7;
      final head = Offset(x, y);
      final tail = head - Offset(-slant, 1) * len;
      streak
        ..strokeWidth = r * 1.1
        ..shader = ui.Gradient.linear(tail, head, [const Color(0x00FFFFFF), Colors.white.withValues(alpha: .5 + depth * .3)]);
      c.drawLine(tail, head, streak);
      bead.color = const Color(0xFFF4F9FC).withValues(alpha: .7 + depth * .3);
      c.drawCircle(head, r, bead);
    } else if (ph < fallT + bounceT) {
      final b = (ph - fallT) / bounceT;
      final xl = x0 - (land + 40) * slant;
      final dir = rnd(i, 445) - .5;
      final h = s.height * (.012 + depth * .03) * (1 - b * .4);
      final p = Offset(xl + dir * b * u * .06, land - sin(b * pi) * h);
      if (b < .15) {
        // Çarpma anında küçük buz kıvılcımı
        final sp = Paint()
          ..color = Colors.white.withValues(alpha: (1 - b / .15) * .8)
          ..strokeWidth = 1;
        for (var k = 0; k < 4; k++) {
          final a = -pi * (.15 + k * .23);
          c.drawLine(Offset(xl, land), Offset(xl, land) + Offset(cos(a), sin(a)) * r * (2 + b * 20), sp);
        }
      }
      bead.color = const Color(0xFFEAF2F6).withValues(alpha: .85 * (1 - b * .3));
      c.drawCircle(p, r * .9, bead);
    }
  }
}

// --- 18. Fırtına: sallanan evler ve ağaçlar, şimşek, eğik sağanak
class StormScene extends VillageScene {
  const StormScene();
  @override
  List<Color> get sky => const [Color(0xFF0E1218), Color(0xFF1E2630), Color(0xFF34404A)];
  @override
  Color get hillFar => const Color(0xFF232C34);
  @override
  Color get hillNear => const Color(0xFF1C2A26);
  @override
  Color get wall => const Color(0xFF5E6268);
  @override
  Color get roof => const Color(0xFF33282A);
  @override
  Color get windowColor => const Color(0xFFE8C77A);
  @override
  bool get litWindows => true;
  @override
  double get sway => .09;

  double _flash(double t) {
    // Yaklaşık 7 saniyede bir çift şimşek
    const period = 7.0;
    final ph = t % period;
    if (ph < .12) return 1 - ph / .12;
    if (ph > .25 && ph < .33) return (1 - (ph - .25) / .08) * .7;
    return 0;
  }

  @override
  void skyLayer(Canvas c, Size s, double t) {
    // Hızla geçen kara bulutlar
    for (var i = 0; i < 7; i++) {
      final w = s.width * (.35 + rnd(i, 451) * .3);
      final span = s.width + w * 2;
      final x = (rnd(i, 452) * span + t * (40 + i * 12)) % span - w;
      final y = s.height * (.05 + rnd(i, 453) * .3);
      final cp = Paint()..color = const Color(0xFF151B22).withValues(alpha: .85);
      for (final (dx, dy, rr) in [(0.0, 0.0, .2), (.2, -.07, .24), (.42, 0.0, .2), (.22, .06, .22)]) {
        c.drawCircle(Offset(x + w * dx, y + w * dy), w * rr, cp);
      }
    }
    // Şimşek
    final f = _flash(t);
    if (f > 0) {
      final cycle = (t / 7).floor();
      var p = Offset(s.width * (.2 + rnd(cycle, 454) * .6), 0);
      final bolt = Path()..moveTo(p.dx, p.dy);
      for (var k = 0; k < 9; k++) {
        p = p + Offset((rnd(cycle * 20 + k, 455) - .5) * s.width * .08, s.height * .07);
        bolt.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        bolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFEAF2FF).withValues(alpha: f)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
      );
    }
  }

  @override
  void weather(Canvas c, Size s, double t) {
    // Rüzgârla iyice eğilmiş sağanak
    const slant = .45;
    final p = Paint()..strokeCap = StrokeCap.round;
    final n = (s.width * s.height / 3600).clamp(120, 360).toInt();
    for (var i = 0; i < n; i++) {
      final depth = rnd(i, 461);
      final speed = s.height * (1.8 + depth * 1.6);
      final len = 18 + depth * 30;
      final travel = s.height + len + s.height * slant;
      final y = ((t * speed + rnd(i, 462) * travel) % travel) - len;
      final x = rnd(i, 463) * (s.width + s.height * slant) - y * slant;
      p
        ..strokeWidth = .8 + depth * 1.4
        ..color = const Color(0xFFB8C6D8).withValues(alpha: .2 + depth * .35);
      c.drawLine(Offset(x, y), Offset(x - len * slant, y + len), p);
    }
    // Uçuşan yapraklar
    final leaf = Paint()..color = const Color(0xFF6E8A4E).withValues(alpha: .7);
    for (var i = 0; i < 14; i++) {
      final life = 3 + rnd(i, 464) * 2;
      final ph = ((t + rnd(i, 465) * life) % life) / life;
      final x = s.width * (1.1 - ph * 1.3);
      final y = s.height * (.4 + rnd(i, 466) * .4) + sin(ph * 12 + i) * 30;
      c.save();
      c.translate(x, y);
      c.rotate(ph * 20 + i);
      c.drawOval(const Rect.fromLTWH(-5, -2.5, 10, 5), leaf);
      c.restore();
    }
    // Şimşek aydınlatması
    final f = _flash(t);
    if (f > 0) c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFDDE8FF).withValues(alpha: .28 * f));
  }
}

// --- 15. Kar yağışı: ay ışığında sessiz bir çam ormanı, katman katman süzülen kar
class SnowfallScene extends ScenePainter {
  const SnowfallScene();

  static const _moon = Offset(.72, .2);

  /// Dallarına kar yığılmış çam.
  static void snowyPine(Canvas c, double x, double baseY, double h, Color tree, Color snow) {
    c.drawPath(pine(x, baseY, h), Paint()..color = tree);
    final w = h * .38;
    const tiers = 5;
    final sp = Paint()..color = snow;
    for (var i = 0; i < tiers; i++) {
      final ty = baseY - h * (i / tiers) * .92;
      final tw = w * (1 - i / tiers * .75);
      final top = max(baseY - h * ((i + 1.6) / tiers) * .92, baseY - h);
      final cy = top + (ty - top) * .42;
      final cw = tw * .42 * .5;
      final p = Path()
        ..moveTo(x, top)
        ..lineTo(x + cw * 1.1, cy)
        ..quadraticBezierTo(x + cw * .6, cy + h * .018, x + cw * .25, cy - h * .004)
        ..quadraticBezierTo(x, cy + h * .02, x - cw * .3, cy)
        ..quadraticBezierTo(x - cw * .7, cy + h * .016, x - cw * 1.1, cy)
        ..close();
      c.drawPath(p, sp);
      // Dal uçlarında küçük kar yastıkları
      c.drawOval(Rect.fromCenter(center: Offset(x - tw * .4, ty - h * .006), width: tw * .22, height: h * .016), sp);
      c.drawOval(Rect.fromCenter(center: Offset(x + tw * .4, ty - h * .006), width: tw * .22, height: h * .016), sp);
    }
  }

  @override
  void back(Canvas c, Size s) {
    fillGradient(c, Offset.zero & s, const [Color(0xFF0E1730), Color(0xFF22345A), Color(0xFF51668F)],
        stops: const [0, .55, 1]);
    final moon = Offset(s.width * _moon.dx, s.height * _moon.dy);
    final u = s.shortestSide;
    glow(c, moon, u * .55, const Color(0xFFBFD3F2).withValues(alpha: .22));
    glow(c, moon, u * .16, const Color(0xFFE8F0FF).withValues(alpha: .45));
    c.drawCircle(moon, u * .045, Paint()..color = const Color(0xFFF4F7FF));
    final star = Paint();
    for (var i = 0; i < 70; i++) {
      final p = Offset(rnd(i, 501) * s.width, rnd(i, 502) * s.height * .45);
      if ((p - moon).distance < u * .25) continue;
      star.color = Colors.white.withValues(alpha: .15 + rnd(i, 503) * .35);
      c.drawCircle(p, .6 + rnd(i, 504) * .8, star);
    }
    // Uzak, sisli tepeler ve ormanlar
    c.drawPath(ridge(s, .62, .05, 511), Paint()..color = const Color(0xFF7A8EB4));
    for (var i = 0; i < 46; i++) {
      final x = rnd(i, 512) * s.width;
      final y = s.height * (.66 + rnd(i, 513) * .04);
      c.drawPath(pine(x, y, u * (.08 + rnd(i, 514) * .06)), Paint()..color = const Color(0xFF5B6F99));
    }
    fillGradient(c, Rect.fromLTWH(0, s.height * .55, s.width, s.height * .2),
        const [Color(0x0090A6CC), Color(0x6690A6CC), Color(0x0090A6CC)], stops: const [0, .6, 1]);
    c.drawPath(ridge(s, .72, .035, 521, roughness: .5), Paint()..color = const Color(0xFFB4C3DC));
    for (var i = 0; i < 30; i++) {
      final x = rnd(i, 522) * s.width;
      final y = s.height * (.74 + rnd(i, 523) * .03);
      snowyPine(c, x, y, u * (.13 + rnd(i, 524) * .08), const Color(0xFF34476F), const Color(0xFFD5E0F0));
    }
  }

  /// Kar taneleri: [layer] 0 uzak (küçük, yavaş) … 2 yakın (büyük, bulanık).
  void _flakes(Canvas c, Size s, double t, int layer) {
    final u = s.shortestSide;
    final area = s.width * s.height;
    final n = switch (layer) {
      0 => (area / 4200).clamp(90, 300).toInt(),
      1 => (area / 11000).clamp(40, 120).toInt(),
      _ => (area / 60000).clamp(10, 26).toInt(),
    };
    final size = [u * .0022, u * .0045, u * .011][layer];
    final speed = [s.height * .025, s.height * .045, s.height * .075][layer];
    final p = Paint()..color = Colors.white.withValues(alpha: [.55, .75, .5][layer]);
    if (layer == 2) p.maskFilter = MaskFilter.blur(BlurStyle.normal, size * .6);
    final salt = 530 + layer * 10;
    for (var i = 0; i < n; i++) {
      final k = .75 + rnd(i, salt) * .5;
      final travel = s.height + size * 8;
      final y = (rnd(i, salt + 1) * travel + t * speed * k) % travel - size * 4;
      final drift = sin(t * (.25 + rnd(i, salt + 2) * .3) + i) * u * (.012 + layer * .012);
      final x = (rnd(i, salt + 3) * s.width + drift + t * u * .004 * (layer + 1)) % s.width;
      c.drawCircle(Offset(x, y), size * (.6 + rnd(i, salt + 4) * .8), p);
    }
  }

  @override
  void mid(Canvas c, Size s, double t) {
    _flakes(c, s, t, 0);
    // Ağaçların arasında ağır ağır süzülen sis
    for (var i = 0; i < 3; i++) {
      final w = s.width * .9;
      final x = (rnd(i, 541) * (s.width + w) + t * 5 * (1 + i * .3)) % (s.width + w) - w / 2;
      final center = Offset(x, s.height * (.73 + i * .02));
      c.drawOval(
        Rect.fromCenter(center: center, width: w, height: s.height * .09),
        Paint()
          ..shader = ui.Gradient.radial(center, w / 2, [const Color(0x40C9D6EA), const Color(0x00C9D6EA)]),
      );
    }
  }

  @override
  void front(Canvas c, Size s) {
    final g = s.height * .82;
    final ground = Path()..moveTo(0, g);
    for (double x = 0; x <= s.width + 8; x += 8) {
      ground.lineTo(x, g - s.height * .03 * sin(x / s.width * 2.4 + .4) - s.height * .015 * sin(x / s.width * 7));
    }
    ground
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(
      ground,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, g - s.height * .05), Offset(0, s.height),
            const [Color(0xFFE4ECF8), Color(0xFFB9C8E0), Color(0xFF8EA1C4)], const [0, .5, 1]),
    );
    // Ay ışığının karda bıraktığı parlaklık
    final moonX = s.width * _moon.dx;
    glow(c, Offset(moonX, g + s.height * .05), s.width * .3, const Color(0xFFFFFFFF).withValues(alpha: .25));
    final u = s.shortestSide;
    // Sokak lambası ve sıcak ışığı
    final lx = s.width * .3, ly = g - s.height * .01;
    final lh = u * .3;
    glow(c, Offset(lx, ly + u * .02), u * .22, const Color(0xFFFFC77A).withValues(alpha: .25));
    final pole = Paint()..color = const Color(0xFF1B2440);
    c.drawRect(Rect.fromLTWH(lx - u * .005, ly - lh, u * .01, lh), pole);
    c.drawRect(Rect.fromLTWH(lx - u * .018, ly - lh - u * .03, u * .036, u * .03), pole);
    c.drawRect(Rect.fromLTWH(lx - u * .022, ly - lh - u * .036, u * .044, u * .008), Paint()..color = const Color(0xFFE9F0FA));
    glow(c, Offset(lx, ly - lh - u * .015), u * .2, const Color(0xFFFFD08A).withValues(alpha: .55), blend: BlendMode.plus);
    c.drawCircle(Offset(lx, ly - lh - u * .015), u * .009, Paint()..color = const Color(0xFFFFF3D6));
    // Yakın, iri karlı çamlar (kenarlarda, sayacı kapatmadan)
    for (final (fx, fh) in [(-.02, .62), (.07, .46), (.93, .5), (1.03, .66), (.16, .3), (.84, .34)]) {
      final x = s.width * fx;
      snowyPine(c, x, g + s.height * .04, u * fh, const Color(0xFF16223F), const Color(0xFFE6EEF9));
    }
  }

  @override
  void top(Canvas c, Size s, double t) {
    _flakes(c, s, t, 1);
    // Karın üstünde göz kırpan ışıltılar
    final g = s.height * .82;
    final sp = Paint();
    for (var i = 0; i < 40; i++) {
      final tw = sin(t * (1.2 + rnd(i, 561) * 2) + i * 4);
      if (tw < .7) continue;
      sp.color = Colors.white.withValues(alpha: (tw - .7) / .3 * .9);
      c.drawCircle(Offset(rnd(i, 562) * s.width, g + s.height * (.03 + rnd(i, 563) * .15)), 1.2, sp);
    }
    _flakes(c, s, t, 2);
  }
}

/// Gerçek fotoğraf: karlı orman, üstünde katman katman süzülen kar.
class PhotoSnowScene extends SnowfallScene {
  const PhotoSnowScene();
  @override
  String get photo => 'assets/photos/kar.jpg';
  @override
  void back(Canvas c, Size s) {}
  @override
  bool get hasFront => false;
  @override
  void mid(Canvas c, Size s, double t) => _flakes(c, s, t, 0);
  @override
  void top(Canvas c, Size s, double t) {
    _flakes(c, s, t, 1);
    _flakes(c, s, t, 2);
  }
}

/// Gerçek fotoğraf: dolu fırtınası, üstünde düşüp seken buz taneleri.
class PhotoHailScene extends ScenePainter {
  const PhotoHailScene();
  @override
  String get photo => 'assets/photos/dolu.jpg';
  @override
  bool get hasFront => false;
  @override
  void top(Canvas c, Size s, double t) => hailFall(c, s, t, s.height * .8, s.height * .99);
}
