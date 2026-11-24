import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../models/day_stats.dart';
import '../state/pomodoro_controller.dart';

/// Odak süresi için hızlı seçim: hazır süreler, özel süre ve serbest (ileri sayan) mod.
class DurationChips extends StatelessWidget {
  const DurationChips({super.key, required this.color, this.inline = false});
  final Color color;

  /// true: kaydırma olmadan, yalnızca içeriği kadar yer kaplar (yatay ekranda üst satır için).
  final bool inline;

  static const presets = [15, 25, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final m = c.settings.focusMinutes;
    final isCustom = !c.isFree && !presets.contains(m);

    Widget chip(String label, bool selected, VoidCallback onTap, {IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? Colors.white : color),
        selected: selected,
        showCheckmark: false,
        selectedColor: color,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: 13),
        onSelected: (_) => onTap(),
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in presets) chip(formatMinutes(p), !c.isFree && m == p, () => c.setFocusDuration(p)),
        chip(
          isCustom ? formatMinutes(m) : 'Özel',
          isCustom,
          () => showCustomDurationDialog(context, c),
          icon: Icons.tune_rounded,
        ),
        chip('Serbest', c.isFree, () => c.setFocusDuration(null), icon: Icons.all_inclusive_rounded),
      ],
    );
    if (inline) return SizedBox(height: 36, child: row);
    return SizedBox(
      height: 36,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: row,
        ),
      ),
    );
  }
}

/// 90 → "1,5 sa", 60 → "1 sa", 25 → "25 dk", 70 → "1 sa 10 dk".
String formatMinutes(int m) {
  if (m < 60) return '$m dk';
  if (m % 60 == 0) return '${m ~/ 60} sa';
  if (m % 60 == 30) return '${m ~/ 60},5 sa';
  return formatDuration(m * 60);
}

/// Saat ve dakika seçtiren özel süre penceresi.
Future<void> showCustomDurationDialog(BuildContext context, PomodoroController c) async {
  var h = c.settings.focusMinutes ~/ 60;
  var m = c.settings.focusMinutes % 60;
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final total = h * 60 + m;
        Widget wheel(String label, int value, int max, int step, ValueChanged<int> onChanged) => Column(
          children: [
            IconButton.filledTonal(
              tooltip: '$label artır',
              onPressed: value + step <= max ? () => onChanged(value + step) : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            const SizedBox(height: 6),
            Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontSize: 56,
                fontWeight: FontWeight.w700,
                fontVariations: [FontVariation('wght', 700)],
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            IconButton.filledTonal(
              tooltip: '$label azalt',
              onPressed: value - step >= 0 ? () => onChanged(value - step) : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        );
        return AlertDialog(
          title: const Text('Odak süresi'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              wheel(
                'SAAT',
                h,
                PomodoroController.maxFocusMinutes ~/ 60,
                1,
                (v) => setState(() {
                  h = v;
                  if (h * 60 + m > PomodoroController.maxFocusMinutes) m = 0;
                }),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(':', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
              ),
              wheel(
                'DAKİKA',
                m,
                h * 60 >= PomodoroController.maxFocusMinutes ? 0 : 55,
                5,
                (v) => setState(() => m = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: total == 0 ? null : () => Navigator.pop(ctx, total),
              child: Text(total == 0 ? 'Süre seç' : '${formatMinutes(total)} olarak ayarla'),
            ),
          ],
        );
      },
    ),
  );
  if (result != null) c.setFocusDuration(result);
}
