import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'boost_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  final Function(String) onFavoriteToggle;
  final bool isFavorite;
  const AdDetailScreen({super.key, required this.ad, required this.onFavoriteToggle, required this.isFavorite});
  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  late bool _isFav;
  int _currentImageIndex = 0;
  bool _isMyAd = false;
  late Map<String, dynamic> _ad;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
    _ad = Map<String, dynamic>.from(widget.ad);
    _checkIfMyAd();
  }

  Future<void> _checkIfMyAd() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      final user = jsonDecode(userJson);
      setState(() => _isMyAd = user['id'] == _ad['user_id']);
    }
  }

  bool get _isBoosted {
    if (_ad['is_boosted'] != true) return false;
    final expiry = _ad['boost_expiry'];
    if (expiry == null) return false;
    try {
      return DateTime.parse(expiry).isAfter(DateTime.now());
    } catch (_) { return false; }
  }

  String get _boostPlan => _ad['boost_plan']?.toString() ?? '';

  String _formatPrice(dynamic price) {
    if (price == null) return '0 FCFA';
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M FCFA';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K FCFA';
    return '$p FCFA';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays} jour(s)';
    } catch (_) { return ''; }
  }

  Future<void> _launchCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    try { await launchUrl(Uri.parse('tel:$clean')); }
    catch (_) {}
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    try { await launchUrl(Uri.parse('https://wa.me/$clean'), mode: LaunchMode.externalApplication); }
    catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp non disponible')));
    }
  }

  void _showContact() {
    final phone = _ad['phone'] ?? _ad['seller_phone'] ?? 'Non disponible';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          CircleAvatar(radius: 32,
              backgroundColor: const Color(0xFF00853F).withOpacity(0.1),
              child: Text((_ad['seller_name']?.toString() ?? 'V').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 24))),
          const SizedBox(height: 12),
          Text(_ad['seller_name'] ?? 'Vendeur',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(phone, style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); _launchCall(phone); },
              icon: const Icon(Icons.phone, color: Colors.white),
              label: const Text('Appeler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00853F),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); _launchWhatsApp(phone); },
              icon: const Icon(Icons.message, color: Colors.white),
              label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _openBoost() async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => BoostScreen(ad: _ad)));
    if (result == true) {
      // Reload ad from SharedPreferences to get updated boost info
      final prefs = await SharedPreferences.getInstance();
      final adsJson = prefs.getString('ads') ?? '[]';
      final ads = List<Map<String, dynamic>>.from(
          (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));
      final updatedAd = ads.firstWhere((a) => a['id'] == _ad['id'], orElse: () => _ad);
      setState(() => _ad = updatedAd);
    }
  }

  List<String> get _imagePaths {
    final paths = _ad['image_paths'];
    if (paths == null || paths is! List) return [];
    return paths.map((e) => e.toString()).where((p) => p.isNotEmpty).toList();
  }

  Widget _buildImageSlider() {
    final paths = _imagePaths;
    if (paths.isEmpty) {
      return Container(
        height: 260, color: Colors.grey[100],
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Pas de photo', style: TextStyle(color: Colors.grey[500])),
        ]),
      );
    }
    return SizedBox(height: 280, child: Stack(children: [
      PageView.builder(
        itemCount: paths.length,
        onPageChanged: (i) => setState(() => _currentImageIndex = i),
        itemBuilder: (_, i) {
          final file = File(paths[i]);
          return FutureBuilder<bool>(
            future: file.exists(),
            builder: (ctx, snap) {
              if (snap.data == true) {
                return Image.file(file, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey)));
              }
              return Container(color: Colors.grey[100],
                  child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey));
            },
          );
        },
      ),
      if (paths.length > 1) ...[
        Positioned(bottom: 12, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(paths.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == i ? 20 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i ? const Color(0xFF00853F) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )))),
        Positioned(top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text('${_currentImageIndex + 1}/${paths.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            )),
      ],
      // Boost badge on image
      if (_isBoosted)
        Positioned(top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _boostBadgeColor(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_boostEmoji(), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(_boostLabel(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            )),
    ]));
  }

  Color _boostBadgeColor() {
    switch (_boostPlan) {
      case 'premium': return const Color(0xFFE65100);
      case 'standard': return const Color(0xFF1565C0);
      default: return const Color(0xFF795548);
    }
  }
  String _boostEmoji() {
    switch (_boostPlan) {
      case 'premium': return '🥇';
      case 'standard': return '🥈';
      default: return '🥉';
    }
  }
  String _boostLabel() {
    switch (_boostPlan) {
      case 'premium': return 'PREMIUM';
      case 'standard': return 'STANDARD';
      default: return 'BOOST';
    }
  }

  Widget? _buildCategoryInfo() {
    final ad = _ad;
    switch (ad['category']) {
      case 'Voitures':
        final items = <Map<String,String>>[];
        if (ad['car_brand'] != null && ad['car_brand'].toString().isNotEmpty)
          items.add({'icon': '🏷️', 'label': 'Marque', 'value': ad['car_brand']});
        if (ad['car_model'] != null && ad['car_model'].toString().isNotEmpty)
          items.add({'icon': '🚗', 'label': 'Modèle', 'value': ad['car_model']});
        if (ad['car_year'] != null && ad['car_year'].toString().isNotEmpty)
          items.add({'icon': '📅', 'label': 'Année', 'value': ad['car_year']});
        if (ad['car_km'] != null && ad['car_km'].toString().isNotEmpty)
          items.add({'icon': '⚡', 'label': 'Kilométrage', 'value': '${ad['car_km']} km'});
        if (ad['car_condition'] != null && ad['car_condition'].toString().isNotEmpty)
          items.add({'icon': '⭐', 'label': 'État', 'value': ad['car_condition']});
        if (items.isEmpty) return null;
        return _infoCard(Icons.directions_car, const Color(0xFF1565C0), 'Détails du véhicule', items);
      case 'Immobilier':
        final items = <Map<String,String>>[];
        if (ad['prop_type'] != null && ad['prop_type'].toString().isNotEmpty)
          items.add({'icon': '🏠', 'label': 'Type', 'value': ad['prop_type']});
        if (ad['prop_deal'] != null && ad['prop_deal'].toString().isNotEmpty)
          items.add({'icon': '🤝', 'label': 'Offre', 'value': ad['prop_deal']});
        if (ad['prop_surface'] != null && ad['prop_surface'].toString().isNotEmpty)
          items.add({'icon': '📐', 'label': 'Surface', 'value': '${ad['prop_surface']} m²'});
        if (ad['prop_rooms'] != null && ad['prop_rooms'].toString().isNotEmpty)
          items.add({'icon': '🚪', 'label': 'Pièces', 'value': ad['prop_rooms']});
        if (items.isEmpty) return null;
        return _infoCard(Icons.home, const Color(0xFF6A1B9A), 'Détails du bien', items);
      case 'Electronique':
        final items = <Map<String,String>>[];
        if (ad['tech_brand'] != null && ad['tech_brand'].toString().isNotEmpty)
          items.add({'icon': '🏷️', 'label': 'Marque', 'value': ad['tech_brand']});
        if (ad['tech_condition'] != null && ad['tech_condition'].toString().isNotEmpty)
          items.add({'icon': '⭐', 'label': 'État', 'value': ad['tech_condition']});
        if (items.isEmpty) return null;
        return _infoCard(Icons.phone_android, const Color(0xFF00838F), 'Détails', items);
      case 'Emploi':
        final items = <Map<String,String>>[];
        if (ad['job_type'] != null && ad['job_type'].toString().isNotEmpty)
          items.add({'icon': '📋', 'label': 'Contrat', 'value': ad['job_type']});
        if (ad['job_salary'] != null && ad['job_salary'].toString().isNotEmpty)
          items.add({'icon': '💰', 'label': 'Salaire', 'value': '${ad['job_salary']} FCFA'});
        if (items.isEmpty) return null;
        return _infoCard(Icons.work, const Color(0xFFE65100), 'Détails du poste', items);
      default: return null;
    }
  }

  Widget _infoCard(IconData icon, Color color, String title, List<Map<String, String>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.07), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 18), const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 10, runSpacing: 10,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${item['icon']} ${item['label']}',
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(item['value'] ?? '',
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryInfo = _buildCategoryInfo();
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280, pinned: true,
            backgroundColor: const Color(0xFF00853F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                    color: _isFav ? Colors.red : Colors.white),
                onPressed: () {
                  setState(() => _isFav = !_isFav);
                  widget.onFavoriteToggle(_ad['id']);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildImageSlider()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Boost badge (active)
                if (_isBoosted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _boostBadgeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _boostBadgeColor().withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Text(_boostEmoji(), style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('Annonce boostée — ${_boostLabel()}',
                          style: TextStyle(color: _boostBadgeColor(), fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(_boostExpiry(), style: TextStyle(color: _boostBadgeColor().withOpacity(0.7), fontSize: 12)),
                    ]),
                  ),

                // Price & Title
                Text(_formatPrice(_ad['price']),
                    style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 26)),
                const SizedBox(height: 4),
                Text(_ad['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip(Icons.location_on, _ad['city'] ?? '', Colors.blue),
                  if (_ad['category'] != null) _chip(Icons.category, _ad['category'] ?? '', Colors.purple),
                  _chip(Icons.access_time, _timeAgo(_ad['created_at']), Colors.grey),
                ]),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                if (categoryInfo != null) categoryInfo,

                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_ad['description'] ?? '',
                    style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Seller info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00853F).withOpacity(0.15), radius: 22,
                      child: Text((_ad['seller_name']?.toString() ?? 'V').substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_ad['seller_name'] ?? 'Vendeur',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_ad['phone'] ?? '',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ])),
                    Icon(Icons.verified, color: Colors.green[400], size: 18),
                  ]),
                ),

                // BOOST BUTTON (only for owner)
                if (_isMyAd) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _openBoost,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8C00), Color(0xFFFFB300)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        const Text('🚀', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Booster cette annonce',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Apparaissez en 1ère position • 10x plus de contacts',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Boost!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: _isMyAd ? null : Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton.icon(
          onPressed: _showContact,
          icon: const Icon(Icons.phone, color: Colors.white),
          label: const Text('Contacter le vendeur',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00853F),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  String _boostExpiry() {
    try {
      final expiry = DateTime.parse(_ad['boost_expiry']);
      final diff = expiry.difference(DateTime.now());
      if (diff.inDays > 0) return 'Expire dans ${diff.inDays}j';
      if (diff.inHours > 0) return 'Expire dans ${diff.inHours}h';
      return 'Expire bientôt';
    } catch (_) { return ''; }
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color), const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}
