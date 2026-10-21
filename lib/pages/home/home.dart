import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:serbisyo_ph/pages/find-service/find_service.dart';
import 'package:serbisyo_ph/pages/active_orders/order_details_page.dart';
import 'package:serbisyo_ph/pages/settings/settings_page.dart';
import 'package:serbisyo_ph/theme/design_system.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = '';
  String _userLocation = 'Locating...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _loadUserName();
    await _loadUserLocation();
    setState(() => _loading = false);
  }

  Future<void> _loadUserName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _userLocation = 'Location unavailable');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _userLocation = 'Location denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _userLocation = 'Tap to enable');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        String location =
            place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        setState(() => _userLocation = location);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userLocation = 'Location unavailable');
      }
    }
  }

  Widget _buildActiveOrdersSection() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _buildEmptyOrdersCard("Sign in to view orders");
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customer_id', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
          .orderBy('created_at', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(DS.spaceLg),
            child: Center(child: CircularProgressIndicator(color: AppColors.kBlack)),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyOrdersCard("Unable to load active orders");
        }

        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return _buildEmptyOrdersCard("No active orders");
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox();

              return _buildOrderCard(
                data['service_type'] ?? 'Service',
                data['status'] ?? 'pending',
                order.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyOrdersCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
      child: DSCard(
        padding: const EdgeInsets.all(DS.spaceLg),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: AppColors.kBorder,
              size: DS.iconLg,
            ),
            const SizedBox(width: DS.spaceMd),
            DSText.bodySmall(message),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String service, String status, String orderId) {
    IconData icon;

    icon = serviceIcon(service);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(orderId: orderId),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: DS.spaceMd),
        padding: const EdgeInsets.all(DS.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(DS.radiusLg),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(DS.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.circular(DS.radiusMd),
              ),
              child: Icon(icon, color: AppColors.kWhite, size: DS.iconSm),
            ),
            const SizedBox(height: DS.spaceMd),
            DSText.titleMedium(service),
            const Spacer(),
            DSStatusBadge(status: status),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promotions')
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final promotions = snapshot.data?.docs ?? [];

        if (promotions.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final doc = promotions[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final discount = data['discount'] ?? '';
              final providerName = data['provider_name'] ?? '';

              return PromotionCard(
                title: discount.isNotEmpty ? discount : title,
                subtitle: providerName,
                color: _getRandomColor(index),
              );
            },
          ),
        );
      },
    );
  }

  Color _getRandomColor(int index) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.green,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
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
                      DSText.caption("YOUR LOCATION"),
                      const SizedBox(height: DS.spaceXs),
                      GestureDetector(
                        onTap: _loadUserLocation,
                        child: DSText.headlineLarge(_userLocation, color: AppColors.kWhite),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
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
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DS.spaceMd),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    child: Column(
                      children: [
                        const SizedBox(height: DS.spaceLg),
                        DSText.headlineLarge(_loading ? 'Loading...' : 'Hi $_userName!'),
                        const SizedBox(height: DS.spaceLg),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.kWhite,
                            borderRadius: BorderRadius.circular(DS.radiusXl),
                            border: Border.all(color: AppColors.kBorder),
                          ),
                          child: TextField(
                            cursorColor: AppColors.kBlack,
                            decoration: InputDecoration(
                              hintText: "What service do you need?",
                              hintStyle: DS.bodySmall,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.kBlack,
                                size: DS.iconMd,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DS.radiusXl),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: DS.spaceMd),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DS.space2xl),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    child: DSSectionHeader(title: "Services"),
                  ),

                  const SizedBox(height: DS.spaceLg),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: DS.spaceMd,
                      crossAxisSpacing: DS.spaceMd,
                      children: [
                        ServiceItem(
                          icon: Icons.local_laundry_service_outlined,
                          label: "Laundry",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FindService(
                                  selectedFilter: "Laundry",
                                ),
                              ),
                            );
                          },
                        ),
                        ServiceItem(
                          icon: Icons.water_drop_outlined,
                          label: "Water",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FindService(
                                  selectedFilter: "Water Refill",
                                ),
                              ),
                            );
                          },
                        ),
                        ServiceItem(
                          icon: Icons.gas_meter_rounded,
                          label: "LPG",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FindService(
                                  selectedFilter: "LPG Refill",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: DS.space2xl),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    child: DSSectionHeader(title: "Active Orders"),
                  ),

                  const SizedBox(height: DS.spaceMd),

                  _buildActiveOrdersSection(),

                  const SizedBox(height: DS.space2xl),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    child: DSSectionHeader(title: "Nearby Services"),
                  ),

                  const SizedBox(height: DS.spaceMd),

                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
                      children: const [
                        ProviderCard(name: "QuickWash"),
                        ProviderCard(name: "AquaPure"),
                        ProviderCard(name: "Juan Clean"),
                        ProviderCard(name: "FreshLab"),
                      ],
                    ),
                  ),

                  const SizedBox(height: DS.space2xl),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    child: DSSectionHeader(title: "Promotions"),
                  ),

                  const SizedBox(height: DS.spaceMd),

                  _buildPromotionsSection(),

                  const SizedBox(height: DS.space2xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ServiceItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.radiusLg),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.kWhite,
              borderRadius: BorderRadius.circular(DS.radiusLg),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Icon(icon, color: AppColors.kBlack, size: DS.iconLg),
          ),
          const SizedBox(height: DS.spaceMd),
          DSText.labelSmall(label, align: TextAlign.center),
        ],
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  final String name;

  const ProviderCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceMd, vertical: DS.spaceSm),
      margin: const EdgeInsets.only(right: DS.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_outlined, size: DS.iconSm),
          const SizedBox(width: DS.spaceXs),
          DSText.labelMedium(name),
          const SizedBox(width: DS.spaceXs),
          const Icon(Icons.star, size: DS.iconXs),
          const SizedBox(width: DS.spaceXs),
          DSText.labelSmall("4.8"),
        ],
      ),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const PromotionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: DS.spaceMd),
      padding: const EdgeInsets.all(DS.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DS.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText.headlineMedium(title, color: AppColors.kWhite),
          const SizedBox(height: DS.spaceXs),
          DSText.bodySmall(subtitle, color: AppColors.kWhite),
          const Spacer(),
          DSText.labelSmall("Tap to avail", color: AppColors.kWhite),
        ],
      ),
    );
  }
}