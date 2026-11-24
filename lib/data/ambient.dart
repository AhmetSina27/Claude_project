import 'package:material_ui/material_ui.dart';

/// Odak (veya mola) sırasında arka planda çalan ortam sesleri.
/// Ses dosyaları assets/sounds klasöründedir; tool/generate_sounds.py ile üretilir.
/// Gerçek kayıtlarla değiştirmek istersen aynı adla .mp3 dosyası koyman yeterli.
enum AmbientSound {
  none('Sessiz', Icons.volume_off_rounded, null),
  doga('Dere', Icons.water_rounded, 'doga'),
  orman('Orman', Icons.forest_rounded, 'orman'),
  yagmur('Yağmur', Icons.water_drop_rounded, 'yagmur'),
  ates('Şömine ateşi', Icons.local_fire_department_rounded, 'ates'),
  kulube('Karlı kulübe', Icons.ac_unit_rounded, 'kulube'),
  dalga('Okyanus dalgaları', Icons.waves_rounded, 'dalga'),
  kahverengi('Kahverengi gürültü', Icons.graphic_eq_rounded, 'kahverengi'),
  tiktak('Tik tak', Icons.watch_later_rounded, 'tiktak');

  const AmbientSound(this.label, this.icon, this.file);
  final String label;
  final IconData icon;
  final String? file;

  String? get assetPath => file == null ? null : 'sounds/$file.mp3';

  static AmbientSound fromName(String? name) =>
      AmbientSound.values.firstWhere((s) => s.name == name, orElse: () => AmbientSound.none);
}
