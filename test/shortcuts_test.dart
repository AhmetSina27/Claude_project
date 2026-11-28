import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:odaklanma_zamani/widgets/timer_shortcuts.dart';

void main() {
  testWidgets('yazı alanına yazarken kısayollar çalışmaz, dışarıda çalışır', (tester) async {
    var skips = 0;
    final field = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerShortcuts(
            bindings: {const SingleActivator(LogicalKeyboardKey.keyS): () => skips++},
            child: Column(children: [TextField(focusNode: field)]),
          ),
        ),
      ),
    );
    await tester.pump();
    // Odak sayfadayken S kısayolu çalışır
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    expect(skips, 1);
    // Yazı alanına odaklanınca "s" harfi kısayolu tetiklemez
    field.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    expect(skips, 1);
  });
}
