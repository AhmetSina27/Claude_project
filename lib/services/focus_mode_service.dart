import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Odak süresince cihazın bildirimlerini susturur.
///
/// Android: Sistem "Rahatsız Etme" modunu (yalnızca öncelikli) açar, odak bitince
/// önceki duruma döndürür. Bunun için kullanıcının bir kez "Rahatsız Etme erişimi"
/// vermesi gerekir.
/// iOS, macOS, Windows: İşletim sistemi uygulamaların bunu yapmasına izin vermez;
/// kullanıcıya Odak/Odak Yardımı kurulumu için yönlendirme gösterilir.
class FocusModeService {
  static const _channel = MethodChannel('odaklanma_zamani/focus_mode');

  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openPermissionSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('openPermissionSettings');
    } catch (_) {}
  }

  Future<bool> enable() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('enable') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}
  }

  /// Desteklenmeyen platformlarda kullanıcıya gösterilecek açıklama.
  String get manualHint => switch (defaultTargetPlatform) {
    TargetPlatform.iOS =>
      'iPhone ve iPad\'de uygulamalar Odak modunu kendisi açamaz. Ayarlar > Odak > Rahatsız Etme > '
          'Otomatik olarak aç bölümüne "Odaklanma Zamanı" uygulamasını ekle; uygulamayı açtığında '
          'bildirimler susar.',
    TargetPlatform.macOS =>
      'macOS\'ta Kontrol Merkezi > Odak > Rahatsız Etme\'yi aç. Sistem Ayarları > Odak bölümünden '
          'zamanlama da ekleyebilirsin.',
    TargetPlatform.windows =>
      'Windows\'ta Ayarlar > Sistem > Bildirimler > Rahatsız etme\'yi aç ya da "Odak oturumu" kullan.',
    _ => 'Bu cihazda bildirimleri sistem ayarlarından susturabilirsin.',
  };
}
