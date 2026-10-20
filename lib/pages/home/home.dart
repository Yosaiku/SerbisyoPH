import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:serbisyo_ph/pages/find-service/find_service.dart';
import 'package:serbisyo_ph/pages/active_orders/order_details_page.dart';
import 'package:serbisyo_ph/pages/settings/settings_page.dart';
import 'package:serbisyo_ph/theme/colors.dart';
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
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: AppColors.kBorder,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.kGreyText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String service, String status, String orderId) {
    Color statusColor;
    String statusText;
    IconData icon;

    icon = serviceIcon(service);

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Searching...';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Accepted';
        break;
      case 'in_progress':
        statusColor = Colors.purple;
        statusText = 'In Progress';
        break;
      default:
        statusColor = AppColors.kGreyText;
        statusText = status;
    }

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
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.kWhite, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              service,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.kBlack,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.kBlack,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "YOUR LOCATION",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _loadUserLocation,
                        child: Text(
                          _userLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.kWhite,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
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
                        builder: (context) => const SettingsPage(),
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
                    child: const Icon(Icons.settings, color: AppColors.kWhite),
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
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          _loading ? 'Loading...' : 'Hi $_userName!',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.kBlack,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.kWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.kBorder),
                          ),
                          child: TextField(
                            cursorColor: AppColors.kBlack,
                            decoration: InputDecoration(
                              hintText: "What service do you need?",
                              hintStyle: const TextStyle(
                                color: AppColors.kGreyText,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.kBlack,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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

                  const SizedBox(height: 30),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Active Orders",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildActiveOrdersSection(),

                  const SizedBox(height: 30),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Nearby Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: const [
                        ProviderCard(name: "QuickWash"),
                        ProviderCard(name: "AquaPure"),
                        ProviderCard(name: "Juan Clean"),
                        ProviderCard(name: "FreshLab"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Promotions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kBlack,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildPromotionsSection(),

                  const SizedBox(height: 40),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Icon(icon, color: AppColors.kBlack, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlack,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, size: 18),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.star, size: 14),
          const SizedBox(width: 2),
          const Text("4.8", style: TextStyle(fontSize: 12)),
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
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.kWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.kWhite),
          ),
          const Spacer(),
          const Text(
            "Tap to avail",
            style: TextStyle(
              fontSize: 10,
              color: AppColors.kWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
