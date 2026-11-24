import 'package:material_ui/material_ui.dart';

import '../data/ambient.dart';

/// Ortam sesi seçimi için yatay çip listesi.
class SoundPicker extends StatelessWidget {
  const SoundPicker({super.key, required this.selected, required this.onSelected, this.color});

  final AmbientSound selected;
  final ValueChanged<AmbientSound> onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final s in AmbientSound.values)
          ChoiceChip(
            avatar: Icon(s.icon, size: 18, color: s == selected ? Colors.white : accent),
            label: Text(s.label),
            selected: s == selected,
            showCheckmark: false,
            selectedColor: accent,
            labelStyle: TextStyle(color: s == selected ? Colors.white : null, fontWeight: FontWeight.w500),
            onSelected: (_) => onSelected(s),
          ),
      ],
    );
  }
}
