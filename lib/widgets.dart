import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class NeonBackground extends StatelessWidget {
  final Widget child;
  const NeonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.3,
          colors: [Color(0xFF0D1B2A), AppColors.bgMain, Color(0xFF050508)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const CustomPaint(size: Size.infinite, painter: _NeonGridPainter()),
          child,
        ],
      ),
    );
  }
}

class ParticleLayer extends StatefulWidget {
  final Widget child;
  const ParticleLayer({super.key, required this.child});

  @override
  State<ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _r = Random(7);
  late final List<_P> _ps;

  @override
  void initState() {
    super.initState();
    _ps = List.generate(24, (_) => _P.random(_r));
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(_ps, _controller.value),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _P {
  final double x, y;
  final double size;
  final Color color;
  final double speed;
  _P(this.x, this.y, this.size, this.color, this.speed);
  factory _P.random(Random r) {
    const colors = [
      AppColors.ciano,
      AppColors.roxoNeon,
      Colors.white,
      AppColors.verde,
    ];
    return _P(
      r.nextDouble(),
      r.nextDouble(),
      1.5 + r.nextDouble() * 3,
      colors[r.nextInt(colors.length)],
      0.5 + r.nextDouble() * 1.0,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_P> ps;
  final double t;
  _ParticlePainter(this.ps, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < ps.length; i++) {
      final p = ps[i];
      final y = (p.y - t * 0.08 * p.speed) % 1.0;
      final op = 0.2 + 0.6 * ((y < 0 ? y + 1 : y).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        Paint()
          ..color = p.color.withValues(alpha: op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

class _NeonGridPainter extends CustomPainter {
  const _NeonGridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1200AFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gap = 60.0;
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonGridPainter old) => false;
}

class NeonTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool uppercase;
  const NeonTitle(this.text,
      {super.key, this.fontSize = 40, this.uppercase = false});

  @override
  Widget build(BuildContext context) {
    final t = uppercase ? text.toUpperCase() : text;
    return Text(
      t,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.ciano, AppColors.roxo, AppColors.magenta],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(0, 0, 400, 100)),
        shadows: [
          Shadow(color: Color(0x6600F0FF), blurRadius: 25),
          Shadow(color: Color(0x66D500FF), blurRadius: 35),
        ],
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final Color? startColor;
  final Color? endColor;
  final IconData? icon;
  const NeonButton(
    this.label,
    this.onTap, {
    super.key,
    this.height = 60,
    this.fontSize = 20,
    this.startColor = const Color(0xFF00E5FF),
    this.endColor = const Color(0xFF9B00FF),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(height / 2),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            colors: [startColor!, endColor!],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.ciano, blurRadius: 22, spreadRadius: -2),
            BoxShadow(color: AppColors.roxo, blurRadius: 18, spreadRadius: -6),
          ],
        ),
        child: Container(
          height: height,
          alignment: Alignment.center,
          child: icon == null
              ? Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: fontSize + 4),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// "JOGAR NOVAMENTE" button styled per design spec:
/// glossy pill, 4-stop horizontal gradient, white outline, drop shadow,
/// inner glow. Uses a plain Container (no Ink) so the gradient always paints.
class PlayAgainButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PlayAgainButton(this.label, {super.key, required this.onTap});

  static const Radius _radius = Radius.circular(9999);
  static const _gradientColors = [
    Color(0xFF1E90FF),
    Color(0xFF00BFFF),
    Color(0xFF8A2BE2),
    Color(0xFFDA70D6),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(_radius),
          child: Container(
            constraints: const BoxConstraints(minWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: _gradientColors,
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xEEFFFFFF), width: 1.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x40FFFFFF),
                  blurRadius: 10,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                    fontSize: 18,
                    shadows: [
                      Shadow(color: Color(0x80000000), blurRadius: 4),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final bool highlighted;
  const NeonCard(
    this.child, {
    super.key,
    this.borderColor = AppColors.azulNeon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? AppColors.magenta : borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (highlighted ? AppColors.magenta : borderColor)
                .withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: -3,
          ),
        ],
      ),
      child: child,
    );
  }
}

class NeonIconTile extends StatelessWidget {
  final Widget icon;
  const NeonIconTile(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bgCard, Color(0xFF101E38)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.azulNeon, width: 1.2),
        boxShadow: [
          BoxShadow(color: Color(0x4400AFFF), blurRadius: 10, spreadRadius: -2)
        ],
      ),
      child: Center(child: icon),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const ScreenHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackButton(
          onPressed: onBack ?? () => Navigator.pop(context),
          color: Colors.white,
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: NeonTitle(title, fontSize: 26, uppercase: true),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}
