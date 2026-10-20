import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class ProviderProfilePage extends StatefulWidget {
  final String providerId;

  const ProviderProfilePage({super.key, required this.providerId});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  Map<String, dynamic>? _provider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.providerId)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        _provider = doc.data();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.kBlack)),
      );
    }

    if (_provider == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Provider not found")),
      );
    }

    final provider = _provider!;
    final album = List<String>.from(provider['album'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.kBlack,
            iconTheme: const IconThemeData(color: AppColors.kWhite),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                provider['name'] ?? 'Provider',
                style: const TextStyle(
                  color: AppColors.kWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: album.isNotEmpty
                  ? Image.network(
                      album.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.kBlack,
                          child: const Icon(
                            Icons.storefront,
                            color: AppColors.kWhite,
                            size: 64,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.kBlack,
                      child: const Icon(
                        Icons.storefront,
                        color: AppColors.kWhite,
                        size: 64,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    icon: Icons.category,
                    title: "Service",
                    value: provider['service_type'] ?? 'Service Provider',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: "Address",
                    value: provider['address'] ?? 'No address',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: "Phone",
                    value: provider['phone'] ?? 'Not provided',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.star,
                    title: "Rating",
                    value: provider['rating']?.toString() ?? 'No ratings yet',
                    valueColor: Colors.orange,
                  ),
                  if (provider['description'] != null &&
                      provider['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle("About"),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: Text(
                        provider['description'],
                        style: const TextStyle(
                          color: AppColors.kBlack,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  if (provider['business_hours'] != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle("Business Hours"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: Column(
                        children: (provider['business_hours'] as Map).entries
                            .map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.kBlack,
                                      ),
                                    ),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: entry.value == "Closed"
                                            ? Colors.red
                                            : AppColors.kGreyText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                  if (provider['price_list'] != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "PRICE LIST",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kBlack,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: Column(
                        children: (provider['price_list'] as Map).entries.map((
                          entry,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: AppColors.kBlack,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "₱${entry.value}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kBlack,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionTitle("Location"),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: provider['lat'] != null && provider['lng'] != null
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                provider['lat'].toDouble(),
                                provider['lng'].toDouble(),
                              ),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("provider"),
                                position: LatLng(
                                  provider['lat'].toDouble(),
                                  provider['lng'].toDouble(),
                                ),
                              ),
                            },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          )
                        : const Center(child: Text("No location available")),
                  ),
                  if (album.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle("Photos"),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: album.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              album[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.kBorder,
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
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
                    fontSize: 12,
                    color: AppColors.kGreyText,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.kBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
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
