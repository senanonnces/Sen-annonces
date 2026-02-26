import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'create_ad_screen.dart';
import 'ad_detail_screen.dart';

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
  bool _loadingAds = false;
  List<Map<String, dynamic>> _ads = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Voitures', 'icon': Icons.directions_car, 'color': Color(0xFF2196F3)},
    {'name': 'Immobilier', 'icon': Icons.home_work, 'color': Color(0xFF4CAF50)},
    {'name': 'Electronique', 'icon': Icons.phone_android, 'color': Color(0xFFFF5722)},
    {'name': 'Emploi', 'icon': Icons.work_outline, 'color': Color(0xFF9C27B0)},
    {'name': 'Mode', 'icon': Icons.checkroom, 'color': Color(0xFFE91E63)},
    {'name': 'Maison', 'icon': Icons.chair_alt, 'color': Color(0xFF795548)},
    {'name': 'Sport', 'icon': Icons.sports_soccer, 'color': Color(0xFFFF9800)},
    {'name': 'Animaux', 'icon': Icons.pets, 'color': Color(0xFF009688)},
    {'name': 'Services', 'icon': Icons.construction, 'color': Color(0xFF607D8B)},
    {'name': 'Education', 'icon': Icons.school_outlined, 'color': Color(0xFF3F51B5)},
    {'name': 'Agriculture', 'icon': Icons.agriculture, 'color': Color(0xFF8BC34A)},
    {'name': 'Autres', 'icon': Icons.more_horiz, 'color': Color(0xFF9E9E9E)},
  ];

  final List<String> _cities = [
    'Toutes','Dakar','Thies','Saint-Louis','Ziguinchor','Kaolack','Mbour','Touba','Diourbel',
  ];

  final List<Map<String, dynamic>> _demoAds = [
    {'id':'1','title':'Toyota Corolla 2019','price':8500000,'category':'Voitures','city':'Dakar','icon':Icons.directions_car,'color':Color(0xFF2196F3),'description':'Voiture en excellent etat, climatisee.'},
    {'id':'2','title':'Appartement F3 a Plateau','price':350000,'category':'Immobilier','city':'Dakar','icon':Icons.home_work,'color':Color(0xFF4CAF50),'description':'Bel appartement F3 au Plateau.'},
    {'id':'3','title':'iPhone 14 Pro Max 256GB','price':650000,'category':'Electronique','city':'Thies','icon':Icons.phone_android,'color':Color(0xFFFF5722),'description':'iPhone 14 Pro Max en parfait etat.'},
    {'id':'4','title':'Terrain 500m2 a Mbour','price':5000000,'category':'Immobilier','city':'Mbour','icon':Icons.home_work,'color':Color(0xFF4CAF50),'description':'Grand terrain constructible.'},
    {'id':'5','title':'Samsung Galaxy S23','price':450000,'category':'Electronique','city':'Dakar','icon':Icons.phone_android,'color':Color(0xFFFF5722),'description':'Samsung Galaxy S23 neuf.'},
    {'id':'6','title':'Moto Jakarta 2022','price':750000,'category':'Voitures','city':'Kaolack','icon':Icons.directions_car,'color':Color(0xFF2196F3),'description':'Moto Jakarta en bon etat.'},
  ];

  @override
  void initState() { super.initState(); _loadAds(); }

  Future<void> _loadAds() async {
    setState(() => _loadingAds = true);
    try {
      final response = await Supabase.instance.client
          .from('annonces').select().eq('is_active', true)
          .order('created_at', ascending: false).limit(50);
      if (mounted) setState(() { _ads = List<Map<String, dynamic>>.from(response); _loadingAds = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingAds = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAds {
    final source = _ads.isEmpty ? _demoAds : _ads;
    return source.where((ad) {
      final matchSearch = _searchQuery.isEmpty ||
          (ad['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == null || ad['category'] == _selectedCategory;
      final matchCity = _selectedCity == null || _selectedCity == 'Toutes' || ad['city'] == _selectedCity;
      return matchSearch && matchCat && matchCity;
    }).toList();
  }

  bool get _isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '\${(p / 1000000).toStringAsFixed(1)} M';
    if (p >= 1000) return '\${(p / 1000).toStringAsFixed(0)} K';
    return p.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [_buildHome(), _buildFavorites(), _buildProfile()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!_isLoggedIn) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; }
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAdScreen()));
        },
        backgroundColor: const Color(0xFF00853F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.home, color: _currentIndex == 0 ? const Color(0xFF00853F) : Colors.grey),
                onPressed: () => setState(() => _currentIndex = 0)),
            IconButton(icon: Icon(Icons.favorite_border, color: _currentIndex == 1 ? const Color(0xFF00853F) : Colors.grey),
                onPressed: () => setState(() => _currentIndex = 1)),
            const SizedBox(width: 48),
            IconButton(icon: Icon(Icons.person_outline, color: _currentIndex == 2 ? const Color(0xFF00853F) : Colors.grey),
                onPressed: () => setState(() => _currentIndex = 2)),
            IconButton(
              icon: Icon(_isLoggedIn ? Icons.logout : Icons.login, color: Colors.grey),
              onPressed: _isLoggedIn ? _logout : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 130, floating: true, backgroundColor: const Color(0xFF00853F),
        flexibleSpace: FlexibleSpaceBar(
          background: Padding(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Sen Annonces', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...', prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                      border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  ),
                )),
                const SizedBox(width: 8),
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.location_on, color: Colors.white, size: 20),
                    onSelected: (v) => setState(() => _selectedCity = v),
                    itemBuilder: (_) => _cities.map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
      SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16,16,16,8),
            child: Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = selected ? null : cat['name'] as String),
                child: Container(
                  width: 70, margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: selected ? (cat['color'] as Color) : (cat['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(cat['icon'] as IconData,
                          color: selected ? Colors.white : cat['color'] as Color, size: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(cat['name'] as String, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500,
                            color: selected ? cat['color'] as Color : Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16,16,16,8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('\${_filteredAds.length} annonces', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (_selectedCity != null && _selectedCity != 'Toutes')
              Chip(label: Text(_selectedCity!, style: const TextStyle(fontSize: 11)),
                  onDeleted: () => setState(() => _selectedCity = null),
                  deleteIconColor: Colors.grey, backgroundColor: const Color(0xFFF0F0F0), padding: EdgeInsets.zero),
          ]),
        ),
      ])),
      _loadingAds
          ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF00853F))))
          : SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => _buildAdCard(_filteredAds[i]), childCount: _filteredAds.length)),
    ]);
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
        child: Row(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
                color: (ad['color'] as Color? ?? Colors.grey).withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14))),
            child: Icon(ad['icon'] as IconData? ?? Icons.image, size: 40, color: ad['color'] as Color? ?? Colors.grey),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('\${_formatPrice(ad['price'])} FCFA',
                  style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                Text(ad['city'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ]),
          )),
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.grey, size: 20), onPressed: () {}),
        ]),
      ),
    );
  }

  Widget _buildFavorites() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.favorite_border, size: 60, color: Colors.grey),
    SizedBox(height: 16),
    Text('Aucun favori', style: TextStyle(color: Colors.grey, fontSize: 16)),
  ]));

  Widget _buildProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircleAvatar(radius: 40, backgroundColor: Color(0xFF00853F),
          child: Icon(Icons.person, size: 45, color: Colors.white)),
      const SizedBox(height: 16),
      Text(user?.email ?? 'Non connecte', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      if (!_isLoggedIn) ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00853F)),
        child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
      ),
    ]));
  }
}
