import 'package:flutter/material.dart';

class AdDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ad;
  const AdDetailScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF00853F),
                      (ad['color'] as Color? ?? const Color(0xFF00853F)).withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    ad['icon'] as IconData? ?? Icons.image,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00853F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ad['category'] ?? '',
                                style: const TextStyle(
                                    color: Color(0xFF00853F), fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          Text(ad['city'] ?? '',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(ad['title'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${_formatPrice(ad['price'])} FCFA',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00853F))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(ad['description'] ?? 'Aucune description disponible.',
                          style: const TextStyle(color: Colors.black87, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendeur',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFF00853F),
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ad['seller_name'] ?? 'Vendeur',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const Text('Membre depuis 2024',
                                  style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showContactDialog(context, false),
                icon: const Icon(Icons.message_outlined, color: Color(0xFF00853F)),
                label: const Text('Message', style: TextStyle(color: Color(0xFF00853F))),
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
                onPressed: () => _showContactDialog(context, true),
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text('Appeler', style: TextStyle(color: Colors.white)),
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

  void _showContactDialog(BuildContext context, bool isCall) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isCall ? 'Appeler le vendeur' : 'Contacter le vendeur'),
        content: Text(isCall
            ? 'Numero: ${ad['phone'] ?? '+221 XX XXX XX XX'}'
            : 'Envoyez un message au vendeur'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F)),
            child: Text(isCall ? 'Appeler' : 'Envoyer',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)} M';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)} K';
    return p.toString();
  }
}
