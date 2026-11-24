import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../models/day_stats.dart';

const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Günlük etüt ve mola sayımı, son 7 günün grafiği.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final today = c.today;
    final week = c.lastDays(7);
    final weekFocus = week.fold<int>(0, (a, e) => a + e.$2.focusSeconds);
    final weekSessions = week.fold<int>(0, (a, e) => a + e.$2.focusSessions);
    final maxMin = week.map((e) => e.$2.focusSeconds ~/ 60).fold<int>(0, (a, b) => a > b ? a : b);

    Widget tile(String value, String label) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Bugün', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  tile(formatDuration(today.focusSeconds), 'Etüt süresi'),
                  const SizedBox(width: 10),
                  tile('${today.focusSessions}', 'Oturum'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  tile('${today.breaks}', 'Mola sayısı'),
                  const SizedBox(width: 10),
                  tile(formatDuration(today.breakSeconds), 'Mola süresi'),
                ],
              ),
              const SizedBox(height: 24),
              Text('Son 7 gün', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${formatDuration(weekFocus)} etüt · $weekSessions oturum · ${c.streakDays} günlük seri',
                style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: SizedBox(
                    height: 200,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (i, (day, s)) in week.indexed)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${s.focusSeconds ~/ 60}',
                                  style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: maxMin == 0
                                        ? 0.02
                                        : ((s.focusSeconds ~/ 60) / maxMin).clamp(0.02, 1.0),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: i == week.length - 1
                                            ? scheme.primary
                                            : scheme.primary.withValues(alpha: .45),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _days[day.weekday - 1],
                                  style: t.labelMedium?.copyWith(
                                    fontWeight: i == week.length - 1 ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Çubuklar günlük etüt süresini dakika olarak gösterir.',
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    for (final (day, s) in week.reversed)
                      ListTile(
                        title: Text('${day.day}.${day.month.toString().padLeft(2, '0')} ${_days[day.weekday - 1]}'),
                        subtitle: Text('${s.breaks} mola · ${formatDuration(s.breakSeconds)} mola süresi'),
                        trailing: Text(
                          '${s.focusSessions} oturum · ${formatDuration(s.focusSeconds)}',
                          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
