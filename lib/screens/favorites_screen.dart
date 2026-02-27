import 'package:flutter/material.dart';
import '../main.dart';
import 'ad_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<String> favorites;
  final List<Map<String, dynamic>> allAds;
  final Map<String, dynamic>? currentUser;
  const FavoritesScreen({super.key, required this.favorites, required this.allAds, this.currentUser});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Future<void> _removeFavorite(String adId) async {
    if (widget.currentUser == null) return;
    try {
      await supabase.from('favorites')
          .delete()
          .eq('user_id', widget.currentUser!['id'])
          .eq('listing_id', adId);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 FCFA';
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M FCFA';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K FCFA';
    return '$p FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final favAds = widget.allAds
        .where((ad) => widget.favorites.contains(ad['id']?.toString() ?? ''))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        foregroundColor: Colors.white,
        title: Text('Favoris (${favAds.length})'),
      ),
      body: favAds.isEmpty
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucun favori', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: favAds.length,
              itemBuilder: (ctx, i) {
                final ad = favAds[i];
                final imageUrl = ad['images'] != null && (ad['images'] as List).isNotEmpty
                    ? ad['images'][0].toString()
                    : null;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null
                          ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey))
                          : const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                    title: Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_formatPrice(ad['price']),
                          style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold)),
                      Text(ad['location_city'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFavorite(ad['id'].toString()),
                    ),
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => AdDetailScreen(ad: ad, currentUser: widget.currentUser),
                    )),
                  ),
                );
              },
            ),
    );
  }
}
