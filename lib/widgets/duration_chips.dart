import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../models/day_stats.dart';
import '../models/phase.dart';
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
          () => showCustomDurationDialog(context, c, phase: Phase.focus),
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
/// [phase] verilmezse o anki aşamanın (odak, kısa mola, uzun mola) süresi ayarlanır.
Future<void> showCustomDurationDialog(BuildContext context, PomodoroController c, {Phase? phase}) async {
  final p = phase ?? c.phase;
  final current = switch (p) {
    Phase.focus => c.settings.focusMinutes,
    Phase.shortBreak => c.settings.shortBreakMinutes,
    Phase.longBreak => c.settings.longBreakMinutes,
  };
  final maxMinutes = p == Phase.focus ? PomodoroController.maxFocusMinutes : 90;
  final quick = p == Phase.focus ? const [10, 20, 30, 40, 50, 75] : const [3, 5, 10, 15, 20, 30];
  var h = current ~/ 60;
  var m = current % 60;
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final total = h * 60 + m;
        void setTotal(int v) => setState(() {
          final t = v.clamp(0, maxMinutes);
          h = t ~/ 60;
          m = t % 60;
        });
        Widget arrow(IconData icon, String tip, int delta) => GestureDetector(
          onLongPress: () => setTotal(total + delta * 5),
          child: IconButton.filledTonal(
            tooltip: '$tip (basılı tut: 5)',
            onPressed: (total + delta >= 0 && total + delta <= maxMinutes) ? () => setTotal(total + delta) : null,
            icon: Icon(icon),
          ),
        );
        Widget wheel(String label, int value, int unit) => Column(
          children: [
            arrow(Icons.keyboard_arrow_up_rounded, '$label artır', unit),
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
            arrow(Icons.keyboard_arrow_down_rounded, '$label azalt', -unit),
          ],
        );
        return AlertDialog(
          title: Text('${p.label} süresi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p == Phase.focus) ...[
                    wheel('SAAT', h, 60),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(':', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700)),
                    ),
                  ],
                  wheel('DAKİKA', p == Phase.focus ? m : total, 1),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final q in quick) ActionChip(label: Text(formatMinutes(q)), onPressed: () => setTotal(q)),
                ],
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
  if (result == null) return;
  switch (p) {
    case Phase.focus:
      c.setFocusDuration(result);
    case Phase.shortBreak:
      c.setBreakDuration(Phase.shortBreak, result);
    case Phase.longBreak:
      c.setBreakDuration(Phase.longBreak, result);
  }
}
