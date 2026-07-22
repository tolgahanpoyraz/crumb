import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_root.dart';
import 'theme/app_theme.dart';

void main() {
  // Fonts are bundled in assets/google_fonts, so resolve them offline
  // instead of fetching at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const CampusFoodApp());
}

class CampusFoodApp extends StatelessWidget {
  const CampusFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crumb',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppRoot(),
    );
  }
}
