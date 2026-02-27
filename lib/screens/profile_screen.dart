import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'login_screen.dart';
import 'ad_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const ProfileScreen({super.key, this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _myAds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final adsJson = prefs.getString('ads') ?? '[]';
    final allAds = List<Map<String, dynamic>>.from(
        (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));
    final userId = widget.user?['id'];
    setState(() {
      _myAds = userId != null
          ? allAds.where((a) => a['user_id'] == userId).toList()
          : [];
      _loading = false;
    });
  }

  Future<void> _deleteAd(String adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Etes-vous sur de vouloir supprimer cette annonce?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final adsJson = prefs.getString('ads') ?? '[]';
      final allAds = List<Map<String, dynamic>>.from(
          (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));
      
      // Also delete image files
      final adToDelete = allAds.firstWhere((a) => a['id'] == adId, orElse: () => {});
      if (adToDelete.isNotEmpty) {
        final paths = adToDelete['image_paths'];
        if (paths != null && paths is List) {
          for (final path in paths) {
            try {
              final f = File(path.toString());
              if (await f.exists()) await f.delete();
            } catch (_) {}
          }
        }
      }
      
      allAds.removeWhere((a) => a['id'] == adId);
      await prefs.setString('ads', jsonEncode(allAds));
      _loadMyAds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimee avec succes'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vous deconnecter?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se deconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('current_user');
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 FCFA';
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M FCFA';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K FCFA';
    return '$p FCFA';
  }

  Widget _buildAdImage(Map<String, dynamic> ad) {
    final paths = ad['image_paths'];
    if (paths != null && paths is List && paths.isNotEmpty) {
      final path = paths.first.toString();
      if (path.isNotEmpty) {
        return FutureBuilder<bool>(
          future: File(path).exists(),
          builder: (_, snap) {
            if (snap.data == true) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultAdIcon()),
              );
            }
            return _defaultAdIcon();
          },
        );
      }
    }
    return _defaultAdIcon();
  }

  Widget _defaultAdIcon() => Container(
    width: 60, height: 60,
    decoration: BoxDecoration(
      color: const Color(0xFF00853F).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.campaign, color: Color(0xFF00853F), size: 28),
  );

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: const Color(0xFF00853F),
        onRefresh: _loadMyAds,
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00853F), Color(0xFF00A651)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 30),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        (user?['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user?['name'] ?? 'Utilisateur',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user?['phone'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    if (user?['city'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(user!['city'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statBox('${_myAds.length}', 'Annonces'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // My Ads section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: Color(0xFF00853F), size: 20),
                    const SizedBox(width: 8),
                    const Text('Mes annonces',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00853F)),
                      ),
                  ],
                ),
              ),
            ),

            if (!_loading && _myAds.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.post_add, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Vous n\'avez aucune annonce',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Publiez votre premiere annonce!',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ),

            if (!_loading && _myAds.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final ad = _myAds[i];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => AdDetailScreen(
                              ad: ad,
                              onFavoriteToggle: (_) {},
                              isFavorite: false,
                            ),
                          ));
                          _loadMyAds();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              _buildAdImage(ad),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ad['title'] ?? '',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 3),
                                    Text(_formatPrice(ad['price']),
                                        style: const TextStyle(
                                            color: Color(0xFF00853F), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Row(children: [
                                      Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                                      Text(ad['city'] ?? '',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                      const SizedBox(width: 8),
                                      if (ad['category'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(ad['category'],
                                              style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                        ),
                                    ]),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                onPressed: () => _deleteAd(ad['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _myAds.length,
                  ),
                ),
              ),

            // Logout button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Se deconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  );
}
