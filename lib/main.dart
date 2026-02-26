import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SenAnnoncesApp());
}

class SenAnnoncesApp extends StatelessWidget {
  const SenAnnoncesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sen Annonces',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00853F)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
