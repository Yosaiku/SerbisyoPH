import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:serbisyo_ph/pages/auth/login_page.dart';
import 'package:serbisyo_ph/maps/map_picker.dart';
import 'package:serbisyo_ph/theme/colors.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.kBlack,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: AppColors.kWhite,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Provider Profile",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlack,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Account Information"),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: "Business Name",
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: "Phone Number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              label: "Description (optional)",
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Service Type"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedService,
                  isExpanded: true,
                  items: _services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service),
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
            const SizedBox(height: 24),
            _buildSectionTitle("Availability"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isOnline ? Icons.check_circle : Icons.pause_circle,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? "Online" : "Offline",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          _isOnline
                              ? "You're visible to customers"
                              : "You're hidden from customers",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kGreyText,
                          ),
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
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? "You're now online!"
                                    : "You're now offline",
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
            const SizedBox(height: 24),
            _buildSectionTitle("Location"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kBorder),
              ),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _hasLocation
                              ? Icons.check_circle
                              : Icons.location_off,
                          color: _hasLocation ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasLocation ? "Location Set" : "No Location Set",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _hasLocation
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            if (_currentAddress.isNotEmpty)
                              Text(
                                _currentAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.kGreyText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text("Use Current"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.kBlack,
                            side: const BorderSide(color: AppColors.kBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updateLocation,
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text("Pick on Map"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kBlack,
                            foregroundColor: AppColors.kWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kBlack,
                  foregroundColor: AppColors.kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.kWhite,
                        ),
                      )
                    : const Text(
                        "Save Profile",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Business Hours"),
            const SizedBox(height: 12),
            _buildBusinessHoursSection(),
            const SizedBox(height: 24),
            _buildSectionTitle("My Promotions"),
            const SizedBox(height: 12),
            _buildPromotionsSection(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: AppColors.kBlack),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.kGreyText),
          prefixIcon: Icon(icon, size: 18, color: AppColors.kGreyText),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: _businessHours.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kBlack,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTimePickerDialog(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.kGreyText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            size: 14,
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
      builder: (context) => AlertDialog(
        title: Text("$day Hours"),
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
                    title: const Text("Open"),
                    leading: const Radio<bool>(value: false),
                  ),
                  ListTile(
                    title: const Text("Closed"),
                    leading: const Radio<bool>(value: true),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const Center(
                  child: Text(
                    "No promotions yet",
                    style: TextStyle(color: AppColors.kGreyText),
                  ),
                ),
              )
            else
              ...promotions.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildPromotionCard(data, doc.id);
              }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _showAddPromotionDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Promotion"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kBlack,
                  side: const BorderSide(color: AppColors.kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_offer, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
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
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kGreyText,
                    ),
                  ),
                if (discount.isNotEmpty)
                  Text(
                    discount,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ADD PROMOTION",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    hintText: "e.g., Summer Sale",
                    prefixIcon: Icon(Icons.local_offer_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  controller: discountController,
                  decoration: const InputDecoration(
                    labelText: "Discount",
                    hintText: "e.g., 20% OFF",
                    prefixIcon: Icon(Icons.percent),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Description (optional)",
                    hintText: "e.g., Valid for laundry services",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.description_outlined),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Add Promotion",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
