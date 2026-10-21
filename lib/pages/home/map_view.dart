import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:serbisyo_ph/theme/colors.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? mapController;
  LatLng? userLocation;
  bool _loading = true;
  Set<Marker> markers = {};
  List<Map<String, dynamic>> providers = [];
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Laundry', 'Water Refill', 'LPG Refill'];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });

      if (userLocation != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(userLocation!, 14),
        );
        await _loadProviders(userLocation!);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProviders(LatLng location) async {
    try {
      QuerySnapshot snapshot;

      if (selectedFilter != 'All') {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'provider')
            .where('service_type', isEqualTo: selectedFilter)
            .where('has_location', isEqualTo: true)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'provider')
            .where('has_location', isEqualTo: true)
            .get();
      }

      List<Map<String, dynamic>> loadedProviders = [];
      Set<Marker> newMarkers = {};

      if (userLocation != null) {
        newMarkers.add(
          Marker(
            markerId: const MarkerId("user"),
            position: userLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: "Your Location"),
          ),
        );
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final isOnline = data['is_online'] ?? false;

        if (data['lat'] != null && data['lng'] != null && isOnline) {
          loadedProviders.add({
            'id': doc.id,
            'name': data['name'] ?? 'Provider',
            'service': data['service_type'] ?? 'General',
            'lat': data['lat'],
            'lng': data['lng'],
            'review_count': data['review_count'] ?? 0,
            'rating': data['rating']?.toString() ?? '4.5',
            'phone': data['phone'] ?? '',
          });

          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['lat'], data['lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: data['name'] ?? 'Provider',
                snippet: data['service_type'] ?? '',
              ),
              onTap: () => _showProviderDetails(data, doc.id),
            ),
          );
        }
      }

      setState(() {
        providers = loadedProviders;
        markers = newMarkers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
      _loading = true;
    });
    if (userLocation != null) {
      _loadProviders(userLocation!);
    }
  }

  void _showProviderDetails(Map<String, dynamic> provider, String providerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getServiceIcon(provider['service_type'] ?? ''),
                color: AppColors.kWhite,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider['name'] ?? 'Provider',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.kBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider['service_type'] ?? 'Service Provider',
              style: const TextStyle(fontSize: 14, color: AppColors.kGreyText),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: AppColors.kBlack, size: 20),
                const SizedBox(width: 4),
                Text(
                  provider['rating']?.toString() ?? '4.5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlack,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${provider['review_count'] ?? 0} reviews)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kGreyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider['phone'] != null &&
                provider['phone'].toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.kBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.kBlack,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phone,
                        size: 20,
                        color: AppColors.kWhite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Number',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kGreyText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            provider['phone'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(provider['phone']),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text(
                          'Call',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kBlack,
                          foregroundColor: AppColors.kWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kBlack,
                  side: const BorderSide(color: AppColors.kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) => serviceIcon(serviceType);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch phone dialer'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = userLocation ?? const LatLng(0, 0);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            compassEnabled: true,
            onMapCreated: (controller) {
              mapController = controller;
              if (userLocation != null && !_loading) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(userLocation!, 14),
                );
              }
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.kWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "NEARBY PROVIDERS",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kBlack,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: filters.map((filter) {
                              final isSelected = selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? AppColors.kWhite
                                          : AppColors.kBlack,
                                    ),
                                  ),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  selectedColor: AppColors.kBlack,
                                  backgroundColor: AppColors.kBackground,
                                  onSelected: (_) => _onFilterChanged(filter),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.kBlack,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: AppColors.kWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedFilter == 'All'
                              ? 'Nearby Providers'
                              : selectedFilter,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.kBlack,
                          ),
                        ),
                        Text(
                          '${providers.length} provider(s) found',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kGreyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.kBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      onPressed: _initLocation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            Container(
              color: AppColors.kBackground.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.kBlack),
              ),
            ),
        ],
      ),
    );
  }
}
