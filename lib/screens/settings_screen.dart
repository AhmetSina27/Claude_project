import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../util/turkce.dart';
import '../data/ambient.dart';
import '../data/backgrounds.dart';
import '../scenes/scenes.dart';
import '../state/pomodoro_controller.dart';
import '../widgets/background_image.dart';
import '../widgets/duration_chips.dart';
import '../models/settings.dart';
import '../widgets/sound_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _dndPermission;

  @override
  void initState() {
    super.initState();
    _checkDnd();
  }

  Future<void> _checkDnd() async {
    final fm = AppScope.read(context).focusMode;
    if (!fm.isSupported) return;
    final ok = await fm.hasPermission();
    if (mounted) setState(() => _dndPermission = ok);
  }

  Future<void> _pick(BuildContext context, Future<bool> Function() pick) async {
    try {
      await pick();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya açılamadı. Başka bir dosya dene ya da fotoğraf iznini kontrol et.')),
        );
      }
    }
  }

  @override
  void dispose() {
    AppScope.read(context).audio.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final s = c.settings;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    void set(AppSettings n) => c.updateSettings(n);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        trUpper(text),
        style: t.labelMedium?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w700, color: scheme.primary),
      ),
    );

    Widget stepper(String label, int value, int min, int max, String unit, ValueChanged<int> onChanged) => ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Azalt',
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 78,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          IconButton(
            tooltip: 'Artır',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
            children: [
              header('Süreler'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Odak süresi'),
                      subtitle: Text(
                        s.freeFocus ? 'Serbest: süre sınırı yok, ileri sayar' : formatMinutes(s.focusMinutes),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Azalt',
                            onPressed: !s.freeFocus && s.focusMinutes > 1
                                ? () => c.setFocusDuration(s.focusMinutes - (s.focusMinutes > 60 ? 5 : 1))
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          IconButton(
                            tooltip: 'Artır',
                            onPressed: !s.freeFocus && s.focusMinutes < PomodoroController.maxFocusMinutes
                                ? () => c.setFocusDuration(s.focusMinutes + (s.focusMinutes >= 60 ? 5 : 1))
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                          TextButton(onPressed: () => showCustomDurationDialog(context, c), child: const Text('Seç')),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Serbest odak'),
                      subtitle: const Text('Süre sınırı olmadan ileri sayar; bitirince kaydedilir'),
                      value: s.freeFocus,
                      onChanged: (v) => c.setFocusDuration(v ? null : s.focusMinutes),
                    ),
                    stepper(
                      'Kısa mola',
                      s.shortBreakMinutes,
                      1,
                      60,
                      'dk',
                      (v) => set(s.copyWith(shortBreakMinutes: v)),
                    ),
                    stepper('Uzun mola', s.longBreakMinutes, 1, 90, 'dk', (v) => set(s.copyWith(longBreakMinutes: v))),
                    stepper(
                      'Uzun mola her',
                      s.longBreakInterval,
                      2,
                      10,
                      'tur',
                      (v) => set(s.copyWith(longBreakInterval: v)),
                    ),
                    stepper('Günlük hedef', s.dailyGoal, 1, 24, 'oturum', (v) => set(s.copyWith(dailyGoal: v))),
                    SwitchListTile(
                      title: const Text('Molaları otomatik başlat'),
                      value: s.autoStartBreaks,
                      onChanged: (v) => set(s.copyWith(autoStartBreaks: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Odağı otomatik başlat'),
                      subtitle: const Text('Mola bitince yeni odak kendiliğinden başlar'),
                      value: s.autoStartFocus,
                      onChanged: (v) => set(s.copyWith(autoStartFocus: v)),
                    ),
                  ],
                ),
              ),

              header('Görünüm'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tema rengi'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final a in AccentTheme.values)
                            Tooltip(
                              message: a.label,
                              child: InkResponse(
                                onTap: () => set(s.copyWith(accent: a)),
                                radius: 26,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: a.forBrightness(Theme.of(context).brightness),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: a == s.accent ? scheme.onSurface : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: a == s.accent ? const Icon(Icons.check_rounded, color: Colors.white) : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Tema'),
                      const SizedBox(height: 10),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Sistem'),
                            icon: Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Açık'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Koyu'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {s.themeMode},
                        onSelectionChanged: (v) => set(s.copyWith(themeMode: v.first)),
                      ),
                    ],
                  ),
                ),
              ),

              header('Arka plan görseli'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _BgTile(
                            label: 'Yok',
                            selected: s.backgroundId == 'none',
                            onTap: () => set(s.copyWith(backgroundId: 'none')),
                            child: Icon(Icons.hide_image_outlined, color: scheme.onSurfaceVariant),
                          ),
                          _BgTile(
                            label: 'Moda göre',
                            selected: s.backgroundId == 'auto',
                            onTap: () => set(s.copyWith(backgroundId: 'auto')),
                            child: Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                          ),
                          for (final sc in Scene.values)
                            _BgTile(
                              label: sc.label,
                              selected: s.backgroundId == 'scene:${sc.name}',
                              onTap: () => set(s.copyWith(backgroundId: 'scene:${sc.name}', focusSound: sc.sound)),
                              child: SizedBox.expand(child: SceneView(scene: sc, animate: false)),
                            ),
                          for (final p in backgroundPresets)
                            _BgTile(
                              label: p.label,
                              selected: s.backgroundId == p.id,
                              onTap: () => set(s.copyWith(backgroundId: p.id)),
                              image: AssetImage(p.image),
                              child: p.video != null
                                  ? const Icon(Icons.play_circle_outline_rounded, color: Colors.white)
                                  : null,
                            ),
                          if (c.hasCustomBackground)
                            _BgTile(
                              label: c.customVideoPath != null ? 'Benim videom' : 'Benim görselim',
                              selected: s.backgroundId == 'custom',
                              onTap: () => set(s.copyWith(backgroundId: 'custom')),
                              onRemove: c.removeCustomBackground,
                              image: c.customBackground != null ? MemoryImage(c.customBackground!) : null,
                              child: c.customVideoPath != null
                                  ? Icon(Icons.movie_rounded, color: scheme.primary)
                                  : null,
                            ),
                          _BgTile(
                            label: 'Fotoğraf seç',
                            selected: false,
                            onTap: () => _pick(context, c.pickCustomBackground),
                            child: Icon(Icons.add_photo_alternate_outlined, color: scheme.primary),
                          ),
                          if (videoSupported && !kIsWeb)
                            _BgTile(
                              label: 'Video seç',
                              selected: false,
                              onTap: () => _pick(context, c.pickCustomVideo),
                              child: Icon(Icons.video_library_outlined, color: scheme.primary),
                            ),
                        ],
                      ),
                      if (s.backgroundId != 'none') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(width: 96, child: Text('Soldurma')),
                            Expanded(
                              child: Slider(
                                value: s.backgroundDim,
                                onChanged: (v) => set(s.copyWith(backgroundDim: v)),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 96, child: Text('Bulanıklık')),
                            Expanded(
                              child: Slider(
                                value: s.backgroundBlur,
                                max: 20,
                                onChanged: (v) => set(s.copyWith(backgroundBlur: v)),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Soldurma, sayaç ve yazıların görselin üstünde rahat okunmasını sağlar.',
                          style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              header('Arka plan sesleri'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Odak sırasında'),
                      const SizedBox(height: 10),
                      SoundPicker(
                        selected: s.focusSound,
                        onSelected: (v) {
                          set(s.copyWith(focusSound: v));
                          if (!c.isRunning) c.audio.preview(v, s.ambientVolume);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('Mola sırasında'),
                      const SizedBox(height: 10),
                      SoundPicker(
                        selected: s.breakSound,
                        onSelected: (v) {
                          set(s.copyWith(breakSound: v));
                          if (!c.isRunning) c.audio.preview(v, s.ambientVolume);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.volume_down_rounded),
                          Expanded(
                            child: Slider(
                              value: s.ambientVolume,
                              onChanged: (v) => set(s.copyWith(ambientVolume: v)),
                            ),
                          ),
                          const Icon(Icons.volume_up_rounded),
                        ],
                      ),
                      Text(
                        'Bir sese dokunduğunda birkaç saniye dinleyebilirsin.',
                        style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              header('Zil ve tebrik'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Teneffüs zili'),
                      subtitle: const Text('Odak bitince ve mola bitince zil çalar'),
                      value: s.bellEnabled,
                      onChanged: (v) {
                        set(s.copyWith(bellEnabled: v));
                        if (v) c.audio.bell(s.bellVolume, s.bellSound);
                      },
                    ),
                    if (s.bellEnabled)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: SegmentedButton<BellSound>(
                          segments: [
                            for (final b in BellSound.values)
                              ButtonSegment(value: b, label: Text(b.label), icon: Icon(b.icon)),
                          ],
                          selected: {s.bellSound},
                          onSelectionChanged: (v) {
                            set(s.copyWith(bellSound: v.first));
                            c.audio.bell(s.bellVolume, v.first);
                          },
                        ),
                      ),
                    if (s.bellEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_rounded, size: 20),
                            Expanded(
                              child: Slider(
                                value: s.bellVolume,
                                onChanged: (v) => set(s.copyWith(bellVolume: v)),
                                onChangeEnd: (v) => c.audio.bell(v, s.bellSound),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SwitchListTile(
                      title: const Text('Tebrik ekranı'),
                      subtitle: const Text('Odak sonunda günlük etüt ve mola özeti ile motivasyon sözü'),
                      value: s.celebrationEnabled,
                      onChanged: (v) => set(s.copyWith(celebrationEnabled: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Alkış sesi'),
                      value: s.applauseEnabled && s.celebrationEnabled,
                      onChanged: s.celebrationEnabled
                          ? (v) {
                              set(s.copyWith(applauseEnabled: v));
                              if (v) c.audio.applause(s.bellVolume);
                            }
                          : null,
                    ),
                  ],
                ),
              ),

              header('Günlük hatırlatma'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Her gün hatırlat'),
                      subtitle: const Text('O gün henüz çalışmadıysan seçtiğin saatte bildirim gelir'),
                      value: s.reminderEnabled,
                      onChanged: (v) => set(s.copyWith(reminderEnabled: v)),
                    ),
                    if (s.reminderEnabled)
                      ListTile(
                        leading: const Icon(Icons.alarm_rounded),
                        title: const Text('Hatırlatma saati'),
                        trailing: Text(
                          '${(s.reminderMinutes ~/ 60).toString().padLeft(2, '0')}:'
                          '${(s.reminderMinutes % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: s.reminderMinutes ~/ 60, minute: s.reminderMinutes % 60),
                            helpText: 'Hatırlatma saati',
                            cancelText: 'Vazgeç',
                            confirmText: 'Tamam',
                            builder: (ctx, child) => MediaQuery(
                              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            ),
                          );
                          if (picked != null) set(s.copyWith(reminderMinutes: picked.hour * 60 + picked.minute));
                        },
                      ),
                  ],
                ),
              ),

              header('Odak modu'),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Odakta bildirimleri kapat'),
                      subtitle: Text(
                        c.focusMode.isSupported
                            ? 'Odak süresince Rahatsız Etme modu açılır, bitince eski haline döner'
                            : 'Bu cihazda sistem ayarından açılması gerekir',
                      ),
                      value: s.doNotDisturb,
                      onChanged: (v) async {
                        set(s.copyWith(doNotDisturb: v));
                        if (v && c.focusMode.isSupported && _dndPermission != true) {
                          await c.focusMode.openPermissionSettings();
                        }
                      },
                    ),
                    if (s.doNotDisturb && c.focusMode.isSupported && _dndPermission == false)
                      ListTile(
                        leading: Icon(Icons.warning_amber_rounded, color: scheme.error),
                        title: const Text('Rahatsız Etme erişimi gerekli'),
                        subtitle: const Text('Açılan listede "Odaklanma Zamanı"ne izin ver, sonra buraya dön.'),
                        trailing: TextButton(
                          onPressed: () async {
                            await c.focusMode.openPermissionSettings();
                          },
                          child: const Text('İzin ver'),
                        ),
                        onTap: _checkDnd,
                      ),
                    if (s.doNotDisturb && !c.focusMode.isSupported)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: OutlinedButton.icon(
                          onPressed: () => showFocusSetupGuide(context),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Otomatik susturmayı kur (1 dakika)'),
                        ),
                      ),
                    SwitchListTile(
                      title: const Text('Ekranı açık tut'),
                      subtitle: const Text('Zamanlayıcı çalışırken ekran kararmaz'),
                      value: s.keepScreenOn,
                      onChanged: (v) => set(s.copyWith(keepScreenOn: v)),
                    ),
                  ],
                ),
              ),
              header('Hakkında'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset('assets/icon/icon.png', width: 64, height: 64),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Odaklanma Zamanı', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Geliştirici: Ahmet Sina Kurt', style: t.bodyMedium),
                            Text('Sürüm 1.0.0', style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Kısayollar: Boşluk başlat/durdur · R sıfırla · S atla',
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Arka plan seçeneği kutucuğu.
class _BgTile extends StatelessWidget {
  const _BgTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.image,
    this.child,
    this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ImageProvider? image;
  final Widget? child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Stack(
              children: [
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 64,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? scheme.primary : scheme.outlineVariant,
                        width: selected ? 3 : 1,
                      ),
                      image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover),
                    ),
                    alignment: Alignment.center,
                    child: child,
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// iPhone/iPad/Mac: Rahatsız Etme'nin uygulama açılınca kendiliğinden açılması için adım adım rehber.
Future<void> showFocusSetupGuide(BuildContext context) {
  final apple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
  Widget step(int n, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          child: Text('$n', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(text)),
        ),
      ],
    ),
  );
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Bildirimleri otomatik sustur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: apple
              ? [
                  const Text(
                    'Apple, uygulamaların bildirimleri kendisi kapatmasına izin vermez. Ama bir kez ayarlarsan '
                    'Odaklanma Zamanı\'nı açtığın anda Rahatsız Etme kendiliğinden açılır, çıkınca kapanır.',
                  ),
                  const SizedBox(height: 12),
                  step(1, 'Ayarlar uygulamasını aç → Odak → Rahatsız Etme.'),
                  step(2, '"Zamanlama Ekle"ye dokun → "Uygulama"yı seç.'),
                  step(3, 'Listeden "Odaklanma Zamanı"nı seç. Hepsi bu!'),
                  const SizedBox(height: 12),
                  Text(
                    'Not: Uygulamayı tarayıcıdan (web linki) kullanıyorsan bu listede görünmez. O zaman odak '
                    'başlarken sağ üstten Denetim Merkezi → Odak → Rahatsız Etme\'ye dokun.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ]
              : [Text(AppScope.read(context).focusMode.manualHint)],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anladım'))],
    ),
  );
}
