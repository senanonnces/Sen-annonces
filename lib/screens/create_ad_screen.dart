import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../main.dart';

class CreateAdScreen extends StatefulWidget {
  final VoidCallback onAdCreated;
  final Map<String, dynamic>? currentUser;
  const CreateAdScreen({super.key, required this.onAdCreated, this.currentUser});
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
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // Car fields
  String? _carBrand, _carModel, _carYear, _carCondition;
  final _kmCtrl = TextEditingController();

  // Real estate fields
  String? _propType, _propDeal;
  final _surfaceCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();

  // Electronics fields
  String? _techCondition;
  final _brandCtrl = TextEditingController();

  // Employment fields
  String? _jobType;
  final _salaryCtrl = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      _phoneCtrl.text = widget.currentUser!['phone'] ?? '';
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _images = picked.map((x) => File(x.path)).toList());
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (int i = 0; i < _images.length; i++) {
      try {
        final bytes = await _images[i].readAsBytes();
        final fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await supabase.storage.from('listings').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        final url = supabase.storage.from('listings').getPublicUrl(fileName);
        urls.add(url);
      } catch (e) {
        // skip failed image
      }
    }
    return urls;
  }

  Future<void> _publishAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Selectionnez une categorie');
      return;
    }
    setState(() => _loading = true);

    try {
      // Upload images
      List<String> imageUrls = await _uploadImages();

      // Build attributes
      Map<String, dynamic> attributes = {};
      if (_selectedCategory == 'Voitures') {
        attributes = {
          'brand': _carBrand, 'model': _carModel,
          'year': _carYear, 'km': _kmCtrl.text, 'condition': _carCondition,
        };
      } else if (_selectedCategory == 'Immobilier') {
        attributes = {
          'type': _propType, 'deal': _propDeal,
          'surface': _surfaceCtrl.text, 'rooms': _roomsCtrl.text,
        };
      } else if (_selectedCategory == 'Electronique') {
        attributes = {'brand': _brandCtrl.text, 'condition': _techCondition};
      } else if (_selectedCategory == 'Emploi') {
        attributes = {'job_type': _jobType, 'salary': _salaryCtrl.text};
      }

      final userId = widget.currentUser?['id'];
      final ad = {
        'user_id': userId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'category': _selectedCategory!.toLowerCase(),
        'location_city': _selectedCity ?? 'Dakar',
        'phone': _phoneCtrl.text.trim(),
        'images': imageUrls,
        'attributes': attributes,
        'is_boosted': false,
      };

      await supabase.from('listings').insert(ad);

      widget.onAdCreated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Annonce publiee avec succes!'),
          backgroundColor: Color(0xFF00853F),
        ));
        Navigator.pop(context);
      }
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        foregroundColor: Colors.white,
        title: const Text('Publier une annonce'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Categorie *'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final active = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? cat['color'] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData, size: 16, color: active ? Colors.white : Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(cat['name'], style: TextStyle(color: active ? Colors.white : Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Photos'),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: _images.isEmpty
                      ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                          Text('Ajouter des photos', style: TextStyle(color: Colors.grey)),
                        ]))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_images[i], width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(_titleCtrl, 'Titre *', Icons.title,
                  validator: (v) => (v == null || v.isEmpty) ? 'Titre requis' : null),
              const SizedBox(height: 12),
              _buildField(_priceCtrl, 'Prix (FCFA) *', Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Prix requis' : null),
              const SizedBox(height: 12),
              _buildField(_descCtrl, 'Description', Icons.description, maxLines: 3),
              const SizedBox(height: 12),
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
              ),
              const SizedBox(height: 12),
              _buildField(_phoneCtrl, 'Telephone vendeur *', Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Telephone requis' : null),

              // Category-specific fields
              if (_selectedCategory == 'Voitures') ..._buildCarFields(),
              if (_selectedCategory == 'Immobilier') ..._buildRealEstateFields(),
              if (_selectedCategory == 'Electronique') ..._buildElectroFields(),
              if (_selectedCategory == 'Emploi') ..._buildJobFields(),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _publishAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00853F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Publier l\'annonce', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCarFields() => [
    const SizedBox(height: 16),
    _sectionTitle('Details Vehicule'),
    Row(children: [
      Expanded(child: _buildDropdown('Marque', ['Toyota', 'Peugeot', 'Renault', 'Mercedes', 'BMW', 'Honda', 'Hyundai', 'Kia', 'Nissan', 'Ford', 'Autre'],
          _carBrand, (v) => setState(() => _carBrand = v))),
      const SizedBox(width: 8),
      Expanded(child: _buildField(_kmCtrl, 'Kilometrage', Icons.speed, keyboardType: TextInputType.number)),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: _buildDropdown('Annee', List.generate(30, (i) => (2025 - i).toString()),
          _carYear, (v) => setState(() => _carYear = v))),
      const SizedBox(width: 8),
      Expanded(child: _buildDropdown('Etat', ['Neuf', 'Tres bon', 'Bon', 'Acceptable'],
          _carCondition, (v) => setState(() => _carCondition = v))),
    ]),
  ];

  List<Widget> _buildRealEstateFields() => [
    const SizedBox(height: 16),
    _sectionTitle('Details Immobilier'),
    Row(children: [
      Expanded(child: _buildDropdown('Type', ['Appartement', 'Villa', 'Studio', 'Maison', 'Terrain', 'Bureau'],
          _propType, (v) => setState(() => _propType = v))),
      const SizedBox(width: 8),
      Expanded(child: _buildDropdown('Transaction', ['Vente', 'Location'],
          _propDeal, (v) => setState(() => _propDeal = v))),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: _buildField(_surfaceCtrl, 'Surface (m²)', Icons.square_foot, keyboardType: TextInputType.number)),
      const SizedBox(width: 8),
      Expanded(child: _buildField(_roomsCtrl, 'Nb pieces', Icons.bed, keyboardType: TextInputType.number)),
    ]),
  ];

  List<Widget> _buildElectroFields() => [
    const SizedBox(height: 16),
    _sectionTitle('Details Electronique'),
    Row(children: [
      Expanded(child: _buildField(_brandCtrl, 'Marque', Icons.business)),
      const SizedBox(width: 8),
      Expanded(child: _buildDropdown('Etat', ['Neuf', 'Tres bon', 'Bon', 'Acceptable'],
          _techCondition, (v) => setState(() => _techCondition = v))),
    ]),
  ];

  List<Widget> _buildJobFields() => [
    const SizedBox(height: 16),
    _sectionTitle('Details Emploi'),
    Row(children: [
      Expanded(child: _buildDropdown('Type contrat', ['CDI', 'CDD', 'Stage', 'Freelance', 'Temps partiel'],
          _jobType, (v) => setState(() => _jobType = v))),
      const SizedBox(width: 8),
      Expanded(child: _buildField(_salaryCtrl, 'Salaire (FCFA)', Icons.monetization_on, keyboardType: TextInputType.number)),
    ]),
  ];

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {
    TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }
}
