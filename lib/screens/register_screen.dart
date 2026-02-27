import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _selectedCity;

  final List<String> _cities = [
    'Dakar','Thies','Saint-Louis','Ziguinchor','Kaolack','Mbour','Touba','Diourbel','Autre',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'city': _selectedCity ?? '',
        },
      );

      if (!mounted) return;

      // Check if email confirmation is required
      if (response.user != null && response.session == null) {
        // Email confirmation required
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.email, color: Color(0xFF00853F)),
                SizedBox(width: 8),
                Text('Confirmez votre email'),
              ],
            ),
            content: Text(
              'Un email de confirmation a ete envoye a:\n\n${_emailCtrl.text.trim()}\n\nVerifiez votre boite mail et cliquez sur le lien de confirmation, puis connectez-vous.',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to login
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F)),
                child: const Text('OK, aller a la connexion', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else if (response.session != null) {
        // Logged in directly (no email confirmation required)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Compte cree avec succes!'),
            backgroundColor: Color(0xFF00853F)));
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      // Make error messages user-friendly
      if (errorMsg.contains('User already registered') || errorMsg.contains('already been registered')) {
        errorMsg = 'Cet email est deja utilise. Essayez de vous connecter.';
      } else if (errorMsg.contains('Password should be')) {
        errorMsg = 'Le mot de passe doit contenir au moins 6 caracteres.';
      } else if (errorMsg.contains('Unable to validate email') || errorMsg.contains('invalid format')) {
        errorMsg = 'Adresse email invalide.';
      } else if (errorMsg.contains('network') || errorMsg.contains('SocketException') || errorMsg.contains('host lookup')) {
        errorMsg = 'Erreur de connexion. Verifiez votre internet.';
      } else if (errorMsg.contains('Signup is disabled')) {
        errorMsg = 'Les inscriptions sont desactivees. Contactez l\'administrateur.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _pass2Ctrl.dispose(); super.dispose();
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
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
                _label('Nom complet *'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _dec('Votre nom complet', Icons.person_outline),
                  validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 14),
                _label('Email *'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('exemple@email.com', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _label('Telephone *'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('+221 77 XXX XX XX', Icons.phone_outlined),
                  validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 14),
                _label('Ville *'),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  hint: const Text('Selectionnez votre ville'),
                  decoration: _dec('', Icons.location_on_outlined),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Selectionnez une ville' : null,
                ),
                const SizedBox(height: 14),
                _label('Mot de passe *'),
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
                _label('Confirmer mot de passe *'),
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

  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
}
