import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class IncomingOrders extends StatefulWidget {
  const IncomingOrders({super.key});

  @override
  State<IncomingOrders> createState() => _IncomingOrdersState();
}

class _IncomingOrdersState extends State<IncomingOrders> {
  @override
  void initState() {
    super.initState();
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.kBorder,
            ),
            SizedBox(height: 16),
            Text(
              "Sign in to view incoming orders",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.kBlack,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.kBlack),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  size: 64,
                  color: AppColors.kGreyText,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Unable to load orders",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kGreyText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];
        orders.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderData = order.data() as Map<String, dynamic>?;
            if (orderData == null) return const SizedBox();

            return IncomingOrderCard(
              orderId: order.id,
              customerId: orderData['customer_id'] ?? '',
              serviceType: orderData['service_type'] ?? 'Unknown',
              pickupLocation: orderData['pickup_location'] ?? '',
              deliveryLocation: orderData['delivery_location'] ?? '',
              note: orderData['note'] ?? '',
              basketCount: orderData['basket_count']?.toString() ?? '',
              gallonCount: orderData['gallon_count']?.toString() ?? '',
              tankCount: orderData['tank_count']?.toString() ?? '',
              createdAt: orderData['created_at'] != null
                  ? _formatTimestamp(orderData['created_at'])
                  : '',
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class IncomingOrderCard extends StatelessWidget {
  final String orderId;
  final String serviceType;
  final String pickupLocation;
  final String deliveryLocation;
  final String note;
  final String basketCount;
  final String gallonCount;
  final String tankCount;
  final String createdAt;
  final String customerId;

  const IncomingOrderCard({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.serviceType,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.note,
    required this.basketCount,
    required this.gallonCount,
    required this.tankCount,
    required this.createdAt,
  });

  IconData _getServiceIcon() => serviceIcon(serviceType);

  String _getQuantityLabel() {
    if (basketCount.isNotEmpty) return '$basketCount basket(s)';
    if (gallonCount.isNotEmpty) return '$gallonCount gallon(s)';
    if (tankCount.isNotEmpty) return '$tankCount tank(s)';
    return '';
  }

  void _showOfferDialog(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in to make an offer"),
          backgroundColor: AppColors.kBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final priceController = TextEditingController();
    final termsController = TextEditingController();
    bool isImmediate = true;
    int? scheduleHours;

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
                "MAKE AN OFFER",
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
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.kBlack,
                  decoration: const InputDecoration(
                    labelText: "Price (₱)",
                    hintText: "Enter your price",
                    labelStyle: TextStyle(color: AppColors.kGreyText),
                    hintStyle: TextStyle(color: AppColors.kGreyText),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: AppColors.kBlack,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Schedule",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() {
                        isImmediate = true;
                        scheduleHours = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isImmediate
                              ? AppColors.kBlack
                              : AppColors.kBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isImmediate
                                ? AppColors.kBlack
                                : AppColors.kBorder,
                          ),
                        ),
                        child: Text(
                          "Immediate",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isImmediate
                                ? AppColors.kWhite
                                : AppColors.kBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() {
                        isImmediate = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !isImmediate
                              ? AppColors.kBlack
                              : AppColors.kBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isImmediate
                                ? AppColors.kBlack
                                : AppColors.kBorder,
                          ),
                        ),
                        child: Text(
                          "Scheduled",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !isImmediate
                                ? AppColors.kWhite
                                : AppColors.kBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isImmediate) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.kWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: DropdownButtonFormField<int>(
                    initialValue: scheduleHours,
                    decoration: const InputDecoration(
                      labelText: "Hours from now",
                      labelStyle: TextStyle(color: AppColors.kGreyText),
                      border: InputBorder.none,
                    ),
                    items: [1, 2, 3, 4, 6, 12, 24].map((h) {
                      return DropdownMenuItem(
                        value: h,
                        child: Text("$h hour(s)"),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => scheduleHours = val),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  controller: termsController,
                  maxLines: 2,
                  cursorColor: AppColors.kBlack,
                  decoration: const InputDecoration(
                    labelText: "Terms / Notes",
                    hintText: "Any special conditions",
                    labelStyle: TextStyle(color: AppColors.kGreyText),
                    hintStyle: TextStyle(color: AppColors.kGreyText),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.note_outlined, color: AppColors.kBlack),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
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
                    final price = priceController.text.trim();
                    if (price.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a price")),
                      );
                      return;
                    }

                    try {
                      final providerDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get();
                      final providerName =
                          providerDoc.data()?['name'] ?? 'Provider';

                      final orderDoc = await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(orderId)
                          .get();
                      final customerId = orderDoc.data()?['customer_id'];
                      final serviceType =
                          orderDoc.data()?['service_type'] ?? 'Service';

                      final offerRef = await FirebaseFirestore.instance
                          .collection('offers')
                          .add({
                            'order_id': orderId,
                            'provider_id': userId,
                            'provider_name': providerName,
                            'price': double.parse(price),
                            'is_immediate': isImmediate,
                            'schedule_hours': scheduleHours,
                            'terms': termsController.text.trim(),
                            'status': 'pending',
                            'created_at': FieldValue.serverTimestamp(),
                          });

                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(orderId)
                          .update({'has_offers': true});

                      if (customerId != null) {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .add({
                              'recipient_id': customerId,
                              'title': 'New Offer Received',
                              'body':
                                  '$providerName offered ₱$price for $serviceType',
                              'data': {
                                'order_id': orderId,
                                'offer_id': offerRef.id,
                              },
                              'read': false,
                              'created_at': FieldValue.serverTimestamp(),
                            });
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Offer submitted!"),
                            backgroundColor: AppColors.kBlack,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Submit Offer",
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getServiceIcon(), color: AppColors.kWhite),
            ),
            title: Text(
              serviceType,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.kBlack,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  createdAt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kGreyText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationRow(Icons.trip_origin, 'Pickup:', pickupLocation),
                const SizedBox(height: 6),
                _buildLocationRow(
                  Icons.location_on,
                  'Delivery:',
                  deliveryLocation,
                ),
                if (_getQuantityLabel().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildLocationRow(
                    Icons.inventory_2_outlined,
                    'Quantity:',
                    _getQuantityLabel(),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildLocationRow(Icons.note_outlined, 'Note:', note),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _showOfferDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.kBlack,
                        side: const BorderSide(color: AppColors.kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Make Offer",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.kGreyText),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.kGreyText,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.kBlack),
          ),
        ),
      ],
    );
  }
}
