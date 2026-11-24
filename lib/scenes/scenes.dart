import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../data/ambient.dart';
import 'scene_painters.dart';

/// Sayacın arkasında oynayan, kodla çizilmiş hareketli sahneler.
enum Scene {
  gece('Yıldız kayması', Icons.nights_stay_rounded, NightSkyScene()),
  kuzey('Kuzey ışıkları', Icons.auto_awesome_rounded, AuroraScene()),
  somine('Şömine', Icons.fireplace_rounded, FireplaceScene()),
  gol('Dağ gölü', Icons.landscape_rounded, LakeScene()),
  orman('Sisli orman', Icons.forest_rounded, MistyForestScene()),
  pencere('Karlı pencere', Icons.ac_unit_rounded, SnowyWindowScene()),
  deniz('Gün batımı', Icons.wb_twilight_rounded, SunsetSeaScene()),
  sakin('Sakin', Icons.bubble_chart_rounded, CalmScene());

  const Scene(this.label, this.icon, this.painter);
  final String label;
  final IconData icon;
  final ScenePainter painter;

  static Scene? fromName(String? n) {
    for (final s in Scene.values) {
      if (s.name == n) return s;
    }
    return null;
  }

  /// "Moda göre" seçeneğinde ortam sesine uyan sahne.
  static Scene forSound(AmbientSound sound) => switch (sound) {
    AmbientSound.doga => Scene.gol,
    AmbientSound.orman => Scene.orman,
    AmbientSound.yagmur => Scene.orman,
    AmbientSound.ates => Scene.somine,
    AmbientSound.kulube => Scene.pencere,
    AmbientSound.dalga => Scene.deniz,
    AmbientSound.kahverengi => Scene.sakin,
    AmbientSound.tiktak => Scene.sakin,
    AmbientSound.none => Scene.gece,
  };

  /// Sahne bu sesin görsel efektini kendisi çiziyorsa, üstüne ayrıca efekt eklenmez.
  bool ownsEffectOf(AmbientSound sound) =>
      (this == Scene.somine && sound == AmbientSound.ates) || (this == Scene.pencere && sound == AmbientSound.kulube);
}

/// Bir sahneyi çizen ve canlandıran bileşen. Sabit katmanlar bir kez resme çevrilir,
/// hareketli katmanlar saniyede ~30 kare güncellenir (pil dostu).
class SceneView extends StatefulWidget {
  const SceneView({super.key, required this.scene, this.animate = true});
  final Scene scene;
  final bool animate;

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneCache {
  Size size = Size.zero;
  double dpr = 1;
  Scene? scene;
  ui.Image? back;
  ui.Image? front;

  void dispose() {
    back?.dispose();
    front?.dispose();
    back = front = null;
  }
}

class _SceneViewState extends State<SceneView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(3.0);
  final _cache = _SceneCache();
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      if (d - _last >= const Duration(milliseconds: 33)) {
        _last = d;
        _time.value = 3.0 + d.inMicroseconds / 1e6;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final run = widget.animate && !MediaQuery.of(context).disableAnimations;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 2.0);
    return RepaintBoundary(
      child: CustomPaint(size: Size.infinite, painter: _ScenePainterAdapter(widget.scene, _time, _cache, dpr)),
    );
  }
}

class _ScenePainterAdapter extends CustomPainter {
  _ScenePainterAdapter(this.scene, this.time, this.cache, this.dpr) : super(repaint: time);
  final Scene scene;
  final ValueNotifier<double> time;
  final _SceneCache cache;
  final double dpr;

  ui.Image _bake(Size s, void Function(Canvas, Size) draw) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(dpr);
    draw(c, s);
    final pic = rec.endRecording();
    final img = pic.toImageSync((s.width * dpr).ceil(), (s.height * dpr).ceil());
    pic.dispose();
    return img;
  }

  void _drawImage(Canvas c, ui.Image img, Size s) {
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Offset.zero & s,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = scene.painter;
    if (cache.size != size || cache.scene != scene || cache.dpr != dpr) {
      cache.dispose();
      cache
        ..size = size
        ..scene = scene
        ..dpr = dpr
        ..back = _bake(size, p.back)
        ..front = p.hasFront ? _bake(size, p.front) : null;
    }
    final t = time.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _drawImage(canvas, cache.back!, size);
    p.mid(canvas, size, t);
    if (cache.front != null) _drawImage(canvas, cache.front!, size);
    p.top(canvas, size, t);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainterAdapter old) => old.scene != scene || old.dpr != dpr || old.time != time;
}
