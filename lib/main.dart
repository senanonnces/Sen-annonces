import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hzmfxjpxejjmqzfjtsck.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6bWZ4anB4ZWpqbXF6Zmp0c2NrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA1MTQ3MzgsImV4cCI6MjA1NjA5MDczOH0.Vo3X56d4mqdnSe3xJCjD56nqzqm2g0VjMmfF8eRjpgU',
  );
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
