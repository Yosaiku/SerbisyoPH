import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:serbisyo_ph/maps/map_picker.dart';
import 'package:serbisyo_ph/theme/design_system.dart';
import 'package:serbisyo_ph/navbars/provider_navigation_bar.dart';

class ProviderSetupPage extends StatefulWidget {
  const ProviderSetupPage({super.key});

  @override
  State<ProviderSetupPage> createState() => _ProviderSetupPageState();
}

class _ProviderSetupPageState extends State<ProviderSetupPage> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedService = 'Laundry';
  String _currentAddress = '';
  double? _currentLat;
  double? _currentLng;
  bool _hasLocation = false;
  bool _saving = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Business name is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'service_type': _selectedService,
        'address': _currentAddress,
        'lat': _currentLat,
        'lng': _currentLng,
        'has_location': _hasLocation,
        'is_online': true,
        'has_completed_setup': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Setup complete! Welcome to Serbisyo PH."),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ProviderNavigationBar(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: "),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _saving = false);
  }

  Future<void> _updateLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        _currentAddress = result['address'];
        _currentLat = result['lat'];
        _currentLng = result['lng'];
        _hasLocation = true;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enable location services"),
              backgroundColor: AppColors.kBlack,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      setState(() => _saving = true);

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      String address = "\, \";

      setState(() {
        _currentAddress = address;
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _hasLocation = true;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location updated!"),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: \"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: DSAppBar(
        title: "PROVIDER SETUP",
        dark: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DS.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: DS.avatarLg,
                    width: DS.avatarLg,
                    decoration: BoxDecoration(
                      color: AppColors.kBlack,
                      borderRadius: BorderRadius.circular(DS.radiusLg),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: AppColors.kWhite,
                      size: DS.iconXl,
                    ),
                  ),
                  const SizedBox(height: DS.spaceMd),
                  DSText.headlineMedium("Welcome!", color: AppColors.kBlack),
                  const SizedBox(height: DS.spaceXs),
                  DSText.bodySmall(
                    "Let's set up your business profile",
                    color: AppColors.kGreyText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "Business Information"),
            const SizedBox(height: DS.spaceMd),
            DSInput(
              controller: _businessNameController,
              label: "Business Name",
              prefixIcon: Icons.storefront_outlined,
            ),
            const SizedBox(height: DS.spaceMd),
            DSInput(
              controller: _phoneController,
              label: "Phone Number",
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: DS.spaceMd),
            DSInput(
              controller: _descriptionController,
              label: "Description (optional)",
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "Service Type"),
            const SizedBox(height: DS.spaceMd),
            DSSegmentedControl<String>(
              value: _selectedService,
              options: {
                'Laundry': 'Laundry',
                'Water Refill': 'Water Refill',
                'LPG Refill': 'LPG Refill',
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedService = value);
                }
              },
            ),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "Location"),
            const SizedBox(height: DS.spaceMd),
            DSCard(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: _hasLocation
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DS.radiusMd),
                        ),
                        child: Icon(
                          _hasLocation
                              ? Icons.check_circle
                              : Icons.location_off,
                          color: _hasLocation ? Colors.green : Colors.orange,
                          size: DS.iconMd,
                        ),
                      ),
                      const SizedBox(width: DS.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DSText.titleMedium(
                              _hasLocation ? "Location Set" : "No Location Set",
                              color: _hasLocation ? Colors.green : Colors.orange,
                            ),
                            if (_currentAddress.isNotEmpty)
                              DSText.bodySmall(
                                _currentAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DS.spaceLg),
                  Row(
                    children: [
                      Expanded(
                        child: DSButton.secondary(
                          label: "Use Current",
                          icon: Icons.my_location,
                          onPressed: _useCurrentLocation,
                        ),
                      ),
                      const SizedBox(width: DS.spaceMd),
                      Expanded(
                        child: DSButton.primary(
                          label: "Pick on Map",
                          icon: Icons.map,
                          onPressed: _updateLocation,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DS.spaceXl),
            DSButton.primary(
              label: "Complete Setup",
              onPressed: _saving ? null : _saveProfile,
              loading: _saving,
            ),
            const SizedBox(height: DS.space2xl),
          ],
        ),
      ),
    );
  }
}
