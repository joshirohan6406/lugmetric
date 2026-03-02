import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const LugMetricApp());
}

class LugMetricApp extends StatelessWidget {
  const LugMetricApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LugMetric',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        fontFamily: "Roboto",
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D7CFF),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D7CFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
