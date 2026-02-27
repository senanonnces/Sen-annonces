import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
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
    final prefs = await SharedPreferences.getInstance();
    final adsJson = prefs.getString('ads') ?? '[]';
    final favsJson = prefs.getString('favorites') ?? '[]';
    final userJson = prefs.getString('current_user');
    setState(() {
      _ads = List<Map<String, dynamic>>.from(
        (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e))
      );
      _favorites = List<String>.from(jsonDecode(favsJson));
      if (userJson != null) _currentUser = jsonDecode(userJson);
    });
  }

  Future<void> _toggleFavorite(String adId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(adId)) {
        _favorites.remove(adId);
      } else {
        _favorites.add(adId);
      }
    });
    await prefs.setString('favorites', jsonEncode(_favorites));
  }

  List<Map<String, dynamic>> get _filteredAds {
    return _ads.where((ad) {
      final matchSearch = _searchQuery.isEmpty ||
          ad['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategory = _selectedCategory == null || _selectedCategory == 'Tout' ||
          ad['category'] == _selectedCategory;
      final matchCity = _selectedCity == null || _selectedCity == 'Toutes' ||
          ad['city'] == _selectedCity;
      return matchSearch && matchCategory && matchCity;
    }).toList()..sort((a, b) => b['created_at'].compareTo(a['created_at']));
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
      return 'Il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }

  // Helper: get first valid image from ad
  Widget _buildAdImage(Map<String, dynamic> ad, {double size = 90}) {
    final paths = ad['image_paths'];
    if (paths != null && paths is List && paths.isNotEmpty) {
      final path = paths.first.toString();
      if (path.isNotEmpty) {
        final file = File(path);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (ctx, snap) {
            if (snap.data == true) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  file,
                  width: size, height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _categoryIcon(ad, size: size),
                ),
              );
            }
            return _categoryIcon(ad, size: size);
          },
        );
      }
    }
    return _categoryIcon(ad, size: size);
  }

  Widget _categoryIcon(Map<String, dynamic> ad, {double size = 90}) {
    final catData = _categories.firstWhere(
      (c) => c['name'] == ad['category'],
      orElse: () => {'icon': Icons.campaign, 'color': const Color(0xFF00853F)},
    );
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: (catData['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(catData['icon'] as IconData, color: catData['color'] as Color, size: size * 0.45),
    );
  }

  Widget _buildHomeTab() {
    final filtered = _filteredAds;
    return RefreshIndicator(
      color: const Color(0xFF00853F),
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Header with gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00853F), Color(0xFF00A651)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour, ${_currentUser?['name']?.toString().split(' ').first ?? 'Visiteur'}!',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const Text('Sen Annonces',
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.campaign, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text('${filtered.length} annonces',
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Rechercher une annonce...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF00853F)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Categories horizontal scroll
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isSelected = (_selectedCategory ?? 'Tout') == cat['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['name'] == 'Tout' ? null : cat['name']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? cat['color'] as Color : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? cat['color'] as Color : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat['icon'] as IconData,
                                    color: isSelected ? Colors.white : cat['color'] as Color,
                                    size: 20),
                                const SizedBox(height: 3),
                                Text(cat['name'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // City filter
                Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF00853F), size: 18),
                      const SizedBox(width: 6),
                      const Text('Ville:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _cities.length,
                            itemBuilder: (_, i) {
                              final city = _cities[i];
                              final isSelected = (_selectedCity ?? 'Toutes') == city;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCity = city == 'Toutes' ? null : city),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF00853F) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF00853F) : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(city,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                      )),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ads list
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 72, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Aucune annonce trouvee',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('Soyez le premier a publier!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex = 1),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Publier une annonce', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00853F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final ad = filtered[i];
                    final isFav = _favorites.contains(ad['id']);
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => AdDetailScreen(
                            ad: ad,
                            onFavoriteToggle: _toggleFavorite,
                            isFavorite: isFav,
                          ),
                        ));
                        _loadData(); // Refresh after returning
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            // Image
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: _buildAdImage(ad, size: 90),
                            ),
                            // Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(ad['title'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                        GestureDetector(
                                          onTap: () => _toggleFavorite(ad['id']),
                                          child: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: isFav ? Colors.red : Colors.grey[400],
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_formatPrice(ad['price']),
                                        style: const TextStyle(
                                            color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                                        const SizedBox(width: 2),
                                        Text(ad['city'] ?? '',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        const SizedBox(width: 8),
                                        if (ad['category'] != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(ad['category'] ?? '',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_timeAgo(ad['created_at']),
                                        style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeTab(),
      CreateAdScreen(onAdCreated: () {
        _loadData();
        setState(() => _currentIndex = 0);
      }),
      FavoritesScreen(favorites: _favorites, ads: _ads, onToggle: _toggleFavorite),
      ProfileScreen(user: _currentUser),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0) _loadData(); // Refresh when going to home
          setState(() => _currentIndex = i);
        },
        selectedItemColor: const Color(0xFF00853F),
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Publier'),
          BottomNavigationBarItem(
            icon: Stack(children: [
              const Icon(Icons.favorite_outline),
              if (_favorites.isNotEmpty) Positioned(
                right: 0, top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('${_favorites.length}', style: const TextStyle(color: Colors.white, fontSize: 8)),
                ),
              ),
            ]),
            activeIcon: const Icon(Icons.favorite),
            label: 'Favoris',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
