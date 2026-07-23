import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

/// The crumb leaf mark from the design handoff, drawn on a 24×24 grid.
class CrumbLogoMark extends StatelessWidget {
  const CrumbLogoMark({super.key, this.size = 21, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrumbLogoPainter(color),
    );
  }
}

class _CrumbLogoPainter extends CustomPainter {
  const _CrumbLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final leaf = Path()
      ..moveTo(5, 19)
      ..cubicTo(5, 11.3, 11.3, 5, 19, 5)
      ..cubicTo(19, 12.7, 12.7, 19, 5, 19)
      ..close();

    final vein = Path()
      ..moveTo(5, 19)
      ..cubicTo(7.8, 14, 11.8, 10.6, 16, 9.3);

    canvas.scale(size.width / 24);
    canvas.drawPath(leaf, paint);
    canvas.drawPath(vein, paint);
  }

  @override
  bool shouldRepaint(_CrumbLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

class CrumbWordmark extends StatelessWidget {
  const CrumbWordmark({super.key, this.fontSize = 34});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'crumb',
      style: GoogleFonts.fredoka(
        color: AppColors.coral,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: fontSize * -0.03,
      ),
    );
  }
}
