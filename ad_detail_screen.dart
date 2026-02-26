import 'package:flutter/material.dart';

class AdDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF00853F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                onPressed: () => setState(() => _isFav = !_isFav),
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
                    colors: [
                      (ad['color'] as Color).withOpacity(0.9),
                      (ad['color'] as Color),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    ad['icon'] as IconData,
                    size: 110,
                    color: Colors.white.withOpacity(0.85),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ad['category'] as String,
                              style: const TextStyle(color: Color(0xFF00853F), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(ad['time'] as String,
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(ad['title'] as String,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(ad['price'] as String,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00853F))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(ad['city'] as String,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(ad['description'] as String,
                          style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendeur',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00853F).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Color(0xFF00853F), size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vendeur Particulier',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  Icon(Icons.star_half, size: 14, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text('4.5', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
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
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00853F)),
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
                onPressed: () => _showCallDialog(context, ad['phone'] as String),
                icon: const Icon(Icons.phone, color: Colors.white),
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

  void _showCallDialog(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Appeler le vendeur'),
        content: Text(phone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Appeler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
