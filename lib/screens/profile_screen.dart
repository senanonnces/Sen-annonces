import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
import 'login_screen.dart';
import 'ad_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUser;
  final VoidCallback? onUpdate;
  const ProfileScreen({super.key, this.currentUser, this.onUpdate});
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
    if (widget.currentUser == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final ads = await supabase
          .from('listings')
          .select()
          .eq('user_id', widget.currentUser!['id'])
          .order('created_at', ascending: false);
      if (mounted) setState(() { _myAds = List<Map<String, dynamic>>.from(ads); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAd(String adId) async {
    try {
      await supabase.from('listings').delete().eq('id', adId);
      setState(() => _myAds.removeWhere((a) => a['id'].toString() == adId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce supprimee'), backgroundColor: Color(0xFF00853F)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil'), backgroundColor: const Color(0xFF00853F), foregroundColor: Colors.white),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Connectez-vous pour voir votre profil'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F), foregroundColor: Colors.white),
              child: const Text('Se connecter'),
            ),
          ]),
        ),
      );
    }

    final user = widget.currentUser!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        foregroundColor: Colors.white,
        title: const Text('Mon Profil'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Deconnexion'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyAds,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF00853F),
                    child: Text(
                      (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user['phone'] ?? '', style: const TextStyle(color: Colors.grey)),
                      Text(user['city'] ?? 'Dakar', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // Stats
            Row(children: [
              Expanded(child: _statCard('${_myAds.length}', 'Annonces', Icons.campaign, const Color(0xFF00853F))),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                '${_myAds.where((a) => a['is_boosted'] == true).length}',
                'Boostees', Icons.rocket_launch, const Color(0xFFFF6F00),
              )),
            ]),
            const SizedBox(height: 16),
            const Text('Mes Annonces', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF00853F)))
            else if (_myAds.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.campaign_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Aucune annonce publiee', style: TextStyle(color: Colors.grey)),
                ]),
              ))
            else
              ...(_myAds.map((ad) => _buildAdTile(ad)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildAdTile(Map<String, dynamic> ad) {
    final imageUrl = ad['images'] != null && (ad['images'] as List).isNotEmpty
        ? ad['images'][0].toString()
        : null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(imageUrl, width: 55, height: 55, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey))
              : const Icon(Icons.image, size: 40, color: Colors.grey),
        ),
        title: Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${ad['price'] ?? 0} FCFA', style: const TextStyle(color: Color(0xFF00853F))),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(ad['id'].toString()),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdDetailScreen(ad: ad, currentUser: widget.currentUser),
        )).then((_) => _loadMyAds()),
      ),
    );
  }

  void _confirmDelete(String adId) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Supprimer'),
      content: const Text('Supprimer cette annonce?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _deleteAd(adId); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }
}
