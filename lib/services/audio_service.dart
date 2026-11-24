import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/ambient.dart';

/// Arka plan (ortam) seslerini ve zil/alkış efektlerini çalar.
///
/// Ortam sesi iki oynatıcıyla çalınır: biri biterken diğeri 1,5 saniyelik yumuşak geçişle
/// başlar. Böylece ses dosyası başa sararken (özellikle mp3'te) duyulan kısa boşluk oluşmaz.
class AudioService {
  final _loop = <AudioPlayer>[AudioPlayer(playerId: 'ambient-a'), AudioPlayer(playerId: 'ambient-b')];
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _preview = AudioPlayer(playerId: 'preview');

  static const _overlap = Duration(milliseconds: 1500);

  AmbientSound _current = AmbientSound.none;
  bool _playing = false;
  int _active = 0;
  double _volume = .6;
  Duration _length = const Duration(seconds: 30);
  Timer? _nextTimer;
  Timer? _fadeTimer;

  Future<void> init() async {
    // Ortam sesi ve zil birbirini kesmesin; diğer uygulamaların sesiyle de karışabilsin.
    final ctx = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, stayAwake: true).build();
    for (final p in [..._loop, _sfx, _preview]) {
      try {
        await p.setAudioContext(ctx);
        await p.setReleaseMode(ReleaseMode.stop);
      } catch (e) {
        debugPrint('Ses bağlamı ayarlanamadı: $e');
      }
    }
  }

  AudioPlayer get _a => _loop[_active];
  AudioPlayer get _b => _loop[1 - _active];

  /// Seçilen ortam sesini kesintisiz döngüde çalar; [sound] none ise durdurur.
  Future<void> playAmbient(AmbientSound sound, double volume) async {
    await _preview.stop().catchError((_) {});
    _volume = volume;
    if (sound.assetPath == null) {
      await stopAmbient();
      return;
    }
    try {
      if (_current == sound && _playing) {
        await _a.setVolume(volume);
        return;
      }
      if (_current == sound && _a.state == PlayerState.paused) {
        await _a.setVolume(volume);
        await _a.resume();
        _playing = true;
        final pos = await _a.getCurrentPosition() ?? Duration.zero;
        _scheduleNext(pos);
        return;
      }
      await stopAmbient();
      _current = sound;
      _active = 0;
      await _a.setSource(AssetSource(sound.assetPath!));
      _length = await _a.getDuration() ?? const Duration(seconds: 30);
      await _a.setVolume(volume);
      await _a.resume();
      _playing = true;
      _scheduleNext(Duration.zero);
    } catch (e) {
      debugPrint('Ortam sesi çalınamadı: $e');
    }
  }

  void _scheduleNext(Duration position) {
    _nextTimer?.cancel();
    final wait = _length - position - _overlap;
    _nextTimer = Timer(wait.isNegative ? Duration.zero : wait, _crossfade);
  }

  Future<void> _crossfade() async {
    if (!_playing || _current.assetPath == null) return;
    final from = _a, to = _b;
    try {
      await to.setSource(AssetSource(_current.assetPath!));
      await to.setVolume(0);
      await to.resume();
    } catch (e) {
      debugPrint('Ses geçişi başlatılamadı: $e');
      return;
    }
    _active = 1 - _active;
    _scheduleNext(Duration.zero);
    const steps = 15;
    var i = 0;
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(Duration(milliseconds: _overlap.inMilliseconds ~/ steps), (t) {
      i++;
      final f = (i / steps).clamp(0.0, 1.0);
      to.setVolume(_volume * f).catchError((_) {});
      from.setVolume(_volume * (1 - f)).catchError((_) {});
      if (i >= steps) {
        t.cancel();
        from.stop().catchError((_) {});
      }
    });
  }

  Future<void> pauseAmbient() async {
    _playing = false;
    _nextTimer?.cancel();
    _fadeTimer?.cancel();
    try {
      await _b.stop();
      await _a.setVolume(_volume);
      await _a.pause();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    _playing = false;
    _current = AmbientSound.none;
    _nextTimer?.cancel();
    _fadeTimer?.cancel();
    for (final p in _loop) {
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  Future<void> setAmbientVolume(double v) async {
    _volume = v;
    try {
      if (_fadeTimer?.isActive != true) await _a.setVolume(v);
      await _preview.setVolume(v);
    } catch (_) {}
  }

  /// Ayarlar ekranında sesi birkaç saniye dinletmek için.
  Future<void> preview(AmbientSound sound, double volume) async {
    try {
      await _preview.stop();
      if (sound.assetPath == null) return;
      await _preview.play(AssetSource(sound.assetPath!), volume: volume);
      Future.delayed(const Duration(seconds: 6), () => _preview.stop());
    } catch (e) {
      debugPrint('Önizleme çalınamadı: $e');
    }
  }

  Future<void> stopPreview() async {
    try {
      await _preview.stop();
    } catch (_) {}
  }

  Future<void> _effect(String file, double volume) async {
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource('sounds/$file.mp3'), volume: volume);
    } catch (e) {
      debugPrint('Efekt çalınamadı: $e');
    }
  }

  /// Teneffüs zili (okul zili ya da guguk): odak bitip mola başlarken.
  Future<void> bell(double volume, [BellSound sound = BellSound.okul]) => _effect(sound.file, volume);

  /// Mola bitip odak başlarken çalan yumuşak çan.
  Future<void> chime(double volume) => _effect('can', volume);

  Future<void> applause(double volume) => _effect('alkis', volume);

  Future<void> dispose() async {
    _nextTimer?.cancel();
    _fadeTimer?.cancel();
    for (final p in [..._loop, _sfx, _preview]) {
      await p.dispose();
    }
  }
}
