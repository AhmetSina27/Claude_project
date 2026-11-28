import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../models/task.dart';

/// Sayacın altındaki hedef satırı: etkin hedef ve ilerlemesi ya da "Hedef ekle".
/// Dokununca hedefler paneli açılır; aşağı kaydırmaya gerek kalmaz.
class GoalLine extends StatelessWidget {
  const GoalLine({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final task = c.activeTask;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: .35),
      shape: StadiumBorder(side: BorderSide(color: scheme.onSurface.withValues(alpha: .12))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => showGoalsSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(task == null ? Icons.add_rounded : Icons.flag_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  task == null ? 'Hedef ekle' : task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (task != null) ...[
                const SizedBox(width: 10),
                ProgressDots(done: task.pomodoros, target: task.target, color: color, size: 8),
              ],
              const SizedBox(width: 6),
              Icon(Icons.expand_more_rounded, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hedefler panelini alttan açılan bir sayfa olarak gösterir.
Future<void> showGoalsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GoalsPanel(
          onPicked: () => Navigator.of(ctx).pop(),
          autofocus: AppScope.read(context).tasks.where((t) => !t.done).isEmpty,
        ),
      ),
    ),
  ),
);

/// "●●○" şeklinde oturum ilerlemesi.
class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.done, required this.target, required this.color, this.size = 9});
  final int done, target;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (target > 8) {
      return Text(
        '$done/$target',
        style: TextStyle(color: done >= target ? color : muted, fontWeight: FontWeight.w700, fontSize: size * 1.5),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < target; i++)
          Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(left: i == 0 ? 0 : size * .4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? color : Colors.transparent,
              border: Border.all(color: i < done ? color : muted, width: 1.4),
            ),
          ),
        if (done > target)
          Padding(
            padding: EdgeInsets.only(left: size * .5),
            child: Text(
              '+${done - target}',
              style: TextStyle(color: color, fontSize: size * 1.3, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

/// Hedef ekleme, seçme, düzenleme ve silme. Ana ekranda kart içinde ve alttan açılan panelde kullanılır.
class GoalsPanel extends StatefulWidget {
  const GoalsPanel({super.key, this.onPicked, this.autofocus = false});

  /// Bir hedef seçildiğinde (panel alttan açıldıysa kapatmak için).
  final VoidCallback? onPicked;

  /// Yazı kutusu açılır açılmaz odaklansın (klavye hemen açılır).
  final bool autofocus;

  @override
  State<GoalsPanel> createState() => _GoalsPanelState();
}

class _GoalsPanelState extends State<GoalsPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  int _target = 1;
  bool _showDone = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final c = AppScope.read(context);
    final task = c.addTask(_input.text, target: _target);
    if (task == null) {
      _focus.requestFocus();
      return;
    }
    _input.clear();
    setState(() => _target = 1);
    _focus.requestFocus();
  }

  void _delete(FocusTask task) {
    final c = AppScope.read(context);
    final removed = c.deleteTask(task);
    if (removed == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${task.title}" silindi'),
          action: SnackBarAction(label: 'Geri al', onPressed: () => c.restoreTask(removed)),
        ),
      );
  }

  Future<void> _edit(FocusTask task) async {
    final c = AppScope.read(context);
    final ctrl = TextEditingController(text: task.title);
    var target = task.target;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Hedefi düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Hedef', border: OutlineInputBorder()),
                onSubmitted: (_) => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 16),
              _TargetStepper(value: target, onChanged: (v) => setD(() => target = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    if (ok == true) c.updateTask(task, title: ctrl.text, target: target);
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final open = c.tasks.where((x) => !x.done).toList();
    final done = c.tasks.where((x) => x.done).toList();
    final plannedLeft = open.fold<int>(0, (a, x) => a + (x.target - x.pomodoros).clamp(0, 20));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Hedefler', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            if (open.isNotEmpty)
              Text(
                plannedLeft == 0 ? 'Hepsi tamam' : '$plannedLeft oturum kaldı',
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Yeni hedef
        TextField(
          controller: _input,
          focusNode: _focus,
          autofocus: widget.autofocus,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
          decoration: InputDecoration(
            hintText: 'Ne üzerinde çalışacaksın?',
            prefixIcon: const Icon(Icons.flag_outlined),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: .6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TargetStepper(value: _target, onChanged: (v) => setState(() => _target = v)),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ekle'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (c.tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(Icons.flag_circle_outlined, size: 44, color: scheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  'Henüz hedef yok.\nÖrneğin "Matematik: türev, 2 oturum" yaz ve Ekle\'ye bas.',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        for (final task in open)
          _GoalTile(
            task: task,
            active: task.id == c.activeTask?.id,
            accent: accent,
            onTap: () {
              c.selectTask(task);
              widget.onPicked?.call();
            },
            onToggle: () => c.toggleTaskDone(task),
            onEdit: () => _edit(task),
            onDelete: () => _delete(task),
          ),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _showDone = !_showDone),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _showDone ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text('Tamamlananlar (${done.length})', style: t.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          if (_showDone)
            for (final task in done)
              _GoalTile(
                task: task,
                active: false,
                accent: accent,
                onTap: () => c.toggleTaskDone(task),
                onToggle: () => c.toggleTaskDone(task),
                onEdit: () => _edit(task),
                onDelete: () => _delete(task),
              ),
        ],
      ],
    );
  }
}

/// Planlanan oturum sayısı seçici: "−  2 oturum  +".
class _TargetStepper extends StatelessWidget {
  const _TargetStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Azalt',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Text(
              '$value oturum',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          IconButton(
            tooltip: 'Artır',
            onPressed: value < 20 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.task,
    required this.active,
    required this.accent,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusTask task;
  final bool active;
  final Color accent;
  final VoidCallback onTap, onToggle, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('hedef-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: scheme.error, borderRadius: BorderRadius.circular(14)),
        child: Icon(Icons.delete_rounded, color: scheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: .14) : scheme.surfaceContainerHighest.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? accent.withValues(alpha: .6) : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: task.done ? 'Geri al' : 'Tamamlandı',
                  onPressed: onToggle,
                  icon: Icon(
                    task.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: task.done ? accent : scheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: t.bodyLarge?.copyWith(
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          decoration: task.done ? TextDecoration.lineThrough : null,
                          color: task.done ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ProgressDots(done: task.pomodoros, target: task.target, color: accent, size: 8),
                          const SizedBox(width: 8),
                          Text(
                            '${task.pomodoros}/${task.target} oturum',
                            style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Şimdi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Seçenekler',
                  icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
                  onSelected: (v) => v == 'duzenle' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'duzenle',
                      child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Düzenle')),
                    ),
                    PopupMenuItem(
                      value: 'sil',
                      child: ListTile(leading: Icon(Icons.delete_rounded), title: Text('Sil')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
