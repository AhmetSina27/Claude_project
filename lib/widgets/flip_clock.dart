import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// Çevirmeli (flip) saat renkleri. Kartlar her iki temada da koyu kalır,
/// tıpkı masa üstündeki gerçek bir flip saat gibi.
class FlipColors {
  static const card = Color(0xFF262A3B);
  static const cardTop = Color(0xFF2C3044);
  static const digit = Color(0xFFF3F2EF);
  static const seam = Color(0xFF14172A);
}

const flipDigitStyle = TextStyle(
  fontFamily: 'Oswald',
  fontWeight: FontWeight.w700,
  fontVariations: [FontVariation('wght', 700)],
  color: FlipColors.digit,
  height: 1.0,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Saat · Dakika · Saniye kartlarından oluşan geri sayım göstergesi.
class FlipClock extends StatelessWidget {
  const FlipClock({
    super.key,
    required this.duration,
    this.labelColor,
    this.maxCardSize = 220,
    this.showHours = true,
    this.glass = false,
  });

  final Duration duration;
  final Color? labelColor;
  final double maxCardSize;
  final bool showHours;

  /// Arkada hareketli sahne varken kartlar buzlu cam gibi yarı saydam olur.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final totalSec = (duration.inMilliseconds / 1000).ceil().clamp(0, 359999);
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    final parts = [if (showHours) (two(h), 'SAAT'), (two(m), 'DAKİKA'), (two(s), 'SANİYE')];
    final label = labelColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, box) {
        final gap = (box.maxWidth * .03).clamp(8.0, 24.0);
        final size = min((box.maxWidth - gap * (parts.length - 1)) / parts.length, maxCardSize);
        return Semantics(
          label: 'Kalan süre ${h > 0 ? '$h saat ' : ''}$m dakika $s saniye',
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (value, name)) in parts.indexed) ...[
                if (i > 0) SizedBox(width: gap),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlipCard(value: value, size: size, glass: glass),
                    SizedBox(height: size * .09),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                        fontSize: (size * .12).clamp(11.0, 26.0),
                        letterSpacing: 1.5,
                        color: label,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// İki haneli tek bir çevirmeli kart. Değer değişince üst yarı aşağı katlanır,
/// ardından yeni değerin alt yarısı yerine oturur.
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.value, required this.size, this.glass = false});
  final String value;
  final double size;
  final bool glass;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late String _current = widget.value;
  late String _previous = widget.value;

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.value != _current) {
      _previous = _current;
      _current = widget.value;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _face(String text, double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(w * .06),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: widget.glass
            ? [FlipColors.cardTop.withValues(alpha: .55), FlipColors.card.withValues(alpha: .6)]
            : const [FlipColors.cardTop, FlipColors.card],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      style: flipDigitStyle.copyWith(fontSize: h * .78, letterSpacing: -w * .01),
    ),
  );

  Widget _half(String text, double w, double h, {required bool top, double shade = 0}) => ClipRect(
    child: Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      heightFactor: .5,
      child: Stack(
        children: [
          _face(text, w, h),
          if (shade > 0)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: shade),
                  borderRadius: BorderRadius.circular(w * .06),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = widget.size * .95;
    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * .06),
          boxShadow: widget.glass
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .28),
                    blurRadius: w * .08,
                    offset: Offset(0, w * .03),
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (widget.glass)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(w * .06),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: const ColoredBox(color: Color(0x00000000)),
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_c.value);
                final animating = _c.isAnimating;
                final firstPhase = animating && t < .5;
                final secondPhase = animating && t >= .5;
                return Stack(
                  children: [
                    // Arkadaki sabit yarılar
                    Positioned(top: 0, left: 0, right: 0, child: _half(_current, w, h, top: true)),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _half(firstPhase ? _previous : _current, w, h, top: false, shade: firstPhase ? t * .5 : 0),
                    ),
                    // Aşağı katlanan eski üst yarı
                    if (firstPhase)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .0025)
                            ..rotateX(-pi / 2 * (t / .5)),
                          child: _half(_previous, w, h, top: true, shade: t * .6),
                        ),
                      ),
                    // Yerine oturan yeni alt yarı
                    if (secondPhase)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .0025)
                            ..rotateX(pi / 2 * (1 - (t - .5) / .5)),
                          child: _half(_current, w, h, top: false, shade: (1 - t) * .6),
                        ),
                      ),
                    // Ortadaki menteşe çizgisi
                    Positioned(
                      left: 0,
                      right: 0,
                      top: h / 2 - max(1.0, h * .006),
                      child: Container(height: max(2.0, h * .012), color: FlipColors.seam),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

const _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

/// "24 Kas 2026 17:39:08"
String formatClockLine(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.day} ${_aylar[d.month - 1]} ${d.year} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}
