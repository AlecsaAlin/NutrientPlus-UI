import 'package:flutter/material.dart';
import 'features/auth/views/splash_screen.dart';

void main() {
  runApp(const NutrientPlusApp());
}

class NutrientPlusApp extends StatelessWidget {
  const NutrientPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutrientPlus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5016),
          brightness: Brightness.light,
        ),
        fontFamily: 'Outfit',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
