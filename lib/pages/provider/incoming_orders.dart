import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/design_system.dart';
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
      return DSEmptyState(
        icon: Icons.receipt_long_outlined,
        title: "Sign in to view incoming orders",
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
          return DSEmptyState(
            icon: Icons.wifi_off_outlined,
            title: "Unable to load orders",
            subtitle: snapshot.error.toString(),
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

        if (orders.isEmpty) {
          return DSEmptyState(
            icon: Icons.inbox_outlined,
            title: "No incoming orders",
            subtitle: "New orders will appear here",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DS.spaceLg),
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
          separatorBuilder: (context, index) => const SizedBox(height: DS.spaceMd),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusXl)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DSModalBottomSheet(
          title: "MAKE AN OFFER",
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DS.spaceXl),
                DSInput(
                  controller: priceController,
                  label: "Price (₱)",
                  hint: "Enter your price",
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: DS.spaceLg),
                DSText.labelMedium("Schedule"),
                const SizedBox(height: DS.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          isImmediate = true;
                          scheduleHours = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(DS.spaceMd),
                          decoration: BoxDecoration(
                            color: isImmediate
                                ? AppColors.kBlack
                                : AppColors.kBackground,
                            borderRadius: BorderRadius.circular(DS.radiusMd),
                            border: Border.all(
                              color: isImmediate
                                  ? AppColors.kBlack
                                  : AppColors.kBorder,
                            ),
                          ),
                          child: Center(
                            child: DSText.labelMedium(
                              "Immediate",
                              color: isImmediate ? AppColors.kWhite : AppColors.kBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DS.spaceMd),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          isImmediate = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(DS.spaceMd),
                          decoration: BoxDecoration(
                            color: !isImmediate
                                ? AppColors.kBlack
                                : AppColors.kBackground,
                            borderRadius: BorderRadius.circular(DS.radiusMd),
                            border: Border.all(
                              color: !isImmediate
                                  ? AppColors.kBlack
                                  : AppColors.kBorder,
                            ),
                          ),
                          child: Center(
                            child: DSText.labelMedium(
                              "Scheduled",
                              color: !isImmediate ? AppColors.kWhite : AppColors.kBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isImmediate) ...[
                  const SizedBox(height: DS.spaceMd),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
                    decoration: BoxDecoration(
                      color: AppColors.kWhite,
                      borderRadius: BorderRadius.circular(DS.radiusMd),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: DropdownButtonFormField<int>(
                      initialValue: scheduleHours,
                      decoration: const InputDecoration(
                        labelText: "Hours from now",
                        labelStyle: DS.bodySmall,
                        border: InputBorder.none,
                      ),
                      items: [1, 2, 3, 4, 6, 12, 24].map((h) {
                        return DropdownMenuItem(
                          value: h,
                          child: DSText.bodyMedium("$h hour(s)"),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setModalState(() => scheduleHours = val),
                    ),
                  ),
                ],
                const SizedBox(height: DS.spaceLg),
                DSInput(
                  controller: termsController,
                  label: "Terms / Notes",
                  hint: "Any special conditions",
                  prefixIcon: Icons.note_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: DS.spaceXl),
                DSButton.primary(
                  label: "Submit Offer",
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
                ),
                const SizedBox(height: DS.spaceXl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DSCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DS.spaceMd),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppColors.kBlack,
                    borderRadius: BorderRadius.circular(DS.radiusMd),
                  ),
                  child: Icon(_getServiceIcon(), color: AppColors.kWhite, size: DS.iconMd),
                ),
                const SizedBox(width: DS.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DSText.titleMedium(serviceType),
                      const SizedBox(height: DS.spaceXs),
                      DSText.caption(createdAt),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSLocationRow(
                  icon: Icons.trip_origin,
                  label: 'Pickup:',
                  value: pickupLocation,
                ),
                const SizedBox(height: DS.spaceSm),
                DSLocationRow(
                  icon: Icons.location_on,
                  label: 'Delivery:',
                  value: deliveryLocation,
                ),
                if (_getQuantityLabel().isNotEmpty) ...[
                  const SizedBox(height: DS.spaceSm),
                  DSLocationRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Quantity:',
                    value: _getQuantityLabel(),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: DS.spaceSm),
                  DSLocationRow(
                    icon: Icons.note_outlined,
                    label: 'Note:',
                    value: note,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DS.spaceMd),
            child: DSButton.secondary(
              label: "Make Offer",
              onPressed: () => _showOfferDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}