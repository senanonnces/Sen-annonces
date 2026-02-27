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
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _selectedCity;

  final List<String> _cities = [
    'Dakar','Thies','Saint-Louis','Ziguinchor','Kaolack','Mbour','Touba','Diourbel','Autre',
  ];

  // Generate a fake unique email from phone number to bypass email confirmation
  String _phoneToEmail(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'user_$clean@senannonces.app';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final fakeEmail = _phoneToEmail(_phoneCtrl.text.trim());
    final password = _passCtrl.text.trim();

    try {
      // Try to sign up first
      final response = await Supabase.instance.client.auth.signUp(
        email: fakeEmail,
        password: password,
        data: {
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'city': _selectedCity ?? 'Dakar',
          'display_name': _nameCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.session != null) {
        // Logged in directly - success!
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Compte cree avec succes! Bienvenue!'),
            backgroundColor: Color(0xFF00853F)));
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
      } else {
        // Email confirmation required - try sign in instead
        // (user may already be registered)
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: fakeEmail,
            password: password,
          );
          if (mounted) {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Compte cree! Connectez-vous maintenant avec votre telephone et mot de passe.'),
              backgroundColor: Color(0xFF00853F),
              duration: Duration(seconds: 4),
            ));
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();

      if (errorMsg.contains('already registered') || errorMsg.contains('already been registered')) {
        // Account exists - try to login directly
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: fakeEmail,
            password: password,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Connexion reussie!'),
                backgroundColor: Color(0xFF00853F)));
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
          }
          return;
        } catch (loginErr) {
          errorMsg = 'Ce numero est deja enregistre. Verifiez votre mot de passe.';
        }
      } else if (errorMsg.contains('network') || errorMsg.contains('SocketException') || errorMsg.contains('host lookup') || errorMsg.contains('Failed')) {
        errorMsg = 'Erreur de connexion internet. Verifiez votre connexion et reessayez.';
      } else if (errorMsg.contains('Password should be') || errorMsg.contains('weak_password')) {
        errorMsg = 'Mot de passe trop faible. Utilisez au moins 6 caracteres.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
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
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00853F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00853F).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_android, color: Color(0xFF00853F), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inscription par numero de telephone - pas besoin d\'email!',
                          style: TextStyle(color: Color(0xFF00853F), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _label('Nom complet *'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _dec('Votre nom complet', Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 14),
                _label('Numero de telephone *'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('+221 77 XXX XX XX', Icons.phone_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                    final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (clean.length < 8) return 'Numero invalide (minimum 8 chiffres)';
                    return null;
                  },
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
