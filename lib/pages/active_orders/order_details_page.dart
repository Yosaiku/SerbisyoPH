import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Map<String, dynamic>? _customerData;
  bool _loading = true;
  List<DocumentSnapshot> _offers = [];
  double _userRating = 0;
  bool _hasRated = false;
  bool _ratingSubmitting = false;
  final TextEditingController _reviewController = TextEditingController();

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

      // Load provider data
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

      // Load customer data
      if (data['customer_id'] != null) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['customer_id'])
            .get();
        if (customerDoc.exists) {
          setState(() {
            _customerData = customerDoc.data();
          });
        }
      }

      // Check if already rated
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && data['status'] == 'completed') {
        final existingRating = await FirebaseFirestore.instance
            .collection('reviews')
            .where('order_id', isEqualTo: widget.orderId)
            .where('customer_id', isEqualTo: userId)
            .get();
        if (existingRating.docs.isNotEmpty) {
          setState(() {
            _hasRated = true;
            _userRating = (existingRating.docs.first.data()['rating'] ?? 0).toDouble();
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

  bool _canCancel() {
    final status = _orderData?['status'];
    return status == 'pending' || status == 'accepted';
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.kBlack,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(color: AppColors.kGreyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep Order',
              style: TextStyle(
                color: AppColors.kGreyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kBlack,
              foregroundColor: AppColors.kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel Order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final status = _orderData?['status'];
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': 'customer',
      });

      // Notify provider if order was accepted
      if (status == 'accepted') {
        final providerId = _orderData?['provider_id'];
        if (providerId != null) {
          final serviceType = _orderData?['service_type'] ?? 'Service';
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipient_id': providerId,
            'title': 'Order Cancelled',
            'body': 'The customer has cancelled the $serviceType order',
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitRating() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _userRating == 0) return;

    setState(() => _ratingSubmitting = true);

    try {
      // Save review
      await FirebaseFirestore.instance.collection('reviews').add({
        'order_id': widget.orderId,
        'customer_id': userId,
        'provider_id': _orderData?['provider_id'],
        'rating': _userRating,
        'review': _reviewController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update provider's average rating
      final providerId = _orderData?['provider_id'];
      if (providerId != null) {
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();
        if (providerDoc.exists) {
          final data = providerDoc.data() as Map<String, dynamic>;
          final currentRating = (data['rating'] ?? 0.0).toDouble();
          final reviewCount = (data['review_count'] ?? 0).toInt();
          final newCount = reviewCount + 1;
          final newRating = ((currentRating * reviewCount) + _userRating) / newCount;

          await FirebaseFirestore.instance.collection('users').doc(providerId).update({
            'rating': newRating,
            'review_count': newCount,
          });
        }
      }

      if (mounted) {
        setState(() {
          _hasRated = true;
          _ratingSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you for rating!'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ratingSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch phone dialer'),
            backgroundColor: AppColors.kBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
        actions: _canCancel()
            ? [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.kBlack, size: 26),
                  onPressed: _cancelOrder,
                  tooltip: 'Cancel Order',
                ),
              ]
            : null,
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
                        _buildPhoneRow(_providerData!['phone']),
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
                  // Call Customer button (only if current user is the provider)
                  if (_orderData?['provider_id'] == FirebaseAuth.instance.currentUser?.uid &&
                      _orderData?['status'] != 'pending' &&
                      _customerData?['phone'] != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(_customerData!['phone']),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text(
                          "Call Customer",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kBlack,
                          foregroundColor: AppColors.kWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Rating section (only if completed and current user is customer)
                  if (_orderData?['status'] == 'completed' &&
                      _orderData?['customer_id'] == FirebaseAuth.instance.currentUser?.uid) ...[
                    const SizedBox(height: 16),
                    _buildRatingSection(),
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

  Widget _buildPhoneRow(String phoneNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "Phone",
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.kGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(phoneNumber),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text("Call", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kBlack,
                      side: const BorderSide(color: AppColors.kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildRatingSection() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCustomer = _orderData?['customer_id'] == currentUserId;

    return _buildSection(
      "Rate Your Experience",
      [
        if (!isCustomer) ...[
          const Center(
            child: Text(
              "Only the customer can leave a rating.",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.kGreyText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            "How was your service?",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = _userRating >= starValue;
              return GestureDetector(
                onTap: () => setState(() => _userRating = starValue.toDouble()),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  color: AppColors.kBlack,
                  size: 32,
                ),
              );
            }),
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 4),
            Text(
              "${_userRating.toInt()} star${_userRating == 1 ? '' : 's'}",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.kGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Add a review (optional)",
              hintStyle: const TextStyle(color: AppColors.kGreyText),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBlack, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          if (!_hasRated)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _ratingSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kBlack,
                  foregroundColor: AppColors.kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _ratingSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.kWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit Rating",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          if (_hasRated) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.kBlack, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "You rated this ${_userRating.toInt()} star${_userRating == 1 ? '' : 's'}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}
