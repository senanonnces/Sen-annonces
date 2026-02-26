import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'create_ad_screen.dart';
import 'ad_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCity = 'Toutes les villes';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.directions_car, 'name': 'Voitures', 'color': const Color(0xFF1565C0)},
    {'icon': Icons.home_work, 'name': 'Immobilier', 'color': const Color(0xFF2E7D32)},
    {'icon': Icons.phone_android, 'name': 'Electronique', 'color': const Color(0xFFE65100)},
    {'icon': Icons.work_outline, 'name': 'Emploi', 'color': const Color(0xFF6A1B9A)},
    {'icon': Icons.checkroom, 'name': 'Mode', 'color': const Color(0xFFAD1457)},
    {'icon': Icons.chair_alt, 'name': 'Maison', 'color': const Color(0xFF4E342E)},
    {'icon': Icons.sports_soccer, 'name': 'Sport', 'color': const Color(0xFFC62828)},
    {'icon': Icons.pets, 'name': 'Animaux', 'color': const Color(0xFF00695C)},
    {'icon': Icons.construction, 'name': 'Services', 'color': const Color(0xFF1A237E)},
    {'icon': Icons.school_outlined, 'name': 'Education', 'color': const Color(0xFF006064)},
    {'icon': Icons.agriculture, 'name': 'Agriculture', 'color': const Color(0xFF558B2F)},
    {'icon': Icons.more_horiz, 'name': 'Autres', 'color': const Color(0xFF546E7A)},
  ];

  final List<String> _cities = [
    'Toutes les villes', 'Dakar', 'Thiès', 'Saint-Louis',
    'Ziguinchor', 'Kaolack', 'Mbour', 'Touba', 'Diourbel',
  ];

  final List<Map<String, dynamic>> _ads = [
    {
      'id': '1',
      'title': 'Toyota Corolla 2019',
      'price': '8 500 000 FCFA',
      'city': 'Dakar',
      'category': 'Voitures',
      'time': 'Il y a 2h',
      'icon': Icons.directions_car,
      'color': const Color(0xFF1565C0),
      'description': 'Voiture en excellent état, climatisation, vitres électriques. Kilométrage: 45 000 km.',
      'phone': '+221 77 123 45 67',
    },
    {
      'id': '2',
      'title': 'Appartement F3 à Plateau',
      'price': '350 000 FCFA/mois',
      'city': 'Dakar',
      'category': 'Immobilier',
      'time': 'Il y a 5h',
      'icon': Icons.home_work,
      'color': const Color(0xFF2E7D32),
      'description': 'Bel appartement F3 au Plateau, 3ème étage, gardien, parking.',
      'phone': '+221 76 234 56 78',
    },
    {
      'id': '3',
      'title': 'iPhone 14 Pro Max 256GB',
      'price': '650 000 FCFA',
      'city': 'Thiès',
      'category': 'Electronique',
      'time': 'Hier',
      'icon': Icons.phone_android,
      'color': const Color(0xFFE65100),
      'description': 'iPhone 14 Pro Max couleur violet, 256GB, état neuf avec boite originale.',
      'phone': '+221 78 345 67 89',
    },
    {
      'id': '4',
      'title': 'Développeur Flutter recherché',
      'price': '400 000 FCFA/mois',
      'city': 'Dakar',
      'category': 'Emploi',
      'time': 'Il y a 3j',
      'icon': Icons.work_outline,
      'color': const Color(0xFF6A1B9A),
      'description': 'Startup fintech cherche développeur Flutter expérimenté. 2 ans minimum. CDI.',
      'phone': '+221 33 456 78 90',
    },
    {
      'id': '5',
      'title': 'Moto Jakarta 125cc',
      'price': '550 000 FCFA',
      'city': 'Mbour',
      'category': 'Voitures',
      'time': 'Il y a 1j',
      'icon': Icons.directions_car,
      'color': const Color(0xFF1565C0),
      'description': 'Moto Jakarta 125cc, 2021, très bon état, peu roulée.',
      'phone': '+221 70 567 89 01',
    },
    {
      'id': '6',
      'title': 'Samsung 65" 4K Smart TV',
      'price': '320 000 FCFA',
      'city': 'Dakar',
      'category': 'Electronique',
      'time': 'Il y a 4h',
      'icon': Icons.phone_android,
      'color': const Color(0xFFE65100),
      'description': 'Télévision Samsung 65 pouces 4K Smart TV, WiFi intégré, Netflix/YouTube.',
      'phone': '+221 77 678 90 12',
    },
  ];

  List<Map<String, dynamic>> get _filteredAds {
    return _ads.where((ad) {
      final matchCity = _selectedCity == 'Toutes les villes' || ad['city'] == _selectedCity;
      final matchSearch = _searchQuery.isEmpty ||
          (ad['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCity && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeTab(),
          _buildFavoritesTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAdScreen()),
        ),
        backgroundColor: const Color(0xFF00853F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, Icons.home, 'Accueil', 0),
            _navItem(Icons.favorite_outline, Icons.favorite, 'Favoris', 1),
            const SizedBox(width: 60),
            _navItem(Icons.person_outline, Icons.person, 'Profil', 2),
            _navItem(Icons.login_outlined, Icons.login, 'Connexion', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData outline, IconData filled, String label, int index) {
    if (index == 3) {
      return IconButton(
        icon: Icon(outline, color: Colors.grey),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        tooltip: label,
      );
    }
    final active = _currentTab == index;
    return IconButton(
      icon: Icon(active ? filled : outline,
          color: active ? const Color(0xFF00853F) : Colors.grey),
      onPressed: () => setState(() => _currentTab = index),
      tooltip: label,
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF00853F),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00853F), Color(0xFF005A2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sen Annonces',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Rechercher...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.location_on, color: Colors.white),
                            onSelected: (v) => setState(() => _selectedCity = v),
                            itemBuilder: (_) => _cities
                                .map((c) => PopupMenuItem(value: c, child: Text(c)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          title: const Text(''),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Catégories',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) => _categoryChip(_categories[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedCity != 'Toutes les villes')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedCity),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedCity = 'Toutes les villes'),
                    backgroundColor: const Color(0xFFE8F5E9),
                    labelStyle: const TextStyle(color: Color(0xFF00853F)),
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_filteredAds.length} annonces',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Text('Trier', style: TextStyle(color: Color(0xFF00853F))),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _adCard(_filteredAds[i]),
            childCount: _filteredAds.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _categoryChip(Map<String, dynamic> cat) {
    return GestureDetector(
      onTap: () => setState(() => _searchQuery = cat['name']),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
            ),
            const SizedBox(height: 5),
            Text(
              cat['name'] as String,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adCard(Map<String, dynamic> ad) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (ad['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ad['icon'] as IconData, size: 40, color: ad['color'] as Color),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(ad['price'] as String,
                        style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(ad['city'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(ad['time'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: const Text('Mes Favoris', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun favori pour le moment', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: const Text('Mon Profil', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Connectez-vous pour voir votre profil',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
