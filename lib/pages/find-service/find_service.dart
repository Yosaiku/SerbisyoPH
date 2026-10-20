import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:serbisyo_ph/pages/find-service/looking.dart';
import 'package:serbisyo_ph/pages/find-service/service_form.dart';
import 'package:serbisyo_ph/maps/map_picker.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class FindService extends StatefulWidget {
  final String selectedFilter;
  const FindService({super.key, required this.selectedFilter});

  @override
  State<FindService> createState() => _FindServiceState();
}

class _FindServiceState extends State<FindService> {
  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.selectedFilter;
  }

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController deliveryController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool sameAsPickup = false;
  int selectedBaskets = 1;
  int selectedGallons = 1;
  int selectedTank = 1;

  double? pickupLat;
  double? pickupLng;
  double? deliveryLat;
  double? deliveryLng;

  final List<Map<String, dynamic>> providers = [
    {"name": "QuickWash", "service": "Laundry", "rating": "4.8"},
    {"name": "AquaPure", "service": "Water Refill", "rating": "4.7"},
    {"name": "Juan Clean", "service": "LPG Refill", "rating": "4.9"},
  ];

  bool _locating = false;

  @override
  void dispose() {
    pickupController.dispose();
    deliveryController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void handleSameLocation(bool? val) {
    setState(() {
      sameAsPickup = val ?? false;

      if (sameAsPickup) {
        deliveryController.text = pickupController.text;
      } else {
        deliveryController.clear();
      }
    });
  }

  void handleQuantity(int? val) {
    setState(() {
      if (selectedFilter == "Laundry") {
        selectedBaskets = val!;
      } else if (selectedFilter == "Water Refill") {
        selectedGallons = val!;
      }
    });
  }

  void broadcastRequest() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to request a service"),
          backgroundColor: AppColors.kBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Map<String, dynamic> request = {
      "service_type": selectedFilter,
      "customer_id": userId,
      "status": "pending",
      "created_at": FieldValue.serverTimestamp(),
      "note": noteController.text,
    };

    if (selectedFilter == "Laundry") {
      request["pickup_location"] = pickupController.text;
      request["delivery_location"] = sameAsPickup
          ? pickupController.text
          : deliveryController.text;
      request["basket_count"] = selectedBaskets;
    }

    if (selectedFilter == "Water Refill") {
      request["pickup_location"] = pickupController.text;
      request["delivery_location"] = deliveryController.text;
      request["gallon_count"] = selectedGallons;
    }

    if (selectedFilter == "LPG Refill") {
      request["pickup_location"] = pickupController.text;
      request["delivery_location"] = sameAsPickup
          ? pickupController.text
          : deliveryController.text;
      request["tank_count"] = selectedTank;
    }

    request["pickup_lat"] = pickupLat;
    request["pickup_lng"] = pickupLng;
    request["delivery_lat"] = deliveryLat;
    request["delivery_lng"] = deliveryLng;

    final docRef = await FirebaseFirestore.instance
        .collection('orders')
        .add(request);
    final orderId = docRef.id;
    request["order_id"] = orderId;

    await _storeNotificationHistory(
      userId,
      'New Order Broadcasted',
      'Your $selectedFilter request has been sent to providers.',
      {'order_id': orderId},
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LookingForService(request: request),
        ),
      );
    }
  }

  Future<void> _storeNotificationHistory(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipient_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }

  void locateMe() async {
    setState(() => _locating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
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
          setState(() => _locating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        await Geolocator.openAppSettings();
        return;
      }

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
        _locating = false;
        pickupController.text = address;
        pickupLat = position.latitude;
        pickupLng = position.longitude;
        if (sameAsPickup) {
          deliveryController.text = address;
          deliveryLat = position.latitude;
          deliveryLng = position.longitude;
        }
      });
    } catch (e) {
      setState(() => _locating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> openMapPicker(bool isPickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          pickupController.text = result["address"];
          pickupLat = result["lat"];
          pickupLng = result["lng"];

          if (sameAsPickup) {
            deliveryController.text = result["address"];
            deliveryLat = result["lat"];
            deliveryLng = result["lng"];
          }
        } else {
          deliveryController.text = result["address"];
          deliveryLat = result["lat"];
          deliveryLng = result["lng"];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "FIND SERVICES",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: TextField(
                cursorColor: AppColors.kBlack,
                decoration: InputDecoration(
                  hintText: "Search Nearby Services...",
                  hintStyle: const TextStyle(
                    color: AppColors.kGreyText,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.kBlack),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          /// FILTER CHIPS
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                filterChip("All"),
                filterChip("Laundry"),
                filterChip("Water Refill"),
                filterChip("LPG Refill"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                /// TOP SUGGESTED PROVIDERS
                ...providers
                    .where(
                      (p) =>
                          selectedFilter == "All" ||
                          p["service"].contains(selectedFilter),
                    )
                    .take(5)
                    .map((provider) => providerCard(provider)),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "REQUEST A SERVICE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kBlack.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// DYNAMIC LAUNDRY FORM
                if (selectedFilter == "Laundry")
                  ServiceForm(
                    pickupController: pickupController,
                    deliveryController: deliveryController,
                    sameAsPickup: sameAsPickup,
                    selectedQuantity: selectedBaskets,
                    quantityLabel: "Basket (8kgs)",
                    locateMe: locateMe,
                    onSameLocationChanged: handleSameLocation,
                    onQuantityChanged: handleQuantity,
                    noteController: noteController,
                    openPickupMap: () => openMapPicker(true),
                    openDeliveryMap: () => openMapPicker(false),
                    isLocating: _locating,
                  ),

                if (selectedFilter == "Water Refill")
                  ServiceForm(
                    pickupController: pickupController,
                    deliveryController: deliveryController,
                    sameAsPickup: sameAsPickup,
                    selectedQuantity: selectedGallons,
                    quantityLabel: "Gallon",
                    locateMe: locateMe,
                    onSameLocationChanged: handleSameLocation,
                    onQuantityChanged: handleQuantity,
                    noteController: noteController,
                    openPickupMap: () => openMapPicker(true),
                    openDeliveryMap: () => openMapPicker(false),
                    isLocating: _locating,
                  ),

                if (selectedFilter == "LPG Refill")
                  ServiceForm(
                    pickupController: pickupController,
                    deliveryController: deliveryController,
                    sameAsPickup: sameAsPickup,
                    selectedQuantity: selectedTank,
                    quantityLabel: "Tank (11kgs)",
                    locateMe: locateMe,
                    onSameLocationChanged: handleSameLocation,
                    onQuantityChanged: handleQuantity,
                    noteController: noteController,
                    openPickupMap: () => openMapPicker(true),
                    openDeliveryMap: () => openMapPicker(false),
                    isLocating: _locating,
                  ),

                const SizedBox(height: 24),

                if (selectedFilter != "All")
                  /// BROADCAST BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.radar, color: AppColors.kWhite),
                        label: const Text(
                          "Broadcast Request",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kWhite,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kBlack, // Black Button
                          foregroundColor: AppColors.kWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: broadcastRequest,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FILTER CHIP WIDGET
  Widget filterChip(String label) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.kWhite : AppColors.kBlack,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: AppColors.kBlack,
        backgroundColor: AppColors.kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.kBlack : AppColors.kBorder,
          ),
        ),
        onSelected: (_) {
          setState(() {
            selectedFilter = label;
          });
        },
      ),
    );
  }

  /// PROVIDER CARD WIDGET
  Widget providerCard(Map provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kBorder, width: 0.5),
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.kBlack,
            size: 20,
          ),
        ),
        title: Text(
          provider["name"],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.kBlack,
          ),
        ),
        subtitle: Text(
          provider["service"],
          style: const TextStyle(color: AppColors.kGreyText, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: AppColors.kBlack, size: 16),
            const SizedBox(width: 4),
            Text(
              provider["rating"],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.kBlack,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to provider detail page
        },
      ),
    );
  }
}
