import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:odaklanma_zamani/scenes/scenes.dart';

void main() {
  for (final scene in Scene.values) {
    test('${scene.label} sahnesi hatasız çizilir', () {
      for (final size in const [ui.Size(390, 844), ui.Size(1180, 820)]) {
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        final p = scene.painter;
        p.back(c, size);
        for (final t in [0.0, 3.3, 12.7]) {
          p.mid(c, size, t);
          if (p.hasFront) p.front(c, size);
          p.top(c, size, t);
        }
        rec.endRecording().dispose();
      }
    });
  }
}
