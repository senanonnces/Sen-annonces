import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
import 'ad_detail_screen.dart';
import 'create_ad_screen.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCity;
  List<Map<String, dynamic>> _ads = [];
  List<String> _favorites = [];
  Map<String, dynamic>? _currentUser;
  bool _loading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tout', 'icon': Icons.apps, 'color': Color(0xFF00853F)},
    {'name': 'Voitures', 'icon': Icons.directions_car, 'color': Color(0xFF1565C0)},
    {'name': 'Immobilier', 'icon': Icons.home, 'color': Color(0xFF6A1B9A)},
    {'name': 'Electronique', 'icon': Icons.phone_android, 'color': Color(0xFF00838F)},
    {'name': 'Emploi', 'icon': Icons.work, 'color': Color(0xFFE65100)},
    {'name': 'Mode', 'icon': Icons.checkroom, 'color': Color(0xFFC2185B)},
    {'name': 'Maison', 'icon': Icons.chair, 'color': Color(0xFF558B2F)},
    {'name': 'Sport', 'icon': Icons.sports_soccer, 'color': Color(0xFF1976D2)},
    {'name': 'Animaux', 'icon': Icons.pets, 'color': Color(0xFF5D4037)},
    {'name': 'Services', 'icon': Icons.build, 'color': Color(0xFF37474F)},
    {'name': 'Autre', 'icon': Icons.more_horiz, 'color': Color(0xFF757575)},
  ];

  final List<String> _cities = [
    'Toutes', 'Dakar', 'Thies', 'Saint-Louis', 'Ziguinchor',
    'Kaolack', 'Mbour', 'Touba', 'Diourbel', 'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        _currentUser = Map<String, dynamic>.from(jsonDecode(userJson));
      }

      // Load ads from Supabase
      final adsResponse = await supabase
          .from('listings')
          .select()
          .order('created_at', ascending: false);

      // Load favorites from Supabase if user logged in
      List<String> favIds = [];
      if (_currentUser != null) {
        final favsResponse = await supabase
            .from('favorites')
            .select('listing_id')
            .eq('user_id', _currentUser!['id']);
        favIds = (favsResponse as List).map((f) => f['listing_id'].toString()).toList();
      }

      if (mounted) {
        setState(() {
          _ads = List<Map<String, dynamic>>.from(adsResponse);
          _favorites = favIds;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAds {
    return _ads.where((ad) {
      final matchSearch = _searchQuery.isEmpty ||
          (ad['title'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ad['description'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategory = _selectedCategory == null ||
          _selectedCategory == 'Tout' ||
          (ad['category'] ?? '') == _selectedCategory?.toLowerCase() ||
          (ad['category'] ?? '').toLowerCase() == _selectedCategory?.toLowerCase();
      final matchCity = _selectedCity == null ||
          _selectedCity == 'Toutes' ||
          (ad['location_city'] ?? '') == _selectedCity;
      return matchSearch && matchCategory && matchCity;
    }).toList();
  }

  Future<void> _toggleFavorite(String adId) async {
    if (_currentUser == null) return;
    final userId = _currentUser!['id'];
    final isFav = _favorites.contains(adId);

    setState(() {
      if (isFav) _favorites.remove(adId);
      else _favorites.add(adId);
    });

    try {
      if (isFav) {
        await supabase.from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('listing_id', adId);
      } else {
        await supabase.from('favorites')
            .insert({'user_id': userId, 'listing_id': adId});
      }
    } catch (e) {
      // revert
      setState(() {
        if (isFav) _favorites.add(adId);
        else _favorites.remove(adId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      FavoritesScreen(favorites: _favorites, allAds: _ads, currentUser: _currentUser),
      ProfileScreen(currentUser: _currentUser, onUpdate: _loadData),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () async {
          if (_currentUser == null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            return;
          }
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => CreateAdScreen(onAdCreated: _loadData, currentUser: _currentUser),
          ));
        },
        backgroundColor: const Color(0xFF00853F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Publier', style: TextStyle(color: Colors.white)),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 'Accueil', 0),
            const SizedBox(width: 40),
            _navItem(Icons.favorite, 'Favoris', 1),
            _navItem(Icons.person, 'Profil', 2),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF00853F) : Colors.grey),
            Text(label, style: TextStyle(
              fontSize: 11,
              color: active ? const Color(0xFF00853F) : Colors.grey,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final filtered = _filteredAds;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: const Text('Sen Annonces', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                filled: true, fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final active = (_selectedCategory ?? 'Tout') == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name'] == 'Tout' ? null : cat['name']),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active ? cat['color'] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 16,
                            color: active ? Colors.white : Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(cat['name'], style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white : Colors.grey[700],
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // City filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedCity ?? 'Toutes',
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedCity = v == 'Toutes' ? null : v),
            ),
          ),
          // Ads count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text('${filtered.length} annonce(s)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          // Ads list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00853F)))
                : filtered.isEmpty
                    ? const Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Aucune annonce trouvee', style: TextStyle(color: Colors.grey)),
                        ],
                      ))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _buildAdCard(filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final isFav = _favorites.contains(ad['id']?.toString() ?? '');
    final isBoost = ad['is_boosted'] == true;
    final imageUrl = ad['images'] != null && (ad['images'] as List).isNotEmpty
        ? ad['images'][0].toString()
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isBoost ? 4 : 1,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdDetailScreen(ad: ad, currentUser: _currentUser),
        )).then((_) => _loadData()),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBoost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6F00),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: const Row(children: [
                  Icon(Icons.rocket_launch, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('ANNONCE BOOSTEE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isBoost ? 0 : 12),
                    bottomLeft: const Radius.circular(12),
                  ),
                  child: imageUrl != null
                      ? Image.network(imageUrl, width: 110, height: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _noImage())
                      : _noImage(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${ad['price'] ?? 0} FCFA',
                            style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on, size: 13, color: Colors.grey),
                          Text(ad['location_city'] ?? 'Dakar',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey),
                      onPressed: () => _toggleFavorite(ad['id']?.toString() ?? ''),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noImage() => Container(
    width: 110, height: 100,
    color: Colors.grey[200],
    child: const Icon(Icons.image, color: Colors.grey, size: 40),
  );
}
