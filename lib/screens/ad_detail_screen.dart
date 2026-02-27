import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  void _showContact(bool isCall) {
    final phone = widget.ad['phone'] ?? widget.ad['seller_phone'] ?? 'Non disponible';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF00853F),
              child: Icon(isCall ? Icons.phone : Icons.message, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(isCall ? 'Appeler le vendeur' : 'Contacter le vendeur',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(widget.ad['seller_name'] ?? 'Vendeur',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00853F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, color: Color(0xFF00853F)),
                  const SizedBox(width: 8),
                  Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00853F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Fermer', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF00853F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  setState(() => _isFav = !_isFav);
                  widget.onFavoriteToggle(ad['id']);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00853F), Color(0xFF004D25)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.campaign, size: 80, color: Colors.white54),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main info card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00853F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ad['category'] ?? '',
                                style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          Text(ad['city'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const Spacer(),
                          Text(_timeAgo(ad['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(ad['title'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_formatPrice(ad['price']),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00853F))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(ad['description'] ?? 'Aucune description disponible.',
                          style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Seller info
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendeur', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF00853F),
                            child: Text(
                              (ad['seller_name'] ?? 'V').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ad['seller_name'] ?? 'Vendeur',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Row(children: [
                                const Icon(Icons.phone, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(ad['phone'] ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showContact(false),
                icon: const Icon(Icons.message_outlined, color: Color(0xFF00853F)),
                label: const Text('Message', style: TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00853F)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showContact(true),
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text('Appeler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00853F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
