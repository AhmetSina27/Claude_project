import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../data/ambient.dart';
import '../data/backgrounds.dart';
import '../models/settings.dart';
import '../scenes/scenes.dart';
import '../state/pomodoro_controller.dart';

/// Gösterilecek arka planın kaynağı: fotoğraf ve/veya video.
@immutable
class BackgroundSource {
  const BackgroundSource({required this.key, this.image, this.videoAsset, this.videoFile, this.scene});
  final String key;
  final Scene? scene;
  final ImageProvider? image;
  final String? videoAsset;
  final String? videoFile;

  bool get hasVideo => videoAsset != null || videoFile != null;
}

/// Video oynatıcısı olan platformlar (Windows ve Linux'ta fotoğraf gösterilir).
bool get videoSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Ayarlarda seçilen arka plan. [sound]: o an çalan ortam sesi ("Moda göre" için).
BackgroundSource? backgroundFor(AppSettings s, PomodoroController c, AmbientSound sound) {
  BackgroundSource? fromPreset(BackgroundPreset? p) =>
      p == null ? null : BackgroundSource(key: p.id, image: AssetImage(p.image), videoAsset: p.video);
  switch (s.backgroundId) {
    case 'none':
      return null;
    case 'auto':
      final preset = presetForSound(sound);
      if (preset != null) return fromPreset(preset);
      final scene = Scene.forSound(sound);
      return BackgroundSource(key: 'scene:${scene.name}', scene: scene);
    case 'custom':
      if (c.customVideoPath != null) return BackgroundSource(key: 'custom-video', videoFile: c.customVideoPath);
      final b = c.customBackground;
      return b == null ? null : BackgroundSource(key: 'custom-image', image: MemoryImage(b));
    default:
      if (s.backgroundId.startsWith('scene:')) {
        final scene = Scene.fromName(s.backgroundId.substring(6));
        return scene == null ? null : BackgroundSource(key: s.backgroundId, scene: scene);
      }
      return fromPreset(presetById(s.backgroundId));
  }
}

/// Arka plan (video ya da yavaşça hareket eden fotoğraf) + okunabilirlik perdesi.
class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({super.key, required this.source, required this.dim, required this.blur, required this.scrim});

  final BackgroundSource source;
  final double dim;
  final double blur;
  final Color scrim;

  @override
  Widget build(BuildContext context) {
    Widget media = source.scene != null
        ? SceneView(key: ValueKey(source.key), scene: source.scene!)
        : source.hasVideo && videoSupported
        ? _LoopingVideo(key: ValueKey(source.key), source: source)
        : _KenBurnsImage(key: ValueKey(source.key), image: source.image);
    if (blur > 0.5) {
      media = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
        child: media,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 800), child: media),
        ColoredBox(color: scrim.withValues(alpha: dim.clamp(0.0, 1.0))),
      ],
    );
  }
}

/// Fotoğrafı çok yavaşça yakınlaştırıp kaydırarak canlı gösterir ("Ken Burns" etkisi).
class _KenBurnsImage extends StatefulWidget {
  const _KenBurnsImage({super.key, required this.image});
  final ImageProvider? image;

  @override
  State<_KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<_KenBurnsImage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.image == null) return const SizedBox.expand();
    final img = Image(
      image: widget.image!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
    );
    if (MediaQuery.of(context).disableAnimations) return img;
    return AnimatedBuilder(
      animation: _c,
      child: img,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(1.06 + .08 * t, 1.06 + .08 * t, 1, 1)
            ..translateByDouble(sin(t * pi) * 12, -t * 10, 0, 1),
          child: child,
        );
      },
    );
  }
}

/// Sessiz ve sürekli dönen arka plan videosu.
class _LoopingVideo extends StatefulWidget {
  const _LoopingVideo({super.key, required this.source});
  final BackgroundSource source;

  @override
  State<_LoopingVideo> createState() => _LoopingVideoState();
}

class _LoopingVideoState extends State<_LoopingVideo> {
  VideoPlayerController? _v;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = widget.source;
    final opts = VideoPlayerOptions(mixWithOthers: true);
    final v = s.videoAsset != null
        ? VideoPlayerController.asset(s.videoAsset!, videoPlayerOptions: opts)
        : VideoPlayerController.file(File(s.videoFile!), videoPlayerOptions: opts);
    try {
      await v.initialize();
      await v.setVolume(0); // Ses, uygulamanın ortam sesinden gelir.
      await v.setLooping(true);
      await v.play();
      if (!mounted) {
        await v.dispose();
        return;
      }
      setState(() => _v = v);
    } catch (e) {
      debugPrint('Arka plan videosu açılamadı: $e');
      await v.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _v?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _v;
    if (v == null || _failed) {
      // Video hazır olana kadar (ya da açılamazsa) fotoğrafı göster.
      return _KenBurnsImage(image: widget.source.image);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v)),
      ),
    );
  }
}
