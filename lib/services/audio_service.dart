import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/ambient.dart';

/// Arka plan (ortam) seslerini ve zil/alkış efektlerini çalar.
class AudioService {
  final AudioPlayer _ambient = AudioPlayer(playerId: 'ambient');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _preview = AudioPlayer(playerId: 'preview');

  AmbientSound _current = AmbientSound.none;
  bool _ambientPlaying = false;

  Future<void> init() async {
    // Ortam sesi ve zil birbirini kesmesin; diğer uygulamaların sesiyle de karışabilsin.
    final ctx = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, stayAwake: true).build();
    for (final p in [_ambient, _sfx, _preview]) {
      try {
        await p.setAudioContext(ctx);
      } catch (e) {
        debugPrint('Ses bağlamı ayarlanamadı: $e');
      }
    }
    await _ambient.setReleaseMode(ReleaseMode.loop);
    await _preview.setReleaseMode(ReleaseMode.stop);
    await _sfx.setReleaseMode(ReleaseMode.stop);
  }

  /// Seçilen ortam sesini döngüde çalar; [sound] none ise durdurur.
  Future<void> playAmbient(AmbientSound sound, double volume) async {
    await _preview.stop();
    if (sound.assetPath == null) {
      await stopAmbient();
      return;
    }
    try {
      await _ambient.setVolume(volume);
      if (_current == sound && _ambientPlaying) return;
      if (_current == sound && _ambient.state == PlayerState.paused) {
        await _ambient.resume();
      } else {
        await _ambient.stop();
        await _ambient.play(AssetSource(sound.assetPath!), volume: volume);
      }
      _current = sound;
      _ambientPlaying = true;
    } catch (e) {
      debugPrint('Ortam sesi çalınamadı: $e');
    }
  }

  Future<void> pauseAmbient() async {
    _ambientPlaying = false;
    try {
      await _ambient.pause();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    _ambientPlaying = false;
    _current = AmbientSound.none;
    try {
      await _ambient.stop();
    } catch (_) {}
  }

  Future<void> setAmbientVolume(double v) async {
    try {
      await _ambient.setVolume(v);
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

  /// Teneffüs zili: odak bitip mola başlarken.
  Future<void> bell(double volume) => _effect('zil', volume);

  /// Mola bitip odak başlarken çalan yumuşak çan.
  Future<void> chime(double volume) => _effect('can', volume);

  Future<void> applause(double volume) => _effect('alkis', volume);

  Future<void> dispose() async {
    await _ambient.dispose();
    await _sfx.dispose();
    await _preview.dispose();
  }
}
