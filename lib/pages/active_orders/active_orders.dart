import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/design_system.dart';
import 'package:serbisyo_ph/pages/active_orders/order_details_page.dart';
import 'package:serbisyo_ph/pages/active_orders/order_history_page.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class ActiveOrders extends StatefulWidget {
  const ActiveOrders({super.key});

  @override
  State<ActiveOrders> createState() => _ActiveOrdersState();
}

class _ActiveOrdersState extends State<ActiveOrders>
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
      return DSEmptyState(
        icon: Icons.receipt_long_outlined,
        title: "Sign in to view your orders",
      );
    }

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: DSAppBar(
        title: "MY ORDERS",
        centerTitle: true,
        actions: [],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.kBlack,
            unselectedLabelColor: AppColors.kGreyText,
            indicatorColor: AppColors.kBlack,
            labelStyle: DS.labelMedium,
            tabs: const [
              Tab(text: "ACTIVE"),
              Tab(text: "HISTORY"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActiveOrdersList(userId: userId),
                const OrderHistoryPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrdersList extends StatelessWidget {
  final String userId;

  const _ActiveOrdersList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customer_id', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.kBlack),
          );
        }

        if (snapshot.hasError) {
          return DSEmptyState(
            icon: Icons.error_outline,
            title: "Unable to load orders",
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return DSEmptyState(
            icon: Icons.receipt_long_outlined,
            title: "No active orders",
            subtitle: "Your active orders will appear here",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(DS.spaceLg),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderData = order.data() as Map<String, dynamic>?;
            if (orderData == null) return const SizedBox();
            return OrderCard(
              orderId: order.id,
              serviceType: orderData['service_type'] ?? 'Unknown',
              status: orderData['status'] ?? 'pending',
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

class OrderCard extends StatefulWidget {
  final String orderId;
  final String serviceType;
  final String status;
  final String createdAt;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard>
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

    if (_shouldAnimate(widget.status)) {
      _controller.repeat(reverse: true);
    }
  }

  bool _shouldAnimate(String status) {
    return status == 'pending' || status == 'in_progress';
  }

  @override
  void didUpdateWidget(OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate(widget.status)) {
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

  bool _canCancel() {
    return widget.status == 'pending' || widget.status == 'accepted';
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DSDialog(
        title: 'Cancel Order?',
        content: DSText.bodyMedium(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          color: AppColors.kGreyText,
        ),
        actions: [
          DSButton.secondary(
            label: 'Keep Order',
            onPressed: () => Navigator.pop(context, false),
          ),
          DSButton.destructive(
            label: 'Cancel Order',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': 'customer',
      });

      if (widget.status == 'accepted') {
        final orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();
        final providerId = orderDoc.data()?['provider_id'];
        if (providerId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipient_id': providerId,
            'title': 'Order Cancelled',
            'body': 'The customer has cancelled the ${widget.serviceType} order',
            'data': {'order_id': widget.orderId},
            'read': false,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order cancelled'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DS.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DS.radiusMd),
            ),
          ),
        );
      }
    }
  }

  IconData _getServiceIcon() => serviceIcon(widget.serviceType);

  String _getStatusText() {
    switch (widget.status) {
      case 'pending':
        return 'Looking for providers...';
      case 'accepted':
        return 'Provider accepted - on the way';
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
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return AppColors.kGreyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DSCard(
      padding: const EdgeInsets.all(DS.spaceMd),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(orderId: widget.orderId),
          ),
        );
      },
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
          const SizedBox(width: DS.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText.titleMedium(widget.serviceType),
                const SizedBox(height: DS.spaceXs),
                Row(
                  children: [
                    FadeTransition(
                      opacity: _controller,
                      child: DSText.bodySmall(
                        _getStatusText(),
                        color: _getStatusColor(),
                      ),
                    ),
                    const Spacer(),
                    DSText.caption(widget.createdAt),
                  ],
                ),
              ],
            ),
          ),
          if (_canCancel())
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.kBlack, size: DS.iconMd),
              onPressed: _cancelOrder,
              tooltip: 'Cancel Order',
            ),
        ],
      ),
    );
  }
}