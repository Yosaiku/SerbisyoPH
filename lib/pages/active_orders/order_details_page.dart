import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';
import 'package:serbisyo_ph/pages/chat/chat_page.dart';
import 'package:serbisyo_ph/utilities/service_icons.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _providerData;
  bool _loading = true;
  List<DocumentSnapshot> _offers = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    if (orderDoc.exists) {
      final data = orderDoc.data() as Map<String, dynamic>;
      setState(() {
        _orderData = data;
      });

      if (data['provider_id'] != null) {
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['provider_id'])
            .get();
        if (providerDoc.exists) {
          setState(() {
            _providerData = providerDoc.data();
          });
        }
      }

      if (data['status'] == 'pending') {
        final offersSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('order_id', isEqualTo: widget.orderId)
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: true)
            .get();
        setState(() {
          _offers = offersSnapshot.docs;
        });
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _acceptOffer(String offerId, String providerId) async {
    try {
      final offerDoc = await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .get();
      final offerData = offerDoc.data();
      final price = offerData?['price']?.toString() ?? '0';
      final serviceType = _orderData?['service_type'] ?? 'Service';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'status': 'accepted',
            'provider_id': providerId,
            'accepted_at': FieldValue.serverTimestamp(),
            'accepted_price': offerData?['price'],
          });

      await FirebaseFirestore.instance.collection('offers').doc(offerId).update(
        {'status': 'accepted'},
      );

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipient_id': providerId,
        'title': 'Offer Accepted!',
        'body': 'Your offer of ₱$price for $serviceType was accepted',
        'data': {'order_id': widget.orderId},
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      final otherOffers = await FirebaseFirestore.instance
          .collection('offers')
          .where('order_id', isEqualTo: widget.orderId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (var doc in otherOffers.docs) {
        await doc.reference.update({'status': 'rejected'});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offer accepted! Order confirmed."),
            backgroundColor: AppColors.kBlack,
          ),
        );
        _loadOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year at $hour:$minute $period';
  }

  IconData _getServiceIcon() => serviceIcon(_orderData?['service_type']);

  String _getQuantityLabel() {
    if (_orderData?['basket_count'] != null) {
      return '${_orderData!['basket_count']} basket(s)';
    }
    if (_orderData?['gallon_count'] != null) {
      return '${_orderData!['gallon_count']} gallon(s)';
    }
    if (_orderData?['tank_count'] != null) {
      return '${_orderData!['tank_count']} tank(s)';
    }
    return '';
  }

  String _getStatusText() {
    switch (_orderData?['status']) {
      case 'pending':
        return 'Looking for providers...';
      case 'accepted':
        return 'Provider accepted';
      case 'in_progress':
        return 'Service in progress';
      case 'completed':
        return 'Completed';
      default:
        return _orderData?['status'] ?? '';
    }
  }

  Color _getStatusColor() {
    switch (_orderData?['status']) {
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
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "ORDER DETAILS",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kBlack),
            )
          : _orderData == null
          ? const Center(child: Text("Order not found"))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.kWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppColors.kBlack,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getServiceIcon(),
                            color: AppColors.kWhite,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _orderData?['service_type'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection("Order Information", [
                    _buildInfoRow(
                      "Order ID",
                      widget.orderId.substring(0, 8).toUpperCase(),
                    ),
                    if (_orderData?['created_at'] != null)
                      _buildInfoRow(
                        "Placed",
                        _formatTimestamp(_orderData!['created_at']),
                      ),
                    if (_getQuantityLabel().isNotEmpty)
                      _buildInfoRow("Quantity", _getQuantityLabel()),
                    if (_orderData?['note'] != null &&
                        _orderData!['note'].toString().isNotEmpty)
                      _buildInfoRow("Note", _orderData!['note']),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection("Locations", [
                    _buildInfoRow(
                      "Pickup",
                      _orderData?['pickup_location'] ?? 'Not specified',
                    ),
                    _buildInfoRow(
                      "Delivery",
                      _orderData?['delivery_location'] ?? 'Not specified',
                    ),
                  ]),
                  if (_providerData != null) ...[
                    const SizedBox(height: 16),
                    _buildSection("Provider", [
                      _buildInfoRow(
                        "Name",
                        _providerData!['name'] ?? 'Unknown',
                      ),
                      if (_providerData!['phone'] != null)
                        _buildInfoRow("Phone", _providerData!['phone']),
                    ]),
                    const SizedBox(height: 12),
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
                                otherUserId: _orderData!['provider_id'],
                                otherUserName:
                                    _providerData!['name'] ?? 'Provider',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text("Message Provider"),
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
                  if (_orderData?['status'] == 'pending' &&
                      _offers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      "Offers (${_offers.length})",
                      _offers.map((offer) {
                        final data = offer.data() as Map<String, dynamic>;
                        return _buildOfferCard(data, offer.id);
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.kBlack.withValues(alpha: 0.5),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.kGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.kBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, String offerId) {
    final providerName = offer['provider_name'] ?? 'Provider';
    final price = offer['price']?.toString() ?? '0';
    final isImmediate = offer['is_immediate'] ?? true;
    final scheduleHours = offer['schedule_hours'];
    final terms = offer['terms'] ?? '';

    String scheduleText = isImmediate
        ? 'Immediate'
        : 'In $scheduleHours hour(s)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                providerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.kBlack,
                ),
              ),
              const Spacer(),
              Text(
                '₱$price',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            scheduleText,
            style: const TextStyle(fontSize: 12, color: AppColors.kGreyText),
          ),
          if (terms.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              terms,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.kGreyText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _acceptOffer(offerId, offer['provider_id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Accept Offer",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
