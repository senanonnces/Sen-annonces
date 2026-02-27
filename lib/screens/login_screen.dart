import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  String _phoneToEmail(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'user_$clean@senannonces.app';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _phoneToEmail(_phoneCtrl.text.trim());
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString();

      String errorMsg;
      if (rawError.contains('Invalid login credentials') || rawError.contains('invalid_credentials')) {
        errorMsg = 'Numero ou mot de passe incorrect.';
      } else if (rawError.contains('Email not confirmed')) {
        errorMsg = 'Compte non confirme.';
      } else if (rawError.contains('SocketException') || rawError.contains('host lookup') || rawError.contains('Connection refused') || rawError.contains('Network is unreachable')) {
        errorMsg = 'Pas de connexion internet.';
      } else if (rawError.contains('Too many requests')) {
        errorMsg = 'Trop de tentatives. Attendez quelques minutes.';
      } else {
        // Show real error for debugging
        errorMsg = rawError.replaceAll('AuthException:', '').replaceAll('Exception:', '').trim();
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur connexion'),
          ]),
          content: SelectableText(errorMsg, style: const TextStyle(fontSize: 13)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F)),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00853F),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.campaign, size: 55, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(child: Text('Sen Annonces',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00853F)))),
                const SizedBox(height: 6),
                const Center(child: Text('Connectez-vous avec votre telephone',
                    style: TextStyle(fontSize: 14, color: Colors.grey))),
                const SizedBox(height: 40),
                const Text('Numero de telephone', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+221 77 XXX XX XX',
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF00853F)),
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00853F), width: 2)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (clean.length < 8) return 'Numero invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00853F)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00853F), width: 2)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v.length < 6) return 'Minimum 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00853F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Se connecter',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte? ', style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text("S'inscrire",
                          style: TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
