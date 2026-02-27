import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
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

    try {
      final phone = _phoneCtrl.text.trim();
      final name = _nameCtrl.text.trim();
      final city = _selectedCity ?? 'Dakar';

      // Check if phone already exists in Supabase
      final existing = await supabase
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        _showError('Ce numero est deja enregistre. Connectez-vous.');
        return;
      }

      // Insert new user to Supabase
      final newUser = await supabase
          .from('users')
          .insert({
            'name': name,
            'phone': phone,
            'password': _passCtrl.text.trim(),
            'city': city,
          })
          .select()
          .single();

      // Save locally for session
      final prefs = await SharedPreferences.getInstance();
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
      _showError('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00853F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        foregroundColor: Colors.white,
        title: const Text('Creer un compte'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.campaign, size: 60, color: Colors.white),
                const SizedBox(height: 8),
                const Text('Sen Annonces',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildCard(
                  child: Column(
                    children: [
                      _buildField(controller: _nameCtrl, label: 'Nom complet', icon: Icons.person,
                          validator: (v) => (v == null || v.isEmpty) ? 'Nom requis' : null),
                      const SizedBox(height: 16),
                      _buildField(controller: _phoneCtrl, label: 'Telephone (+221...)', icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.length < 9) ? 'Numero invalide' : null),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'Ville',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: Colors.grey[50],
                        ),
                        items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCity = v),
                        validator: (v) => v == null ? 'Selectionnez une ville' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(controller: _passCtrl, label: 'Mot de passe', icon: Icons.lock,
                          obscureText: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 caracteres' : null),
                      const SizedBox(height: 16),
                      _buildField(controller: _pass2Ctrl, label: 'Confirmer mot de passe', icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (v) => v != _passCtrl.text ? 'Les mots de passe ne correspondent pas' : null),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00853F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Color(0xFF00853F))
                        : const Text('Creer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: child,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
