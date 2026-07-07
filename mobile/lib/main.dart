import 'package:flutter/material.dart';

import 'app_root.dart';

void main() {
  runApp(const CampusFoodApp());
}

class CampusFoodApp extends StatelessWidget {
  const CampusFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Food Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}