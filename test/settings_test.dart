import 'package:flutter_test/flutter_test.dart';
import 'package:odaklanma_zamani/data/ambient.dart';
import 'package:odaklanma_zamani/models/settings.dart';

void main() {
  test('copyWith ve JSON tüm alanları korur', () {
    final s = const AppSettings().copyWith(
      focusMinutes: 90,
      backgroundId: 'scene:somine',
      backgroundDim: .4,
      backgroundBlur: 6,
      freeFocus: true,
      focusSound: AmbientSound.ates,
      accent: AccentTheme.orman,
    );
    // Başka bir alan değişince arka plan seçimi kaybolmamalı.
    final t = s.copyWith(dailyGoal: 3);
    expect(t.backgroundId, 'scene:somine');
    expect(t.freeFocus, isTrue);
    final back = AppSettings.fromJson(t.toJson());
    expect(back.focusMinutes, 90);
    expect(back.backgroundId, 'scene:somine');
    expect(back.backgroundDim, .4);
    expect(back.backgroundBlur, 6);
    expect(back.freeFocus, isTrue);
    expect(back.focusSound, AmbientSound.ates);
    expect(back.accent, AccentTheme.orman);
    expect(back.dailyGoal, 3);
  });
}
