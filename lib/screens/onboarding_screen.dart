import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../scenes/scenes.dart';
import '../widgets/flip_clock.dart';

/// İlk açılışta bir kez gösterilen 3 sayfalık tanıtım.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  const _Page(this.scene, this.title, this.text, this.icon);
  final Scene scene;
  final String title;
  final String text;
  final IconData icon;
}

const _pages = [
  _Page(
    Scene.gece,
    'Zamanı çevir,\nodağını bul.',
    'Masandaki gerçek bir saat gibi dönen kartlar. 15 dakikadan 5 saate kadar istediğin süreyi seç ya da Serbest modda süresiz çalış.',
    Icons.timer_rounded,
  ),
  _Page(
    Scene.kutuphane,
    'Sahneni ve sesini seç.',
    'Kütüphane, şömine, su altı, kiraz çiçekleri… Sayacın arkasında hareketli sahneler, kulağında ders çalışmayı bozmayan sakin sesler.',
    Icons.landscape_rounded,
  ),
  _Page(
    Scene.kiraz,
    'Her oturum bir zafer.',
    'Odak bitince teneffüs zili çalar; günlük etüt süren, serin ve ilham veren bir söz seni bekler. Süre dolunca haber verebilmemiz için bildirimlere izin ver.',
    Icons.workspace_premium_rounded,
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _pager.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } else {
      AppScope.read(context).completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1E),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: SceneView(key: ValueKey(_pages[_index].scene), scene: _pages[_index].scene),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .15), Colors.black.withValues(alpha: .7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => AppScope.read(context).completeOnboarding(),
                    child: const Text('Atla', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i == 0)
                                  const SizedBox(
                                    width: 300,
                                    child: FlipClock(
                                      duration: Duration(minutes: 25),
                                      maxCardSize: 92,
                                      glass: true,
                                      labelColor: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(p.icon, size: 72, color: accent),
                                const SizedBox(height: 28),
                                Text(
                                  p.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 40,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                    fontVariations: [FontVariation('wght', 700)],
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  p.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFFE6E3EE), fontSize: 17, height: 1.45),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _pages.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: i == _index ? 22 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: i == _index ? accent : Colors.white38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _next,
                            child: Text(
                              last ? 'Başla' : 'Devam',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
