import 'ambient.dart';

/// Uygulamayla birlikte gelen hazır arka planlar.
///
/// Yeni arka plan eklemek için:
/// 1. Fotoğrafı assets/backgrounds/ klasörüne koy (video varsa .mp4 olarak yanına).
/// 2. Aşağıya bir satır ekle. [video] verilirse arka plan hareketli olur; fotoğraf hem
///    küçük resim hem de videonun oynatılamadığı cihazlarda (Windows, Linux) yedek olarak kullanılır.
/// 3. [sound] verilirse "Moda göre" seçeneğinde o ses çalarken bu arka plan gösterilir.
class BackgroundPreset {
  const BackgroundPreset(this.id, this.label, this.image, {this.video, this.sound});
  final String id;
  final String label;
  final String image;
  final String? video;
  final AmbientSound? sound;
}

const backgroundPresets = <BackgroundPreset>[
  // Örnek:
  // BackgroundPreset('ates', 'Şömine', 'assets/backgrounds/ates.jpg',
  //     video: 'assets/backgrounds/ates.mp4', sound: AmbientSound.ates),
];

BackgroundPreset? presetById(String id) {
  for (final p in backgroundPresets) {
    if (p.id == id) return p;
  }
  return null;
}

BackgroundPreset? presetForSound(AmbientSound sound) {
  for (final p in backgroundPresets) {
    if (p.sound == sound) return p;
  }
  return null;
}
