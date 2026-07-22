import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

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
