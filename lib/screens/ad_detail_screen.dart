import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'boost_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  final Map<String, dynamic>? currentUser;
  const AdDetailScreen({super.key, required this.ad, this.currentUser});
  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  bool _isFav = false;
  int _currentImageIndex = 0;
  bool _isMyAd = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _checkMyAd();
  }

  Future<void> _checkFavorite() async {
    if (widget.currentUser == null) return;
    try {
      final result = await supabase
          .from('favorites')
          .select('id')
          .eq('user_id', widget.currentUser!['id'])
          .eq('listing_id', widget.ad['id'].toString())
          .maybeSingle();
      if (mounted) setState(() => _isFav = result != null);
    } catch (_) {}
  }

  void _checkMyAd() {
    if (widget.currentUser == null) return;
    setState(() => _isMyAd = widget.ad['user_id']?.toString() == widget.currentUser!['id']?.toString());
  }

  Future<void> _toggleFavorite() async {
    if (widget.currentUser == null) return;
    final userId = widget.currentUser!['id'];
    final adId = widget.ad['id'].toString();
    try {
      if (_isFav) {
        await supabase.from('favorites').delete()
            .eq('user_id', userId).eq('listing_id', adId);
      } else {
        await supabase.from('favorites').insert({'user_id': userId, 'listing_id': adId});
      }
      if (mounted) setState(() => _isFav = !_isFav);
    } catch (_) {}
  }

  Future<void> _contactWhatsApp() async {
    final phone = (widget.ad['phone'] ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    final title = Uri.encodeComponent(widget.ad['title'] ?? '');
    final url = Uri.parse('https://wa.me/$phone?text=Bonjour, je suis interesse par votre annonce: $title');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _callSeller() async {
    final phone = widget.ad['phone'] ?? '';
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.ad['images'] != null
        ? List<String>.from(widget.ad['images'])
        : <String>[];
    final attrs = widget.ad['attributes'] as Map<String, dynamic>? ?? {};
    final isBoost = widget.ad['is_boosted'] == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        foregroundColor: Colors.white,
        title: Text(widget.ad['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.currentUser != null)
            IconButton(
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                  color: _isFav ? Colors.red[200] : Colors.white),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: ListView(
        children: [
          // Images
          if (images.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i], fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 8, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text('${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
              ],
            )
          else
            Container(height: 200, color: Colors.grey[200],
                child: const Icon(Icons.image, size: 60, color: Colors.grey)),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (isBoost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: const Color(0xFFFF6F00), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('ANNONCE BOOSTEE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              Text(widget.ad['title'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${widget.ad['price'] ?? 0} FCFA',
                  style: const TextStyle(fontSize: 24, color: Color(0xFF00853F), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                Text(widget.ad['location_city'] ?? 'Dakar',
                    style: const TextStyle(color: Colors.grey)),
              ]),
              const Divider(height: 24),
              if (widget.ad['description'] != null && widget.ad['description'].toString().isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(widget.ad['description'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5)),
                const Divider(height: 24),
              ],
              // Attributes
              if (attrs.isNotEmpty) ...[
                const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: attrs.entries
                      .where((e) => e.value != null && e.value.toString().isNotEmpty)
                      .map((e) => Chip(
                          label: Text('${e.key}: ${e.value}',
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey[100]))
                      .toList(),
                ),
                const Divider(height: 24),
              ],
              // Boost button (only for my ads)
              if (_isMyAd) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BoostScreen(ad: widget.ad),
                    )),
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Booster cette annonce'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Contact buttons
              if (!_isMyAd) ...[
                const Text('Contacter le vendeur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _contactWhatsApp,
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _callSeller,
                      icon: const Icon(Icons.call),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00853F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
