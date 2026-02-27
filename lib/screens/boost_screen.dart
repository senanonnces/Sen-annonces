import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

// ===== PAYDUNYA CONFIG =====
class PayDunyaConfig {
  static const String masterKey = 'cN5QrHLIEuuIJi7kEHBI';
  static const String privateKey = 'live_private_eV2nDieusk4adJ3G7fZ5jlgwS47';
  static const String publicKey = 'live_public_n6Y1rlmlnxt4JU3drav9CLWCs57';
  static const String baseUrl = 'https://app.paydunya.com/api/v1';
}

// ===== BOOST PLANS =====
class BoostPlan {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final int days;
  final Color color;
  final String description;
  final List<String> features;

  const BoostPlan({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.days,
    required this.color,
    required this.description,
    required this.features,
  });
}

const List<BoostPlan> boostPlans = [
  BoostPlan(
    id: 'basique',
    name: 'Basique',
    emoji: '🥉',
    price: 1000,
    days: 3,
    color: Color(0xFF795548),
    description: '3 jours en avant',
    features: ['Annonce en haut de liste', 'Badge Boost', '3 jours de visibilité'],
  ),
  BoostPlan(
    id: 'standard',
    name: 'Standard',
    emoji: '🥈',
    price: 2000,
    days: 7,
    color: Color(0xFF1565C0),
    description: '7 jours de visibilité maximale',
    features: ['Annonce en haut de liste', 'Badge Boost ⭐', '7 jours de visibilité', 'Plus de contacts'],
  ),
  BoostPlan(
    id: 'premium',
    name: 'Premium',
    emoji: '🥇',
    price: 5000,
    days: 30,
    color: Color(0xFFE65100),
    description: '30 jours — Visibilité maximale!',
    features: ['Annonce en tête de liste', 'Badge Premium 🔥', '30 jours de visibilité', 'Maximum de contacts', 'Mise en avant spéciale'],
  ),
];

// ===== BOOST SCREEN =====
class BoostScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  const BoostScreen({super.key, required this.ad});
  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  BoostPlan? _selectedPlan;
  String? _selectedPayment; // 'wave', 'orange', 'visa'
  bool _loading = false;
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      final user = jsonDecode(userJson);
      _phoneCtrl.text = user['phone']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    if (_selectedPlan == null) {
      _showSnack('Choisissez un forfait Boost', Colors.orange);
      return;
    }
    if (_selectedPayment == null) {
      _showSnack('Choisissez une méthode de paiement', Colors.orange);
      return;
    }
    if (_selectedPayment != 'visa' && _phoneCtrl.text.trim().length < 8) {
      _showSnack('Entrez votre numéro de téléphone', Colors.orange);
      return;
    }

    setState(() => _loading = true);

    try {
      // Step 1: Create invoice on PayDunya
      final invoiceToken = await _createPayDunyaInvoice();
      if (invoiceToken == null) {
        _showSnack('Erreur de connexion à PayDunya', Colors.red);
        return;
      }

      if (_selectedPayment == 'visa') {
        // For card payment → open PayDunya checkout URL
        final checkoutUrl = 'https://app.paydunya.com/checkout/invoice/$invoiceToken';
        await _openPaymentUrl(checkoutUrl, invoiceToken);
      } else {
        // For Wave / Orange Money → direct API pay
        await _directPay(invoiceToken);
      }
    } catch (e) {
      _showSnack('Erreur: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _createPayDunyaInvoice() async {
    try {
      final plan = _selectedPlan!;
      final body = jsonEncode({
        'invoice': {
          'total_amount': plan.price,
          'description': 'Boost annonce: ${widget.ad['title']} - ${plan.name} (${plan.days} jours)',
        },
        'store': {
          'name': 'Sen Annonces',
        },
        'actions': {
          'cancel_url': 'https://sen-annonces.com/cancel',
          'return_url': 'https://sen-annonces.com/success',
          'callback_url': 'https://sen-annonces.com/callback',
        },
        'custom_data': {
          'ad_id': widget.ad['id'],
          'boost_plan': plan.id,
          'boost_days': plan.days,
        },
      });

      final response = await http.post(
        Uri.parse('${PayDunyaConfig.baseUrl}/checkout-invoice/create'),
        headers: {
          'Content-Type': 'application/json',
          'PAYDUNYA-MASTER-KEY': PayDunyaConfig.masterKey,
          'PAYDUNYA-PRIVATE-KEY': PayDunyaConfig.privateKey,
          'PAYDUNYA-PUBLIC-KEY': PayDunyaConfig.publicKey,
        },
        body: body,
      );

      final data = jsonDecode(response.body);
      if (data['response_code'] == '00') {
        return data['token'];
      } else {
        debugPrint('PayDunya error: ${data['response_text']}');
        return null;
      }
    } catch (e) {
      debugPrint('Invoice creation error: $e');
      return null;
    }
  }

  Future<void> _directPay(String invoiceToken) async {
    try {
      final phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      String endpoint;
      Map<String, dynamic> payBody;

      if (_selectedPayment == 'wave') {
        endpoint = '${PayDunyaConfig.baseUrl}/softpay/wave-senegal';
        payBody = {
          'invoice_token': invoiceToken,
          'wave_senegal_fullname': widget.ad['seller_name'] ?? 'Client',
          'wave_senegal_email': 'client@sen-annonces.com',
          'wave_senegal_phone': phone,
          'wave_senegal_payment_token': invoiceToken,
        };
      } else {
        // Orange Money
        endpoint = '${PayDunyaConfig.baseUrl}/softpay/orange-money-senegal';
        payBody = {
          'invoice_token': invoiceToken,
          'orange_money_senegal_fullname': widget.ad['seller_name'] ?? 'Client',
          'orange_money_senegal_email': 'client@sen-annonces.com',
          'orange_money_senegal_phone': phone,
        };
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'PAYDUNYA-MASTER-KEY': PayDunyaConfig.masterKey,
          'PAYDUNYA-PRIVATE-KEY': PayDunyaConfig.privateKey,
          'PAYDUNYA-PUBLIC-KEY': PayDunyaConfig.publicKey,
        },
        body: jsonEncode(payBody),
      );

      final data = jsonDecode(response.body);
      debugPrint('Pay response: $data');

      if (data['response_code'] == '00') {
        // Wave returns a URL to open
        if (_selectedPayment == 'wave' && data['payment_url'] != null) {
          await _openPaymentUrl(data['payment_url'], invoiceToken);
        } else {
          // Orange Money — wait for confirmation
          await _waitForPaymentConfirmation(invoiceToken);
        }
      } else {
        // Try checkout URL as fallback
        final checkoutUrl = 'https://app.paydunya.com/checkout/invoice/$invoiceToken';
        await _openPaymentUrl(checkoutUrl, invoiceToken);
      }
    } catch (e) {
      // Fallback to checkout URL
      final checkoutUrl = 'https://app.paydunya.com/checkout/invoice/$invoiceToken';
      await _openPaymentUrl(checkoutUrl, invoiceToken);
    }
  }

  Future<void> _openPaymentUrl(String url, String invoiceToken) async {
    if (!mounted) return;
    // Open payment page then check status
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebScreen(
          url: url,
          invoiceToken: invoiceToken,
          plan: _selectedPlan!,
          ad: widget.ad,
        ),
      ),
    );
    if (result == true && mounted) {
      await _activateBoost();
    }
  }

  Future<void> _waitForPaymentConfirmation(String invoiceToken) async {
    if (!mounted) return;
    _showSnack('Validez le paiement sur votre téléphone...', const Color(0xFF00853F));

    // Show waiting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: Color(0xFFFF7900)),
          const SizedBox(height: 16),
          const Text('En attente de votre confirmation...', textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Validez le paiement sur votre téléphone Orange Money',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ]),
      ),
    );

    // Poll for 60 seconds
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      final paid = await _checkPaymentStatus(invoiceToken);
      if (paid) {
        if (mounted) Navigator.pop(context); // close dialog
        await _activateBoost();
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context); // close dialog
      _showSnack('Paiement non confirmé. Réessayez.', Colors.orange);
    }
  }

  Future<bool> _checkPaymentStatus(String invoiceToken) async {
    try {
      final response = await http.get(
        Uri.parse('${PayDunyaConfig.baseUrl}/checkout-invoice/confirm/$invoiceToken'),
        headers: {
          'PAYDUNYA-MASTER-KEY': PayDunyaConfig.masterKey,
          'PAYDUNYA-PRIVATE-KEY': PayDunyaConfig.privateKey,
          'PAYDUNYA-PUBLIC-KEY': PayDunyaConfig.publicKey,
        },
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'completed';
    } catch (_) {
      return false;
    }
  }

  Future<void> _activateBoost() async {
    final plan = _selectedPlan!;
    final prefs = await SharedPreferences.getInstance();
    final adsJson = prefs.getString('ads') ?? '[]';
    final ads = List<Map<String, dynamic>>.from(
        (jsonDecode(adsJson) as List).map((e) => Map<String, dynamic>.from(e)));

    final adIndex = ads.indexWhere((a) => a['id'] == widget.ad['id']);
    if (adIndex != -1) {
      final boostExpiry = DateTime.now().add(Duration(days: plan.days));
      ads[adIndex]['is_boosted'] = true;
      ads[adIndex]['boost_plan'] = plan.id;
      ads[adIndex]['boost_expiry'] = boostExpiry.toIso8601String();
      await prefs.setString('ads', jsonEncode(ads));
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('Boost ${plan.name} activé!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Votre annonce sera en tête de liste pendant ${plan.days} jours',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00853F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Super! Merci 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: const Text('Booster mon annonce 🚀',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Ad preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00853F).withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF00853F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign, color: Color(0xFF00853F), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.ad['title'] ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_formatPrice(widget.ad['price']),
                    style: const TextStyle(color: Color(0xFF00853F), fontWeight: FontWeight.bold)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Why boost
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00853F), Color(0xFF00A651)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Text('🚀', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pourquoi Booster?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('Votre annonce apparaît en 1ère position\net reçoit 10x plus de contacts!',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Plans
          const Text('Choisir un forfait',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...boostPlans.map((plan) => GestureDetector(
            onTap: () => setState(() => _selectedPlan = plan),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _selectedPlan?.id == plan.id ? plan.color.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedPlan?.id == plan.id ? plan.color : Colors.grey.shade200,
                  width: _selectedPlan?.id == plan.id ? 2 : 1,
                ),
                boxShadow: [BoxShadow(
                  color: _selectedPlan?.id == plan.id
                      ? plan.color.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Text(plan.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(plan.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: plan.color)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: plan.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${plan.days} jours',
                            style: TextStyle(color: plan.color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    ...plan.features.take(2).map((f) => Row(children: [
                      Icon(Icons.check_circle, size: 13, color: plan.color),
                      const SizedBox(width: 4),
                      Text(f, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ])).toList(),
                  ])),
                  Column(children: [
                    Text('${_formatNum(plan.price)}', style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: plan.color)),
                    Text('FCFA', style: TextStyle(color: plan.color, fontSize: 11)),
                  ]),
                  const SizedBox(width: 8),
                  Icon(
                    _selectedPlan?.id == plan.id ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _selectedPlan?.id == plan.id ? plan.color : Colors.grey,
                  ),
                ]),
              ),
            ),
          )).toList(),

          const SizedBox(height: 8),
          const Text('Méthode de paiement',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Payment methods
          Row(children: [
            _paymentBtn('wave', '🌊', 'Wave', const Color(0xFF1BA7FF)),
            const SizedBox(width: 10),
            _paymentBtn('orange', '🟠', 'Orange\nMoney', const Color(0xFFFF7900)),
            const SizedBox(width: 10),
            _paymentBtn('visa', '💳', 'Carte\nBancaire', const Color(0xFF1565C0)),
          ]),
          const SizedBox(height: 16),

          // Phone number (for Wave/Orange)
          if (_selectedPayment == 'wave' || _selectedPayment == 'orange') ...[
            Text(
              _selectedPayment == 'wave' ? 'Numéro Wave' : 'Numéro Orange Money',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ex: 77 XXX XX XX',
                prefixIcon: Icon(
                  _selectedPayment == 'wave' ? Icons.waves : Icons.phone,
                  color: _selectedPayment == 'wave' ? const Color(0xFF1BA7FF) : const Color(0xFFFF7900),
                ),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _selectedPayment == 'wave' ? const Color(0xFF1BA7FF) : const Color(0xFFFF7900),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Summary box
          if (_selectedPlan != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedPlan!.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selectedPlan!.color.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.receipt_long, color: _selectedPlan!.color),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Récapitulatif',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _selectedPlan!.color)),
                  Text('${_selectedPlan!.name} — ${_selectedPlan!.days} jours',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ])),
                Text('${_formatNum(_selectedPlan!.price)} FCFA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _selectedPlan!.color)),
              ]),
            ),

          const SizedBox(height: 20),

          // Pay button
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00853F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              child: _loading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                      SizedBox(width: 12),
                      Text('Traitement en cours...', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🚀', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        _selectedPlan != null
                            ? 'Payer ${_formatNum(_selectedPlan!.price)} FCFA'
                            : 'Booster maintenant',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ]),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _paymentBtn(String id, String emoji, String label, Color color) {
    final isSelected = _selectedPayment == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPayment = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.grey[700])),
          ]),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final p = int.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M FCFA';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K FCFA';
    return '$p FCFA';
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return n.toString();
  }
}

// ===== PAYMENT WEB SCREEN =====
class PaymentWebScreen extends StatefulWidget {
  final String url;
  final String invoiceToken;
  final BoostPlan plan;
  final Map<String, dynamic> ad;

  const PaymentWebScreen({
    super.key,
    required this.url,
    required this.invoiceToken,
    required this.plan,
    required this.ad,
  });
  @override
  State<PaymentWebScreen> createState() => _PaymentWebScreenState();
}

class _PaymentWebScreenState extends State<PaymentWebScreen> {
  bool _checking = false;

  Future<void> _checkAndConfirm() async {
    setState(() => _checking = true);
    try {
      final response = await http.get(
        Uri.parse('${PayDunyaConfig.baseUrl}/checkout-invoice/confirm/${widget.invoiceToken}'),
        headers: {
          'PAYDUNYA-MASTER-KEY': PayDunyaConfig.masterKey,
          'PAYDUNYA-PRIVATE-KEY': PayDunyaConfig.privateKey,
          'PAYDUNYA-PUBLIC-KEY': PayDunyaConfig.publicKey,
        },
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        if (data['status'] == 'completed') {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paiement non confirmé. Réessayez.'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00853F),
        title: Text('Paiement ${widget.plan.name}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          TextButton(
            onPressed: _checking ? null : _checkAndConfirm,
            child: _checking
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('J\'ai payé ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(children: [
        // Payment info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF00853F).withOpacity(0.08),
          child: Row(children: [
            const Text('💳', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Paiement ${widget.plan.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Montant: ${widget.plan.price} FCFA — ${widget.plan.days} jours de Boost',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ])),
          ]),
        ),
        // Open in browser button
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)],
                  ),
                  child: Column(children: [
                    const Text('💳', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text('Paiement ${widget.plan.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text('${widget.plan.price} FCFA',
                        style: TextStyle(
                            color: widget.plan.color, fontWeight: FontWeight.bold, fontSize: 28)),
                    const SizedBox(height: 6),
                    Text('${widget.plan.days} jours de visibilité',
                        style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await launchUrl(Uri.parse(widget.url),
                              mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.open_in_browser, color: Colors.white),
                        label: const Text('Ouvrir la page de paiement',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00853F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Après le paiement, appuyez sur "J\'ai payé ✓" en haut',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
