import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});
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
    {'name': 'Voitures', 'icon': Icons.directions_car},
    {'name': 'Immobilier', 'icon': Icons.home_work},
    {'name': 'Electronique', 'icon': Icons.phone_android},
    {'name': 'Emploi', 'icon': Icons.work_outline},
    {'name': 'Mode', 'icon': Icons.checkroom},
    {'name': 'Maison', 'icon': Icons.chair_alt},
    {'name': 'Sport', 'icon': Icons.sports_soccer},
    {'name': 'Animaux', 'icon': Icons.pets},
    {'name': 'Services', 'icon': Icons.construction},
    {'name': 'Education', 'icon': Icons.school_outlined},
    {'name': 'Agriculture', 'icon': Icons.agriculture},
    {'name': 'Autres', 'icon': Icons.more_horiz},
  ];

  final List<String> _cities = [
    'Dakar', 'Thies', 'Saint-Louis', 'Ziguinchor',
    'Kaolack', 'Mbour', 'Touba', 'Diourbel', 'Autre',
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selectionnez une categorie'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('annonces').insert({
        'title': _titleCtrl.text.trim(),
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'category': _selectedCategory,
        'city': _selectedCity ?? 'Dakar',
        'user_id': user?.id,
        'is_active': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce publiee avec succes!'),
            backgroundColor: Color(0xFF00853F),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: const Text('Publier une annonce',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('1. Choisissez une categorie'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['name'] as String),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00853F)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData,
                              color: selected ? Colors.white : Colors.grey,
                              size: 24),
                          const SizedBox(height: 4),
                          Text(cat['name'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('2. Informations'),
              _buildLabel('Titre *'),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDec('Ex: Toyota Corolla 2019'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 14),
              _buildLabel('Prix (FCFA) *'),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec('Ex: 500000'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 14),
              _buildLabel('Ville *'),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                hint: const Text('Selectionnez votre ville'),
                decoration: _inputDec(''),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                validator: (v) =>
                    v == null ? 'Selectionnez une ville' : null,
              ),
              const SizedBox(height: 14),
              _buildLabel('Telephone *'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDec('+221 77 XXX XX XX'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 14),
              _buildLabel('Description *'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: _inputDec('Decrivez votre annonce en detail...'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.publish, color: Colors.white),
                  label: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Publier l annonce',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00853F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00853F))));

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));

  InputDecoration _inputDec(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF00853F), width: 2)));
}
