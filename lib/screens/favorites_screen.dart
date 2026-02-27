import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'ad_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List<String> favorites;
  final List<Map<String, dynamic>> ads;
  final Function(String) onToggle;

  const FavoritesScreen({super.key, required this.favorites, required this.ads, required this.onToggle});

  String _formatPrice(dynamic price) {
    if (price == null) return '0 FCFA';
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M FCFA';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K FCFA';
    return '$p FCFA';
  }

  Widget _buildImage(Map<String, dynamic> ad) {
    final paths = ad['image_paths'];
    if (paths != null && paths is List && paths.isNotEmpty) {
      final path = paths.first.toString();
      if (path.isNotEmpty) {
        return FutureBuilder<bool>(
          future: File(path).exists(),
          builder: (_, snap) {
            if (snap.data == true) {
              return ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Image.file(File(path),
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultIcon()),
              );
            }
            return _defaultIcon();
          },
        );
      }
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() => Container(
    width: 90, height: 90,
    decoration: const BoxDecoration(
      color: Color(0x1A00853F),
      borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
    ),
    child: const Icon(Icons.campaign, color: Color(0xFF00853F), size: 36),
  );

  @override
  Widget build(BuildContext context) {
    final favAds = ads.where((ad) => favorites.contains(ad['id'])).toList();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Favoris (${favAds.length})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00853F),
        automaticallyImplyLeading: false,
        actions: [
          if (favAds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {},
            ),
        ],
      ),
      body: favAds.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucun favori pour le moment',
                      style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Appuyez sur ❤️ sur une annonce pour la sauvegarder',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: favAds.length,
              itemBuilder: (ctx, i) {
                final ad = favAds[i];
                return GestureDetector(
                  onTap: () => Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => AdDetailScreen(
                          ad: ad, onFavoriteToggle: onToggle, isFavorite: true))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        _buildImage(ad),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ad['title'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(_formatPrice(ad['price']),
                                    style: const TextStyle(
                                        color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                  const SizedBox(width: 2),
                                  Text(ad['city'] ?? '',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                          onPressed: () => onToggle(ad['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
