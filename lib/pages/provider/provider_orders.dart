import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';
import 'package:serbisyo_ph/pages/provider/provider_order_history_page.dart';
import 'package:serbisyo_ph/pages/chat/chat_page.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class ProviderOrders extends StatefulWidget {
  const ProviderOrders({super.key});

  @override
  State<ProviderOrders> createState() => _ProviderOrdersState();
}

class _ProviderOrdersState extends State<ProviderOrders>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              "Sign in to view your orders",
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

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "MY ORDERS",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.kBlack,
          unselectedLabelColor: AppColors.kGreyText,
          indicatorColor: AppColors.kBlack,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: "ACTIVE"),
            Tab(text: "HISTORY"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProviderActiveOrders(userId: userId),
          const ProviderOrderHistoryPage(),
        ],
      ),
    );
  }
}

class _ProviderActiveOrders extends StatelessWidget {
  final String userId;

  const _ProviderActiveOrders({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('provider_id', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'in_progress'])
          .orderBy('created_at', descending: true)
          .snapshots(),
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
                Icon(Icons.error_outline, size: 48, color: AppColors.kBorder),
                const SizedBox(height: 12),
                const Text(
                  "Unable to load orders",
                  style: TextStyle(fontSize: 14, color: AppColors.kGreyText),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.kBorder),
                const SizedBox(height: 16),
                const Text(
                  "No accepted orders",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Accepted orders will appear here",
                  style: TextStyle(fontSize: 13, color: AppColors.kGreyText),
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
            final orderData = order.data() as Map<String, dynamic>?;
            if (orderData == null) return const SizedBox();
            return ProviderOrderCard(
              orderId: order.id,
              serviceType: orderData['service_type'] ?? 'Unknown',
              status: orderData['status'] ?? 'accepted',
              createdAt: orderData['created_at'] != null
                  ? _formatTimestamp(orderData['created_at'])
                  : '',
              customerId: orderData['customer_id'] ?? '',
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

class ProviderOrderCard extends StatefulWidget {
  final String orderId;
  final String serviceType;
  final String status;
  final String createdAt;
  final String customerId;

  const ProviderOrderCard({
    super.key,
    required this.orderId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    required this.customerId,
  });

  @override
  State<ProviderOrderCard> createState() => _ProviderOrderCardState();
}

class _ProviderOrderCardState extends State<ProviderOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.3,
      upperBound: 1.0,
    );

    if (widget.status == 'in_progress') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProviderOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'in_progress') {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getServiceIcon() => serviceIcon(widget.serviceType);

  String _getStatusText() {
    switch (widget.status) {
      case 'accepted':
        return 'Accepted - preparing';
      case 'in_progress':
        return 'Service in progress';
      case 'completed':
        return 'Completed';
      default:
        return widget.status;
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return AppColors.kGreyText;
    }
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      final customerId = orderDoc.data()?['customer_id'];
      final serviceType = orderDoc.data()?['service_type'] ?? 'Service';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'status': newStatus,
            if (newStatus == 'in_progress')
              'in_progress_at': FieldValue.serverTimestamp(),
            if (newStatus == 'completed')
              'completed_at': FieldValue.serverTimestamp(),
          });

      if (customerId != null) {
        String title;
        String body;
        if (newStatus == 'in_progress') {
          title = 'Service Started';
          body = 'Your $serviceType is now in progress';
        } else if (newStatus == 'completed') {
          title = 'Order Completed';
          body = 'Your $serviceType has been completed';
        } else {
          title = 'Order Status Updated';
          body = 'Your order status changed to $newStatus';
        }

        await FirebaseFirestore.instance.collection('notifications').add({
          'recipient_id': customerId,
          'title': title,
          'body': body,
          'data': {'order_id': widget.orderId},
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'completed' ? 'Order completed!' : 'Status updated',
            ),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              widget.serviceType,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.kBlack,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _controller,
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.createdAt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kGreyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.status != 'completed')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (widget.status == 'accepted')
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(context, 'in_progress'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: AppColors.kWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Start Job",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      if (widget.status == 'in_progress') ...[
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _updateStatus(context, 'accepted'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.kBlack,
                                side: const BorderSide(
                                  color: AppColors.kBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Back",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateStatus(context, 'completed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: AppColors.kWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Complete",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              orderId: widget.orderId,
                              otherUserId: widget.customerId,
                              otherUserName: 'Customer',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text("Message Customer"),
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
              ),
            ),
        ],
      ),
    );
  }
}
