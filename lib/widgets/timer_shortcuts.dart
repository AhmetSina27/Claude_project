import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Klavye kısayolları (Boşluk, R, S, F...). Kullanıcı bir yazı alanına yazarken
/// kısayollar devre dışı kalır; böylece hedef adında "s" yazınca mola başlamaz.
class TimerShortcuts extends StatelessWidget {
  const TimerShortcuts({super.key, required this.bindings, required this.child});

  final Map<ShortcutActivator, VoidCallback> bindings;
  final Widget child;

  /// Odak bir yazı alanındaysa true.
  static bool get isTyping {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent || isTyping) return KeyEventResult.ignored;
        for (final entry in bindings.entries) {
          if (entry.key.accepts(event, HardwareKeyboard.instance)) {
            entry.value();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
