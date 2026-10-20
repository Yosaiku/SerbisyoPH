import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';
import 'package:serbisyo_ph/pages/active_orders/order_details_page.dart';

class ProviderOrderHistoryPage extends StatelessWidget {
  const ProviderOrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "COMPLETED JOBS",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text("Please sign in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('provider_id', isEqualTo: userId)
                  .where('status', isEqualTo: 'completed')
                  .orderBy('completed_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.kBlack),
                  );
                }

                final orders = snapshot.data?.docs ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.kBorder),
                        const SizedBox(height: 16),
                        const Text(
                          "No completed jobs",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Your completed jobs will appear here",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.kGreyText,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>?;
                    if (data == null) return const SizedBox();

                    return _ProviderHistoryCard(
                      serviceType: data['service_type'] ?? 'Service',
                      price: data['accepted_price']?.toString() ?? '-',
                      orderId: order.id,
                      completedAt: data['completed_at'],
                      pickupLocation: data['pickup_location'] ?? '',
                      deliveryLocation: data['delivery_location'] ?? '',
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                );
              },
            ),
    );
  }
}

class _ProviderHistoryCard extends StatelessWidget {
  final String serviceType;
  final String price;
  final String orderId;
  final Timestamp? completedAt;
  final String pickupLocation;
  final String deliveryLocation;

  const _ProviderHistoryCard({
    required this.serviceType,
    required this.price,
    required this.orderId,
    this.completedAt,
    required this.pickupLocation,
    required this.deliveryLocation,
  });

  IconData _getServiceIcon() => serviceIcon(serviceType);

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppColors.kBlack,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getServiceIcon(), color: AppColors.kWhite),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceType,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.kBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (completedAt != null)
                        Text(
                          _formatDate(completedAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.kGreyText,
                          ),
                        ),
                    ],
                  ),
                ),
                if (price != '-')
                  Text(
                    '₱$price',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trip_origin, size: 14, color: AppColors.kGreyText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pickupLocation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kGreyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.kGreyText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deliveryLocation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kGreyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }
}
