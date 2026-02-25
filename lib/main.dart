import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00853F),
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF00853F),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Sen Annonces',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Petites annonces au Senegal',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
