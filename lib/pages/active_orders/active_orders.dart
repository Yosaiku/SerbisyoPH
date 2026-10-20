import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';
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
          _ActiveOrdersList(userId: userId),
          const OrderHistoryPage(),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.kBorder),
                const SizedBox(height: 12),
                Text(
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
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.kBorder,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No active orders",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your active orders will appear here",
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
            return OrderCard(
              orderId: order.id,
              serviceType: orderData['service_type'] ?? 'Unknown',
              status: orderData['status'] ?? 'pending',
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: ListTile(
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(orderId: widget.orderId),
            ),
          );
        },
      ),
    );
  }
}
