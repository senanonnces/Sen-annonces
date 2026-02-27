import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

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
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 70, limit: 4);
      if (picked.isNotEmpty) {
        setState(() {
          _images = picked.map((x) => File(x.path)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 70);
      if (photo != null) {
        setState(() {
          _images.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur camera: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF00853F),
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choisir depuis la galerie'),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(context); _pickFromCamera(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Validate category first
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Text('Veuillez choisir une categorie!'),
          ]),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      final user = userJson != null ? jsonDecode(userJson) : null;

      final adsJson = prefs.getString('ads') ?? '[]';
      final ads = List<Map<String, dynamic>>.from(
          (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));

      // Convert images to base64 for local storage (max 3 images, compressed)
      final List<String> imagePaths = _images.map((f) => f.path).toList();

      final newAd = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleCtrl.text.trim(),
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'category': _selectedCategory,
        'city': _selectedCity ?? user?['city'] ?? 'Dakar',
        'user_id': user?['id'] ?? '',
        'seller_name': user?['name'] ?? 'Vendeur',
        'image_paths': imagePaths,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      ads.insert(0, newAd);
      await prefs.setString('ads', jsonEncode(ads));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Annonce publiee avec succes!'),
        ]),
        backgroundColor: Color(0xFF00853F),
        duration: Duration(seconds: 3),
      ));

      // Reset
      _titleCtrl.clear(); _priceCtrl.clear();
      _descCtrl.clear(); _phoneCtrl.clear();
      setState(() { _selectedCategory = null; _selectedCity = null; _images = []; });

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

  InputDecoration _dec(String hint, IconData icon, {bool required = false}) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF00853F)),
    filled: true, fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00853F), width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        automaticallyImplyLeading: false,
        title: const Text('Publier une annonce',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ===== STEP 1: CATEGORY =====
                _stepHeader('1', 'Choisir une categorie', required: true),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                          color: isSelected ? cat['color'] as Color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat['color'] as Color : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: (cat['color'] as Color).withOpacity(0.3),
                                blurRadius: 8, offset: const Offset(0, 3))
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'] as IconData,
                                color: isSelected ? Colors.white : cat['color'] as Color,
                                size: 22),
                            const SizedBox(height: 3),
                            Text(cat['name'] as String,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00853F), size: 16),
                      const SizedBox(width: 4),
                      Text('Categorie: $_selectedCategory',
                          style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                const SizedBox(height: 20),

                // ===== STEP 2: PHOTOS =====
                _stepHeader('2', 'Ajouter des photos (optionnel)'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add photo button
                      GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          width: 100, height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.grey[400], size: 32),
                              const SizedBox(height: 4),
                              Text('Ajouter\nphoto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      // Selected images
                      ..._images.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final img = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 100, height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(img), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ===== STEP 3: DETAILS =====
                _stepHeader('3', 'Details de l\'annonce'),
                const SizedBox(height: 10),
                _fieldLabel('Titre *'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec('Ex: iPhone 14 Pro Max 256GB', Icons.title),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est obligatoire' : null,
                ),
                const SizedBox(height: 12),
                _fieldLabel('Prix (FCFA) *'),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Ex: 150000', Icons.payments_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Le prix est obligatoire';
                    if (int.tryParse(v.trim()) == null) return 'Entrez un prix valide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _fieldLabel('Description *'),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: _dec('Decrivez votre article: etat, caracteristiques...', Icons.description_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'La description est obligatoire';
                    if (v.trim().length < 10) return 'Description trop courte (min 10 caracteres)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _fieldLabel('Telephone de contact *'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('+221 77 XXX XX XX', Icons.phone_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Le telephone est obligatoire';
                    if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 8) return 'Numero invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _fieldLabel('Ville *'),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  hint: const Text('Selectionnez votre ville'),
                  decoration: _dec('', Icons.location_on_outlined),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Selectionnez une ville' : null,
                ),
                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00853F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    child: _loading
                        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Publication...', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ])
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.publish, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Publier l\'annonce',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
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

  Widget _stepHeader(String step, String title, {bool required = false}) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: Color(0xFF00853F), shape: BoxShape.circle),
          child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)));
}
