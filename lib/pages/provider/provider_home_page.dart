import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/pages/provider/provider_settings.dart';
import 'package:serbisyo_ph/pages/provider/provider_album_page.dart';
import 'package:serbisyo_ph/maps/map_picker.dart';
import 'package:serbisyo_ph/theme/design_system.dart';

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
            behavior: SnackBarBehavior.floating,
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
            padding: const EdgeInsets.fromLTRB(DS.spaceLg, 50, DS.spaceLg, DS.spaceLg),
            decoration: const BoxDecoration(
              color: AppColors.kBlack,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(DS.radiusXl),
                bottomRight: Radius.circular(DS.radiusXl),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DSText.headlineMedium(_providerName, color: AppColors.kWhite),
                          const SizedBox(width: DS.spaceSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DS.spaceSm,
                              vertical: DS.spaceXs,
                            ),
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? Colors.green
                                  : Colors.red.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(DS.radiusFull),
                            ),
                            child: DSText.labelSmall(
                              _isOnline ? "Online" : "Offline",
                              color: AppColors.kWhite,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DS.spaceXs),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: DS.iconSm),
                          const SizedBox(width: DS.spaceXs),
                          DSText.bodyMedium(
                            _rating > 0
                                ? _rating.toStringAsFixed(1)
                                : "No ratings yet",
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: DS.spaceXs),
                      DSText.bodySmall(
                        _businessAddress.isNotEmpty
                            ? _businessAddress
                            : 'No address set',
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProviderSettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings, color: AppColors.kWhite, size: DS.iconMd),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.radiusMd),
                    ),
                    fixedSize: const Size(42, 42),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DS.spaceMd),
                  _buildLocationBanner(),
                  const SizedBox(height: DS.spaceLg),
                  _buildStatsSection(),
                  const SizedBox(height: DS.spaceXl),
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
      return DSCard(
        padding: const EdgeInsets.all(DS.spaceLg),
        color: Colors.green.withValues(alpha: 0.05),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DS.spaceSm),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DS.radiusMd),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: DS.iconMd),
            ),
            const SizedBox(width: DS.spaceLg),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText.titleMedium("You're on the map!", color: Colors.green),
                  DSText.bodySmall("Customers can find you", color: Colors.green),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return DSCard(
      padding: const EdgeInsets.all(DS.spaceLg),
      color: Colors.orange.withValues(alpha: 0.05),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DS.spaceSm),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DS.radiusMd),
            ),
            child: const Icon(Icons.location_off, color: Colors.orange, size: DS.iconMd),
          ),
          const SizedBox(width: DS.spaceLg),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText.titleMedium("Set your location", color: Colors.orange),
                DSText.bodySmall("Add your location to appear on the map", color: Colors.orange),
              ],
            ),
          ),
          DSButton.primary(
            label: "Set",
            onPressed: _setLocation,
            height: DS.btnHeightSm,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSSectionHeader(title: "Today's Stats"),
        const SizedBox(height: DS.spaceMd),
        Row(
          children: [
            Expanded(
              child: DSStatCard(
                icon: Icons.receipt_long,
                value: _todayOrders.toString(),
                label: "Orders",
                color: AppColors.kBlack,
              ),
            ),
            const SizedBox(width: DS.spaceMd),
            Expanded(
              child: DSStatCard(
                icon: Icons.attach_money,
                value: "₱$_totalEarnings",
                label: "Earnings",
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: DS.spaceXl),
        _buildEarningsHistory(),
      ],
    );
  }

  Widget _buildEarningsHistory() {
    if (_earningsHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSSectionHeader(title: "Earnings History"),
        const SizedBox(height: DS.spaceMd),
        ..._earningsHistory.map(
          (item) => DSCard(
            padding: const EdgeInsets.all(DS.spaceLg),
            margin: const EdgeInsets.only(bottom: DS.spaceMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DSText.titleMedium(item['period']),
                DSText.headlineMedium("₱${item['amount']}", color: Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSSectionHeader(title: "Quick Actions"),
        const SizedBox(height: DS.spaceMd),
        DSActionTile(
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
        const SizedBox(height: DS.spaceMd),
        DSActionTile(
          icon: Icons.map,
          title: "Location",
          subtitle: _hasLocation ? "Update your location" : "Set your location",
          onTap: _setLocation,
        ),
        const SizedBox(height: DS.spaceMd),
        DSActionTile(
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
}