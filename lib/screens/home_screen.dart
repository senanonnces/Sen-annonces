import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
                // Header
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
                          const Icon(Icons.campaign, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          const Text('Sen Annonces',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          // City filter
                          GestureDetector(
                            onTap: () => _showCityFilter(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(_selectedCity ?? 'Toutes',
                                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Rechercher des annonces...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                // Categories
                SizedBox(
                  height: 95,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat['name'] ||
                          (_selectedCategory == null && cat['name'] == 'Tout');
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _selectedCategory = cat['name'] == 'Tout' ? null : cat['name']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (cat['color'] as Color)
                                      : (cat['color'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: (cat['color'] as Color).withOpacity(0.4),
                                        blurRadius: 8, offset: const Offset(0, 3))
                                  ] : [],
                                ),
                                child: Icon(cat['icon'] as IconData,
                                    color: isSelected ? Colors.white : cat['color'] as Color,
                                    size: 26),
                              ),
                              const SizedBox(height: 5),
                              Text(cat['name'] as String,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? cat['color'] as Color : Colors.grey[600],
                                  )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Results count
                if (_searchQuery.isNotEmpty || _selectedCategory != null || _selectedCity != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text('${filtered.length} annonce(s) trouvee(s)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const Spacer(),
                        if (_selectedCategory != null || _selectedCity != null)
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategory = null;
                              _selectedCity = null;
                              _searchQuery = '';
                            }),
                            child: const Text('Effacer filtres',
                                style: TextStyle(color: Color(0xFF00853F), fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Ads grid
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _ads.isEmpty
                              ? 'Aucune annonce pour le moment\nSoyez le premier a publier!'
                              : 'Aucun resultat pour votre recherche',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        if (_ads.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _currentIndex = 2),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Publier une annonce',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00853F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildAdCard(filtered[i]),
                      childCount: filtered.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final isFav = _favorites.contains(ad['id']);
    final cat = _categories.firstWhere(
      (c) => c['name'] == ad['category'],
      orElse: () => _categories.last,
    );
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad, onFavoriteToggle: _toggleFavorite, isFavorite: isFav)));
        _loadData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [(cat['color'] as Color).withOpacity(0.15), (cat['color'] as Color).withOpacity(0.05)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(cat['icon'] as IconData, size: 48, color: (cat['color'] as Color).withOpacity(0.5))),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(ad['id']),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                          child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat['color'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(ad['category'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad['title'] ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const Spacer(),
                    Text(_formatPrice(ad['price']),
                        style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 11, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(child: Text(ad['city'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 10))),
                        Text(_timeAgo(ad['created_at']),
                            style: const TextStyle(color: Colors.grey, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Filtrer par ville', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._cities.map((city) => ListTile(
            leading: Icon(Icons.location_on,
                color: _selectedCity == city || (city == 'Toutes' && _selectedCity == null)
                    ? const Color(0xFF00853F) : Colors.grey),
            title: Text(city),
            trailing: _selectedCity == city || (city == 'Toutes' && _selectedCity == null)
                ? const Icon(Icons.check, color: Color(0xFF00853F)) : null,
            onTap: () {
              setState(() => _selectedCity = city == 'Toutes' ? null : city);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      FavoritesScreen(favorites: _favorites, ads: _ads, onToggle: _toggleFavorite),
      CreateAdScreen(onAdCreated: () { _loadData(); setState(() => _currentIndex = 0); }),
      ProfileScreen(user: _currentUser),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(child: tabs[_currentIndex]),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _currentIndex = 2),
              backgroundColor: const Color(0xFF00853F),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _navItem(Icons.home_outlined, Icons.home, 'Accueil', 0),
              _navItem(Icons.favorite_outline, Icons.favorite, 'Favoris', 1),
              const Expanded(child: SizedBox()),
              _navItem(Icons.person_outline, Icons.person, 'Profil', 3),
              _navItem(Icons.logout, Icons.logout, 'Quitter', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () async {
          if (index == 4) {
            // Logout
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_logged_in', false);
            await prefs.remove('current_user');
            if (mounted) {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            }
            return;
          }
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF00853F) : Colors.grey, size: 22),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isActive ? const Color(0xFF00853F) : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
