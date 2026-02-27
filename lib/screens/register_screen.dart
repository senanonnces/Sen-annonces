import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _selectedCity;

  final List<String> _cities = [
    'Dakar', 'Thies', 'Saint-Louis', 'Ziguinchor',
    'Kaolack', 'Mbour', 'Touba', 'Diourbel', 'Autre',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final users = List<Map<String, dynamic>>.from(
        (jsonDecode(usersJson) as List).map((e) => Map<String, dynamic>.from(e))
      );

      final phone = _phoneCtrl.text.trim();

      // Check if phone already registered
      final exists = users.any((u) => u['phone'] == phone);
      if (exists) {
        if (mounted) {
          _showError('Ce numero est deja enregistre. Connectez-vous.');
        }
        return;
      }

      // Create new user
      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameCtrl.text.trim(),
        'phone': phone,
        'password': _passCtrl.text.trim(),
        'city': _selectedCity ?? 'Dakar',
        'created_at': DateTime.now().toIso8601String(),
      };

      users.add(newUser);
      await prefs.setString('users', jsonEncode(users));

      // Auto login after register
      await prefs.setString('current_user', jsonEncode(newUser));
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Compte cree avec succes! Bienvenue!'),
        backgroundColor: Color(0xFF00853F),
      ));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _showError('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF00853F)),
    filled: true, fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00853F), width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: const Text('Creer un compte', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00853F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00853F).withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: Color(0xFF00853F), size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Inscription rapide - pas besoin d\'email!',
                      style: TextStyle(color: Color(0xFF00853F), fontSize: 12, fontWeight: FontWeight.w500),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),
                _lbl('Nom complet *'),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Votre nom complet', Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 14),
                _lbl('Numero de telephone *'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Ex: 0791234567', Icons.phone_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                    if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 8) return 'Numero invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _lbl('Ville *'),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  hint: const Text('Selectionnez votre ville'),
                  decoration: _dec('', Icons.location_on_outlined),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Selectionnez une ville' : null,
                ),
                const SizedBox(height: 14),
                _lbl('Mot de passe *'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: _dec('Min. 6 caracteres', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v.length < 6) return 'Minimum 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _lbl('Confirmer mot de passe *'),
                TextFormField(
                  controller: _pass2Ctrl,
                  obscureText: _obscure,
                  decoration: _dec('Repetez le mot de passe', Icons.lock_outline),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v != _passCtrl.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00853F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text("S'inscrire",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
}
