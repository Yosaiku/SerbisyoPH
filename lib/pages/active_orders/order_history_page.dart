import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';
import 'package:serbisyo_ph/pages/active_orders/order_details_page.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

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
          "ORDER HISTORY",
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
                  .where('customer_id', isEqualTo: userId)
                  .where('status', isEqualTo: 'completed')
                  .orderBy('completed_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.kBlack),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Unable to load order history",
                      style: TextStyle(color: AppColors.kGreyText),
                    ),
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
                          "No order history",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Completed orders will appear here",
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

                    return _HistoryCard(
                      serviceType: data['service_type'] ?? 'Service',
                      status: data['status'] ?? 'completed',
                      price: data['accepted_price']?.toString() ?? '-',
                      orderId: order.id,
                      completedAt: data['completed_at'],
                      providerId: data['provider_id'],
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

class _HistoryCard extends StatelessWidget {
  final String serviceType;
  final String status;
  final String price;
  final String orderId;
  final Timestamp? completedAt;
  final String? providerId;

  const _HistoryCard({
    required this.serviceType,
    required this.status,
    required this.price,
    required this.orderId,
    this.completedAt,
    this.providerId,
  });

  IconData _getServiceIcon() => serviceIcon(serviceType);

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showRatingDialog(BuildContext context) {
    if (providerId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RatingDialog(
        orderId: orderId,
        providerId: providerId!,
        serviceType: serviceType,
      ),
    );
  }

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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Completed",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (completedAt != null)
                            Text(
                              _formatDate(completedAt!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.kGreyText,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (price != '-')
                  Text(
                    '₱$price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.kBlack,
                    ),
                  ),
              ],
            ),
            if (providerId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingDialog(context),
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text("Rate Provider"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kBlack,
                    side: const BorderSide(color: AppColors.kBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final String orderId;
  final String providerId;
  final String serviceType;

  const _RatingDialog({
    required this.orderId,
    required this.providerId,
    required this.serviceType,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
          const Text(
            "RATE YOUR EXPERIENCE",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_outline,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Write a review (optional)",
                hintStyle: TextStyle(color: AppColors.kGreyText),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _rating > 0
                  ? () async {
                      await FirebaseFirestore.instance
                          .collection('reviews')
                          .add({
                            'order_id': widget.orderId,
                            'provider_id': widget.providerId,
                            'customer_id':
                                FirebaseAuth.instance.currentUser?.uid,
                            'rating': _rating,
                            'review': _reviewController.text.trim(),
                            'service_type': widget.serviceType,
                            'created_at': FieldValue.serverTimestamp(),
                          });

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.providerId)
                          .collection('ratings')
                          .add({
                            'rating': _rating,
                            'created_at': FieldValue.serverTimestamp(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thanks for your review!"),
                            backgroundColor: AppColors.kBlack,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Submit Review",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
