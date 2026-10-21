import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:serbisyo_ph/pages/auth/login_page.dart';
import 'package:serbisyo_ph/maps/map_picker.dart';
import 'package:serbisyo_ph/theme/design_system.dart';

class ProviderSettingsPage extends StatefulWidget {
  const ProviderSettingsPage({super.key});

  @override
  State<ProviderSettingsPage> createState() => _ProviderSettingsPageState();
}

class _ProviderSettingsPageState extends State<ProviderSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedService = 'Laundry';
  String _currentAddress = '';
  double? _currentLat;
  double? _currentLng;
  bool _hasLocation = false;
  bool _isOnline = false;
  bool _loading = true;
  bool _saving = false;

  Map<String, String> _businessHours = {
    'Monday': '8:00 AM - 6:00 PM',
    'Tuesday': '8:00 AM - 6:00 PM',
    'Wednesday': '8:00 AM - 6:00 PM',
    'Thursday': '8:00 AM - 6:00 PM',
    'Friday': '8:00 AM - 6:00 PM',
    'Saturday': '8:00 AM - 6:00 PM',
    'Sunday': 'Closed',
  };

  final List<String> _services = ['Laundry', 'Water Refill', 'LPG Refill'];

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _selectedService = data['service_type'] ?? 'Laundry';
          _currentAddress = data['address'] ?? '';
          _currentLat = data['lat'];
          _currentLng = data['lng'];
          _hasLocation = data['has_location'] ?? false;
          _isOnline = data['is_online'] ?? false;
          if (data['business_hours'] != null) {
            _businessHours = Map<String, String>.from(data['business_hours']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'service_type': _selectedService,
        'address': _currentAddress,
        'lat': _currentLat,
        'lng': _currentLng,
        'has_location': _hasLocation,
        'is_online': _isOnline,
        'business_hours': _businessHours,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated!"),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
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
      String address = "${place.street}, ${place.locality}";

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
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.kBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.kBlack)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: DSAppBar(title: "Settings"),
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
                  DSText.labelMedium("Provider Profile", color: AppColors.kBlack),
                ],
              ),
            ),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "Account Information"),
            const SizedBox(height: DS.spaceMd),
            DSInput(
              controller: _nameController,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(DS.radiusMd),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedService,
                  isExpanded: true,
                  items: _services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: DSText.bodyMedium(service),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedService = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "Availability"),
            const SizedBox(height: DS.spaceMd),
            DSCard(
              padding: const EdgeInsets.all(DS.spaceLg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(DS.spaceSm),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DS.radiusMd),
                    ),
                    child: Icon(
                      _isOnline ? Icons.check_circle : Icons.pause_circle,
                      color: _isOnline ? Colors.green : Colors.red,
                      size: DS.iconMd,
                    ),
                  ),
                  const SizedBox(width: DS.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DSText.titleMedium(
                          _isOnline ? "Online" : "Offline",
                          color: _isOnline ? Colors.green : Colors.red,
                        ),
                        DSText.bodySmall(
                          _isOnline
                              ? "You're visible to customers"
                              : "You're hidden from customers",
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) async {
                      setState(() => _isOnline = value);
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({'is_online': value});
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? "You're now online!" : "You're now offline",
                              ),
                              backgroundColor: AppColors.kBlack,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    activeThumbColor: AppColors.kBlack,
                  ),
                ],
              ),
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
              label: "Save Profile",
              onPressed: _saving ? null : _saveProfile,
              loading: _saving,
            ),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "Business Hours"),
            const SizedBox(height: DS.spaceMd),
            _buildBusinessHoursSection(),
            const SizedBox(height: DS.spaceXl),
            DSSectionHeader(title: "My Promotions"),
            const SizedBox(height: DS.spaceMd),
            _buildPromotionsSection(),
            const SizedBox(height: DS.spaceLg),
            DSButton.outlinedDestructive(
              label: "Logout",
              onPressed: _logout,
            ),
            const SizedBox(height: DS.space2xl),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    return DSCard(
      padding: const EdgeInsets.all(DS.spaceMd),
      child: Column(
        children: _businessHours.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DS.spaceXs),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: DSText.labelSmall(entry.key),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTimePickerDialog(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DS.spaceMd,
                        vertical: DS.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kBackground,
                        borderRadius: BorderRadius.circular(DS.radiusSm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: DSText.bodySmall(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.edit,
                            size: DS.iconSm,
                            color: AppColors.kGreyText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTimePickerDialog(String day) {
    final isClosed = _businessHours[day] == 'Closed';

    showDialog(
      context: context,
      builder: (context) => DSDialog(
        title: "$day Hours",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<bool>(
              groupValue: isClosed,
              onChanged: (value) {
                setState(() {
                  _businessHours[day] =
                      value == true ? 'Closed' : '8:00 AM - 6:00 PM';
                });
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  ListTile(
                    title: const DSText.bodyMedium("Open"),
                    leading: const Radio<bool>(value: false),
                  ),
                  ListTile(
                    title: const DSText.bodyMedium("Closed"),
                    leading: const Radio<bool>(value: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [],
      ),
    );
  }

  Widget _buildPromotionsSection() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promotions')
          .where('provider_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final promotions = snapshot.data?.docs ?? [];

        return Column(
          children: [
            if (promotions.isEmpty)
              DSCard(
                padding: const EdgeInsets.all(DS.spaceLg),
                child: Center(child: DSText.bodySmall("No promotions yet")),
              )
            else
              ...promotions.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildPromotionCard(data, doc.id);
              }),
            const SizedBox(height: DS.spaceMd),
            DSButton.secondary(
              label: "Add Promotion",
              icon: Icons.add,
              onPressed: () => _showAddPromotionDialog(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final discount = data['discount'] ?? '';
    final isActive = data['is_active'] ?? true;

    return DSCard(
      padding: const EdgeInsets.all(DS.spaceMd),
      margin: const EdgeInsets.only(bottom: DS.spaceMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DS.spaceSm),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DS.radiusMd),
            ),
            child: const Icon(Icons.local_offer, color: Colors.green, size: DS.iconMd),
          ),
          const SizedBox(width: DS.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText.titleMedium(title),
                if (description.isNotEmpty)
                  DSText.bodySmall(description),
                if (discount.isNotEmpty)
                  DSText.labelSmall(discount, color: Colors.green),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) async {
              await FirebaseFirestore.instance
                  .collection('promotions')
                  .doc(docId)
                  .update({'is_active': value});
            },
            activeThumbColor: AppColors.kBlack,
          ),
        ],
      ),
    );
  }

  void _showAddPromotionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final discountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusXl)),
      ),
      builder: (context) => DSModalBottomSheet(
        title: "ADD PROMOTION",
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DS.spaceXl),
              DSInput(
                controller: titleController,
                label: "Title",
                hint: "e.g., Summer Sale",
                prefixIcon: Icons.local_offer_outlined,
              ),
              const SizedBox(height: DS.spaceMd),
              DSInput(
                controller: discountController,
                label: "Discount",
                hint: "e.g., 20% OFF",
                prefixIcon: Icons.percent,
              ),
              const SizedBox(height: DS.spaceMd),
              DSInput(
                controller: descController,
                label: "Description (optional)",
                hint: "e.g., Valid for laundry services",
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: DS.spaceXl),
              DSButton.primary(
                label: "Add Promotion",
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a title")),
                    );
                    return;
                  }

                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId == null) return;

                  final providerDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();
                  final providerName =
                      providerDoc.data()?['name'] ?? 'Provider';

                  await FirebaseFirestore.instance
                      .collection('promotions')
                      .add({
                    'provider_id': userId,
                    'provider_name': providerName,
                    'title': titleController.text.trim(),
                    'discount': discountController.text.trim(),
                    'description': descController.text.trim(),
                    'is_active': true,
                    'created_at': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Promotion added!"),
                        backgroundColor: AppColors.kBlack,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: DS.spaceXl),
            ],
          ),
        ),
      ),
    );
  }
}