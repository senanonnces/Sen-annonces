import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const ProfileScreen({super.key, this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _myAds = [];

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    final prefs = await SharedPreferences.getInstance();
    final adsJson = prefs.getString('ads') ?? '[]';
    final allAds = List<Map<String, dynamic>>.from(
        (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));
    final userId = widget.user?['id'];
    setState(() {
      _myAds = userId != null
          ? allAds.where((a) => a['user_id'] == userId).toList()
          : [];
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
      allAds.removeWhere((a) => a['id'] == adId);
      await prefs.setString('ads', jsonEncode(allAds));
      _loadMyAds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimee'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_user');
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
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
    final user = widget.user;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF00853F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00853F), Color(0xFF00A651)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: Text(
                        user != null && user['name'] != null
                            ? user['name'].toString().substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF00853F)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(user?['name'] ?? 'Utilisateur',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user?['phone'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Se deconnecter',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _statCard('Mes annonces', _myAds.length.toString(), Icons.campaign),
                      const SizedBox(width: 10),
                      _statCard('Ville', user?['city'] ?? 'N/A', Icons.location_on),
                      const SizedBox(width: 10),
                      _statCard('Membre', 'Actif', Icons.verified_user),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // My ads section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Mes annonces',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text('${_myAds.length} annonce(s)',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _myAds.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Vous n\'avez pas encore d\'annonces',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final ad = _myAds[i];
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00853F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign, color: Color(0xFF00853F)),
                          ),
                          title: Text(ad['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_formatPrice(ad['price']),
                              style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteAd(ad['id']),
                          ),
                        ),
                      );
                    },
                    childCount: _myAds.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00853F), size: 22),
            const SizedBox(height: 4),
            Text(value, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
