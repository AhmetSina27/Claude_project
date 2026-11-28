import 'dart:math';
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
  sakin('Sakin', Icons.bubble_chart_rounded, CalmScene()),
  kiraz('Kiraz çiçekleri', Icons.local_florist_rounded, SakuraScene()),
  kutuphane('Kütüphane', Icons.local_library_rounded, LibraryScene()),
  uzay('Uzay', Icons.public_rounded, SpaceScene()),
  sualti('Su altı', Icons.scuba_diving_rounded, UnderwaterScene()),
  lavanta('Lavanta tarlası', Icons.spa_rounded, LavenderScene()),
  sisli('Sisli', Icons.foggy, FoggyScene()),
  karli('Kar yağışı', Icons.cloudy_snowing, PhotoSnowScene()),
  gunesli('Güneşli', Icons.wb_sunny_rounded, SunnyScene()),
  dolu('Dolu', Icons.grain_rounded, PhotoHailScene()),
  firtina('Fırtına', Icons.thunderstorm_rounded, StormScene());

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
    AmbientSound.orman => Scene.kiraz,
    AmbientSound.yagmur => Scene.orman,
    AmbientSound.ates => Scene.somine,
    AmbientSound.kulube => Scene.pencere,
    AmbientSound.dalga => Scene.deniz,
    AmbientSound.kahverengi => Scene.uzay,
    AmbientSound.gece => Scene.gece,
    AmbientSound.ruzgar => Scene.kuzey,
    AmbientSound.sualti => Scene.sualti,
    AmbientSound.sinav => Scene.kutuphane,
    AmbientSound.tiktak => Scene.kutuphane,
    AmbientSound.guguklu => Scene.pencere,
    AmbientSound.gunes => Scene.gunesli,
    AmbientSound.dolu => Scene.dolu,
    AmbientSound.kar => Scene.karli,
    AmbientSound.firtina => Scene.firtina,
    AmbientSound.none => Scene.sakin,
  };

  /// Sahne seçildiğinde birlikte gelen ortam sesi.
  AmbientSound get sound => switch (this) {
    Scene.gece => AmbientSound.gece,
    Scene.kuzey => AmbientSound.ruzgar,
    Scene.somine => AmbientSound.ates,
    Scene.gol => AmbientSound.doga,
    Scene.orman => AmbientSound.yagmur,
    Scene.pencere => AmbientSound.kulube,
    Scene.deniz => AmbientSound.dalga,
    Scene.sakin => AmbientSound.kahverengi,
    Scene.kiraz => AmbientSound.orman,
    Scene.kutuphane => AmbientSound.sinav,
    Scene.uzay => AmbientSound.kahverengi,
    Scene.sualti => AmbientSound.sualti,
    Scene.lavanta => AmbientSound.gece,
    Scene.sisli => AmbientSound.ruzgar,
    Scene.karli => AmbientSound.kar,
    Scene.gunesli => AmbientSound.gunes,
    Scene.dolu => AmbientSound.dolu,
    Scene.firtina => AmbientSound.firtina,
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
    final effects = CustomPaint(size: Size.infinite, painter: _ScenePainterAdapter(widget.scene, _time, _cache, dpr));
    final photo = widget.scene.painter.photo;
    if (photo == null) return RepaintBoundary(child: effects);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: const Color(0xFF10141C)),
        // Fotoğraf çok yavaş yakınlaşıp uzaklaşır (Ken Burns); ayrı katmanda kalır.
        RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _time,
            builder: (context, t, child) {
              final k = .5 - .5 * cos(t / 40 * 2 * pi);
              return Transform.scale(
                scale: 1.04 + .05 * k,
                alignment: Alignment(-.3 + .6 * k, .1),
                child: child,
              );
            },
            child: Image.asset(
              photo,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        RepaintBoundary(child: effects),
      ],
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
