import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateAdScreen extends StatefulWidget {
  final VoidCallback onAdCreated;
  const CreateAdScreen({super.key, required this.onAdCreated});
  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _selectedCategory;
  String? _selectedCity;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Voitures', 'icon': Icons.directions_car, 'color': Color(0xFF1565C0)},
    {'name': 'Immobilier', 'icon': Icons.home, 'color': Color(0xFF6A1B9A)},
    {'name': 'Electronique', 'icon': Icons.phone_android, 'color': Color(0xFF00838F)},
    {'name': 'Emploi', 'icon': Icons.work, 'color': Color(0xFFE65100)},
    {'name': 'Mode', 'icon': Icons.checkroom, 'color': Color(0xFFC2185B)},
    {'name': 'Maison', 'icon': Icons.chair, 'color': Color(0xFF558B2F)},
    {'name': 'Sport', 'icon': Icons.sports_soccer, 'color': Color(0xFF1976D2)},
    {'name': 'Animaux', 'icon': Icons.pets, 'color': Color(0xFF5D4037)},
    {'name': 'Services', 'icon': Icons.build, 'color': Color(0xFF37474F)},
    {'name': 'Autre', 'icon': Icons.more_horiz, 'color': Color(0xFF757575)},
  ];

  final List<String> _cities = [
    'Dakar', 'Thies', 'Saint-Louis', 'Ziguinchor',
    'Kaolack', 'Mbour', 'Touba', 'Diourbel', 'Autre',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selectionnez une categorie'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      final user = userJson != null ? jsonDecode(userJson) : null;

      final adsJson = prefs.getString('ads') ?? '[]';
      final ads = List<Map<String, dynamic>>.from(
          (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));

      final newAd = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleCtrl.text.trim(),
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : user?['phone'] ?? '',
        'category': _selectedCategory,
        'city': _selectedCity ?? user?['city'] ?? 'Dakar',
        'user_id': user?['id'] ?? '',
        'seller_name': user?['name'] ?? 'Vendeur',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      ads.insert(0, newAd);
      await prefs.setString('ads', jsonEncode(ads));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Annonce publiee avec succes!'),
          backgroundColor: Color(0xFF00853F)));

      // Reset form
      _titleCtrl.clear();
      _priceCtrl.clear();
      _descCtrl.clear();
      _phoneCtrl.clear();
      setState(() { _selectedCategory = null; _selectedCity = null; });

      widget.onAdCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _priceCtrl.dispose();
    _descCtrl.dispose(); _phoneCtrl.dispose();
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
        automaticallyImplyLeading: false,
        title: const Text('Publier une annonce', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category selection
                _sectionTitle('Categorie *'),
                SizedBox(
                  height: 105,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 1.2,
                      crossAxisSpacing: 6, mainAxisSpacing: 6,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? cat['color'] as Color : (cat['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? Border.all(color: cat['color'] as Color, width: 2) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat['icon'] as IconData,
                                  color: isSelected ? Colors.white : cat['color'] as Color, size: 20),
                              const SizedBox(height: 3),
                              Text(cat['name'] as String,
                                  style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : cat['color'] as Color,
                                  ), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle('Titre de l\'annonce *'),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _dec('Ex: iPhone 14 Pro Max 256GB', Icons.title),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 14),
                _sectionTitle('Prix (FCFA) *'),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Ex: 150000', Icons.attach_money),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                    if (int.tryParse(v.trim()) == null) return 'Prix invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _sectionTitle('Description *'),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: _dec('Decrivez votre article en detail...', Icons.description),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 14),
                _sectionTitle('Telephone de contact'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Numero de contact (optionnel)', Icons.phone),
                ),
                const SizedBox(height: 14),
                _sectionTitle('Ville'),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  hint: const Text('Selectionnez une ville'),
                  decoration: _dec('', Icons.location_on_outlined),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.publish, color: Colors.white),
                    label: Text(_loading ? 'Publication...' : 'Publier l\'annonce',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00853F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));
}
