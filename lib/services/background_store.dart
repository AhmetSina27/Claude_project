import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'storage.dart';

/// Kullanıcının cihazından seçtiği arka plan görselini saklar.
/// Mobil ve masaüstünde uygulama klasörüne dosya olarak, web'de tarayıcı deposuna yazılır.
class BackgroundStore {
  BackgroundStore(this._storage);
  final Storage _storage;
  static const _fileName = 'ozel_arka_plan.jpg';
  static const _videoName = 'ozel_arka_plan.mp4';

  Future<File> _file([String name = _fileName]) async => File('${(await getApplicationSupportDirectory()).path}/$name');

  /// Daha önce seçilmiş video varsa yolu (web'de desteklenmez).
  Future<String?> loadVideoPath() async {
    if (kIsWeb) return null;
    try {
      final f = await _file(_videoName);
      return await f.exists() ? f.path : null;
    } catch (_) {
      return null;
    }
  }

  /// Galeriden bir video seçtirip uygulama klasörüne kopyalar.
  Future<String?> pickVideo() async {
    if (kIsWeb) return null;
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (x == null) return null;
    final f = await _file(_videoName);
    await f.parent.create(recursive: true);
    if (await f.exists()) await f.delete();
    await File(x.path).copy(f.path);
    final old = await _file();
    if (await old.exists()) await old.delete();
    return f.path;
  }

  Future<Uint8List?> load() async {
    try {
      if (kIsWeb) {
        final b64 = _storage.loadString('customBackground');
        return b64 == null ? null : base64Decode(b64);
      }
      final f = await _file();
      return await f.exists() ? await f.readAsBytes() : null;
    } catch (e) {
      debugPrint('Arka plan görseli okunamadı: $e');
      return null;
    }
  }

  /// Galeriden / dosyalardan bir görsel seçtirir, küçültüp kaydeder.
  /// Kullanıcı vazgeçerse null döner.
  Future<Uint8List?> pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    if (kIsWeb) {
      await _storage.saveString('customBackground', base64Encode(bytes));
    } else {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes, flush: true);
      final vid = await _file(_videoName);
      if (await vid.exists()) await vid.delete();
    }
    return bytes;
  }

  Future<void> remove() async {
    try {
      if (kIsWeb) {
        await _storage.removeKey('customBackground');
      } else {
        for (final name in [_fileName, _videoName]) {
          final f = await _file(name);
          if (await f.exists()) await f.delete();
        }
      }
    } catch (_) {}
  }
}
