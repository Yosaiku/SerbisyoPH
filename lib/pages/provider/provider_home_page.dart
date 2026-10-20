import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/pages/provider/provider_settings.dart';
import 'package:serbisyo_ph/pages/provider/provider_album_page.dart';
import 'package:serbisyo_ph/maps/map_picker.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class ProviderHomePage extends StatefulWidget {
  const ProviderHomePage({super.key});

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  String _providerName = '';
  String _businessAddress = '';
  bool _hasLocation = false;
  bool _isOnline = false;
  double _rating = 0.0;
  bool _loading = true;
  int _todayOrders = 0;
  int _totalEarnings = 0;
  List<Map<String, dynamic>> _earningsHistory = [];

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _providerName = data['name'] ?? 'Provider';
          _businessAddress = data['address'] ?? '';
          _hasLocation = data['has_location'] ?? false;
          _isOnline = data['is_online'] ?? false;
          _rating = (data['rating'] ?? 0.0).toDouble();
        });
      }

      await _loadStats(userId);
      await _loadEarningsHistory(userId);
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _loadStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('provider_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final todayOrders = ordersSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['created_at'];
        if (createdAt is Timestamp) {
          return createdAt.toDate().isAfter(startOfDay);
        }
        return false;
      }).length;

      int totalEarnings = 0;
      for (var doc in ordersSnapshot.docs) {
        final price = doc.data()['price'];
        if (price != null) {
          totalEarnings += (price as num).toInt();
        }
      }

      if (mounted) {
        setState(() {
          _todayOrders = todayOrders;
          _totalEarnings = totalEarnings;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadEarningsHistory(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('provider_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      int weeklyEarnings = 0;
      int monthlyEarnings = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['created_at'];
        final price = data['price'] as num? ?? 0;

        if (createdAt is Timestamp) {
          final orderDate = createdAt.toDate();
          if (orderDate.isAfter(startOfWeek)) {
            weeklyEarnings += price.toInt();
          }
          if (orderDate.isAfter(startOfMonth)) {
            monthlyEarnings += price.toInt();
          }
        }
      }

      if (mounted) {
        setState(() {
          _earningsHistory = [
            {'period': 'Today', 'amount': _totalEarnings},
            {'period': 'This Week', 'amount': weeklyEarnings},
            {'period': 'This Month', 'amount': monthlyEarnings},
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading earnings history: $e');
    }
  }

  Future<void> _setLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (result != null && mounted) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'address': result['address'],
              'lat': result['lat'],
              'lng': result['lng'],
              'has_location': true,
            });

        setState(() {
          _businessAddress = result['address'];
          _hasLocation = true;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location set! You're now visible on the map."),
            backgroundColor: AppColors.kBlack,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kBlack),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.kBlack,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _providerName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: AppColors.kWhite,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _isOnline
                                      ? Colors.green
                                      : Colors.red.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isOnline ? "Online" : "Offline",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.kWhite,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.orange, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                _rating > 0
                                    ? _rating.toStringAsFixed(1)
                                    : "No ratings yet",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _businessAddress.isNotEmpty
                                ? _businessAddress
                                : 'No address set',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProviderSettingsPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: AppColors.kWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildLocationBanner(),
                  const SizedBox(height: 20),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBanner() {
    if (_hasLocation) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're on the map!",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Customers can find you",
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_off, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set your location",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  "Add your location to appear on the map",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _setLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S STATS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.kBlack,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.receipt_long,
                value: _todayOrders.toString(),
                label: "Orders",
                color: AppColors.kBlack,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                value: "₱$_totalEarnings",
                label: "Earnings",
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildEarningsHistory(),
      ],
    );
  }

  Widget _buildEarningsHistory() {
    if (_earningsHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "EARNINGS HISTORY",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.kBlack,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ..._earningsHistory.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.kWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['period'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlack,
                  ),
                ),
                Text(
                  "₱${item['amount']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.kGreyText),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Quick Actions"),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.storefront,
          title: "Business Profile",
          subtitle: "Update your business details",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProviderSettingsPage(),
              ),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.map,
          title: "Location",
          subtitle: _hasLocation ? "Update your location" : "Set your location",
          onTap: _setLocation,
        ),
        _buildActionTile(
          icon: Icons.photo_library,
          title: "Photo Album",
          subtitle: "Showcase your work",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProviderAlbumPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.kBlack.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.kBlack),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.kBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kGreyText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.kGreyText),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.kGreyText,
        letterSpacing: 0.8,
      ),
    );
  }
}
