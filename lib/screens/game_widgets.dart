import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../i18n/strings.dart';
import 'package:confetti/confetti.dart';

class ScoreBoard extends StatelessWidget {
  final String humanSym;
  final String aiSym;
  final int humanScore;
  final int aiScore;
  final String aiLabel;
  const ScoreBoard({
    super.key,
    required this.humanSym,
    required this.aiSym,
    required this.humanScore,
    required this.aiScore,
    this.aiLabel = 'IA DIFÍCIL',
  });

  static const _blue = Color(0xFF00A3FF);
  static const _purple = Color(0xFFC026FF);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        return Container(
          height: compact ? 62 : 70,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F2E), Color(0xFF12082E), Color(0xFF1A0A2E)],
            ),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(-6, 0),
              ),
              BoxShadow(
                color: _purple.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(6, 0),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: CustomPaint(
              painter: _ScoreboardBorderPainter(),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _playerSide(humanSym, L.t('you'), humanScore, _blue),
                    ),
                  ),
                  _VsHexBadge(hx: compact ? 42 : 58, hy: compact ? 38 : 50),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _playerSide(aiSym, aiLabel, aiScore, _purple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _playerSide(String symbol, String label, int score, Color color) {
    final isBlue = color == _blue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBlue) ...[
            _PlayerIcon(symbol: symbol, color: color),
            const SizedBox(width: 8),
            _ScoreText(label: label, color: color),
            const SizedBox(width: 6),
            _ScoreRow(score: score, color: color),
          ] else ...[
            _ScoreRow(score: score, color: color),
            const SizedBox(width: 6),
            _ScoreText(label: label, color: color),
            const SizedBox(width: 8),
            _PlayerIcon(symbol: symbol, color: color),
          ],
        ],
      ),
    );
  }
}

class _ScoreboardBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(35);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, r);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    glow.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.center,
      colors: [ScoreBoard._blue, Colors.transparent],
    ).createShader(rect.outerRect);
    canvas.drawRRect(rect, glow);

    glow.shader = const LinearGradient(
      begin: Alignment.center,
      end: Alignment.centerRight,
      colors: [Colors.transparent, ScoreBoard._purple],
    ).createShader(rect.outerRect);
    canvas.drawRRect(rect, glow);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        colors: [
          ScoreBoard._blue,
          ScoreBoard._purple,
        ],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerIcon extends StatelessWidget {
  final String symbol;
  final Color color;
  const _PlayerIcon({required this.symbol, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color, blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _ScoreText extends StatelessWidget {
  final String label;
  final Color color;
  const _ScoreText({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        shadows: [Shadow(color: color, blurRadius: 8)],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRow({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.emoji_events, size: 13, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: color.withValues(alpha: 0.3), blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

class _VsHexBadge extends StatelessWidget {
  final double hx;
  final double hy;
  const _VsHexBadge({required this.hx, required this.hy});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: hx,
      height: hy,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: _HexClipper(),
            child: Container(
              width: hx,
              height: hy,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ScoreBoard._blue.withValues(alpha: 0.3),
                    ScoreBoard._purple.withValues(alpha: 0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ScoreBoard._blue.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: ScoreBoard._purple.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          ClipPath(
            clipper: _HexClipper(),
            child: Container(
              width: hx - 6,
              height: hy - 6,
              decoration: const BoxDecoration(
                color: Color(0xFF080E22),
              ),
              child: CustomPaint(
                painter: _HexBorderPainter(),
              ),
            ),
          ),
          Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 6),
                Shadow(color: ScoreBoard._blue.withValues(alpha: 0.5), blurRadius: 10),
                Shadow(color: ScoreBoard._purple.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final d = w * 0.25;
    return Path()
      ..moveTo(d, 0)
      ..lineTo(w - d, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - d, h)
      ..lineTo(d, h)
      ..lineTo(0, h / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _HexBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final d = w * 0.25;
    final path = Path()
      ..moveTo(d, 0)
      ..lineTo(w - d, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - d, h)
      ..lineTo(d, h)
      ..lineTo(0, h / 2)
      ..close();

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = const LinearGradient(
        colors: [ScoreBoard._blue, ScoreBoard._purple],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, glowPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = const LinearGradient(
        colors: [ScoreBoard._blue, ScoreBoard._purple],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Board3x3 extends StatelessWidget {
  final List<String> board;
  final List<int>? winLine;
  final bool enabled;
  final ValueChanged<int> onTap;
  const Board3x3({
    super.key,
    required this.board,
    required this.winLine,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final size = (screenW * 0.9).clamp(260.0, 420.0);
    final cell = size / 3;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF05070D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ciano, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.ciano, blurRadius: 28, spreadRadius: -4),
          BoxShadow(color: AppColors.roxo, blurRadius: 22, spreadRadius: -10),
        ],
      ),
      child: Stack(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: 9,
            itemBuilder: (context, i) => _cell(i, cell, (size - 12) / 3),
          ),
          if (winLine != null)
            IgnorePointer(
              child: CustomPaint(
                size: Size(size - 12, size - 12),
                painter: _WinLinePainter(
                  indices: winLine!,
                  color: AppColors.ciano,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(int i, double cell, double inner) {
    final v = board[i];
    final isWin = winLine?.contains(i) ?? false;
    final color = v == 'X' ? AppColors.ciano : AppColors.magenta;
    return GestureDetector(
      onTap: enabled && v == '' ? () => onTap(i) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071B36), Color(0xFF05080F)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWin ? AppColors.ciano : const Color(0xFF123B70),
            width: isWin ? 3 : 2,
          ),
          boxShadow: [
            if (v != '')
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14),
            if (isWin)
              BoxShadow(color: AppColors.ciano, blurRadius: 20, spreadRadius: 1),
          ],
        ),
        child: Center(
          child: v == ''
              ? null
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, val, child) => Transform.scale(
                    scale: val,
                    child: v == 'X'
                        ? _NeonX(size: inner * 0.65)
                        : _NeonO(size: inner * 0.65),
                  ),
                ),
          ),
      ),
    );
  }
}

class _NeonX extends StatelessWidget {
  final double size;
  const _NeonX({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _XPainter(color: AppColors.ciano),
      );
}

class _NeonO extends StatelessWidget {
  final double size;
  const _NeonO({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _OPainter(color: AppColors.magenta),
      );
}

class _XPainter extends CustomPainter {
  final Color color;
  _XPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final inset = size.width * 0.18;
    final pts = [
      [Offset(inset, inset), Offset(size.width - inset, size.height - inset)],
      [Offset(size.width - inset, inset), Offset(inset, size.height - inset)],
    ];
    for (final l in pts) {
      canvas.drawLine(l[0], l[1], glow);
      canvas.drawLine(l[0], l[1], paint);
    }
  }

  @override
  bool shouldRepaint(_XPainter old) => old.color != color;
}

class _OPainter extends CustomPainter {
  final Color color;
  _OPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.32;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = size.width * 0.12;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = size.width * 0.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(c, r, glow);
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(_OPainter old) => old.color != color;
}

class _WinLinePainter extends CustomPainter {
  final List<int> indices;
  final Color color;
  _WinLinePainter({required this.indices, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (indices.length != 3) return;
    const spacing = 5.0;
    final cell = (size.width - spacing * 2) / 3;
    final start = _center(indices.first, cell, spacing);
    final end = _center(indices.last, cell, spacing);
    final glow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = cell * 0.16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()
      ..color = color
      ..strokeWidth = cell * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, glow);
    canvas.drawLine(start, end, line);
  }

  Offset _center(int index, double cell, double spacing) {
    final row = index ~/ 3;
    final col = index % 3;
    return Offset(col * (cell + spacing) + cell / 2,
        row * (cell + spacing) + cell / 2);
  }

  @override
  bool shouldRepaint(_WinLinePainter old) =>
      old.indices != indices || old.color != color;
}

class GameResultBanner extends StatelessWidget {
  final String mainText;
  final String secondaryText;
  final Color color;
  final IconData icon;
  const GameResultBanner({
    super.key,
    required this.mainText,
    required this.secondaryText,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: -4)],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.dourado),
          const SizedBox(height: 6),
          Text(
            mainText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: color,
              shadows: [Shadow(color: color, blurRadius: 18)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayAgainButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PlayAgainButton(this.label, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        decoration: BoxDecoration(
          color: AppColors.ciano,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(color: AppColors.ciano.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 4),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
