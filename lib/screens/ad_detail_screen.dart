import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
  }

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
    final uri = Uri.parse('tel:$clean');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'appeler: $phone')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp non disponible')),
        );
      }
    }
  }

  void _showContact() {
    final phone = widget.ad['phone'] ?? widget.ad['seller_phone'] ?? 'Non disponible';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF00853F).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFF00853F), size: 32),
            ),
            const SizedBox(height: 12),
            Text(widget.ad['seller_name'] ?? 'Vendeur',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(phone,
                style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _launchCall(phone); },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Appeler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00853F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _launchWhatsApp(phone); },
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<String> get _imagePaths {
    final paths = widget.ad['image_paths'];
    if (paths == null || paths is! List) return [];
    return paths.map((e) => e.toString()).where((p) => p.isNotEmpty).toList();
  }

  Widget _buildImageSlider() {
    final paths = _imagePaths;
    if (paths.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[100],
        child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
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
                          child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        ));
                  }
                  return Container(
                    color: Colors.grey[100],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Photo non disponible', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (paths.length > 1)
            Positioned(
              bottom: 12,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(paths.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i ? const Color(0xFF00853F) : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
          if (paths.length > 1)
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_currentImageIndex + 1}/${paths.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF00853F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFav ? Icons.favorite : Icons.favorite_border,
                  color: _isFav ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  setState(() => _isFav = !_isFav);
                  widget.onFavoriteToggle(ad['id']);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSlider(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price + favorite
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatPrice(ad['price']),
                                style: const TextStyle(
                                    color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(ad['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Meta info
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _chip(Icons.location_on, ad['city'] ?? '', Colors.blue),
                      if (ad['category'] != null)
                        _chip(Icons.category, ad['category'] ?? '', Colors.purple),
                      _chip(Icons.access_time, _timeAgo(ad['created_at']), Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Description
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(ad['description'] ?? '',
                      style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Seller info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF00853F).withOpacity(0.15),
                          radius: 22,
                          child: const Icon(Icons.person, color: Color(0xFF00853F), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ad['seller_name'] ?? 'Vendeur',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(ad['phone'] ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        Icon(Icons.verified, color: Colors.green[400], size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showContact,
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text('Contacter le vendeur',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00853F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
