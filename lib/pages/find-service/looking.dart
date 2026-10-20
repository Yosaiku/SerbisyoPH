import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class LookingForService extends StatefulWidget {
  final Map<String, dynamic> request;

  const LookingForService({super.key, required this.request});

  @override
  State<LookingForService> createState() => _LookingForServiceState();
}

class _LookingForServiceState extends State<LookingForService>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _broadcastPhase = 'Searching within 2km...';
  int _phase = 1;
  bool _broadcastFailed = false;
  DateTime? _broadcastStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startBroadcastTimer();
  }

  void _startBroadcastTimer() {
    _broadcastStartTime = DateTime.now();
    _updatePhase();
  }

  void _updatePhase() {
    if (_broadcastFailed) return;

    final elapsed = DateTime.now().difference(_broadcastStartTime!);

    if (elapsed.inMinutes >= 5) {
      setState(() {
        _broadcastFailed = true;
        _broadcastPhase = 'No providers found nearby';
      });
      return;
    }

    if (elapsed.inMinutes >= 2 && _phase == 1) {
      setState(() {
        _phase = 2;
        _broadcastPhase = 'Expanding to 10km...';
      });
    } else if (elapsed.inMinutes >= 4 && _phase == 2) {
      setState(() {
        _phase = 3;
        _broadcastPhase = 'Expanding to 15km (final)...';
      });
    }

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_broadcastFailed) {
        _updatePhase();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.request['order_id'] as String?;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kBlack),
        title: const Text(
          "PROVIDER OFFERS",
          style: TextStyle(
            color: AppColors.kBlack,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: orderId == null
          ? _buildErrorState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('order_id', isEqualTo: orderId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    children: [
                      _buildSummaryCard(widget.request),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.kBorder,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Unable to load offers",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kBlack,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
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
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  children: [
                    _buildSummaryCard(widget.request),
                    const SizedBox(height: 20),
                    _buildBroadcastStatus(),
                    const SizedBox(height: 20),
                    _buildPhaseIndicator(),
                    const SizedBox(height: 32),
                    Text(
                      (snapshot.data?.docs.isEmpty ?? true)
                          ? "WAITING FOR OFFERS..."
                          : "AVAILABLE OFFERS (${snapshot.data!.docs.length})",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kBlack.withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_broadcastFailed &&
                        (snapshot.data?.docs.isEmpty ?? true))
                      _buildNoOffersState()
                    else if (snapshot.data?.docs.isEmpty ?? true)
                      _buildSearchingState()
                    else
                      ...() {
                        final docs = snapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aPrice =
                              (a.data() as Map<String, dynamic>)['price']
                                  as num? ??
                              0;
                          final bPrice =
                              (b.data() as Map<String, dynamic>)['price']
                                  as num? ??
                              0;
                          return aPrice.compareTo(bPrice);
                        });
                        return docs.map((doc) {
                          final offer = doc.data() as Map<String, dynamic>;
                          return _buildProviderCard(offer, doc.id);
                        });
                      }(),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.kBorder),
          const SizedBox(height: 16),
          const Text("Order not found"),
        ],
      ),
    );
  }

  Widget _buildBroadcastStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _broadcastFailed
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _broadcastFailed ? Icons.warning_amber : Icons.radar,
            color: _broadcastFailed ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _broadcastPhase,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _broadcastFailed ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPhaseDot(1, '2km'),
        _buildPhaseLine(_phase > 1),
        _buildPhaseDot(2, '10km'),
        _buildPhaseLine(_phase > 2),
        _buildPhaseDot(3, '15km'),
      ],
    );
  }

  Widget _buildPhaseDot(int phase, String label) {
    final isActive = _phase >= phase;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : AppColors.kBorder,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            size: 14,
            color: isActive ? AppColors.kWhite : AppColors.kBorder,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.kBlack : AppColors.kGreyText,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.green : AppColors.kBorder,
    );
  }

  Widget _buildNoOffersState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.kBorder),
            const SizedBox(height: 16),
            const Text(
              "No offers received",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.kBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We couldn't find available providers nearby",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.kGreyText),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kBlack,
              ),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> request) {
    DateTime date =
        DateTime.tryParse(request["timestamp"] ?? "") ?? DateTime.now();
    String timeStamp = DateFormat(
      "MMM dd • hh:mm a",
    ).format(date).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request["service_type"]?.toUpperCase() ?? "SERVICE",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  timeStamp,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kGreyText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.kBorder, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryRow(
                  "Pickup",
                  request["pickup_location"] ?? "-",
                  Icons.trip_origin,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  "Delivery",
                  request["delivery_location"] ?? "-",
                  Icons.place_outlined,
                ),
                if (request["basket_count"] != null ||
                    request["gallon_count"] != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (request["basket_count"] != null)
                        _buildMetricChip(
                          "${request["basket_count"]} Baskets",
                          Icons.shopping_basket_outlined,
                        ),
                      if (request["basket_count"] != null &&
                          request["gallon_count"] != null)
                        const SizedBox(width: 12),
                      if (request["gallon_count"] != null)
                        _buildMetricChip(
                          "${request["gallon_count"]} Gallons",
                          Icons.water_drop_outlined,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (request["note"] != null &&
              request["note"].toString().isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.kBorder, thickness: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.kBackground,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Text(
                '"${request["note"]}"',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.kGreyText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.kBlack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.kGreyText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.kBlack),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> offer, String offerId) {
    final providerName = offer['provider_name'] ?? 'Provider';
    final price = offer['price']?.toString() ?? '0';
    final isImmediate = offer['is_immediate'] ?? true;
    final scheduleHours = offer['schedule_hours'];

    String scheduleText = isImmediate
        ? 'Immediate'
        : 'In $scheduleHours hour(s)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront,
                color: AppColors.kWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.kBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.kGreyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scheduleText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.kGreyText,
                        ),
                      ),
                      if (offer['terms'] != null &&
                          offer['terms'].toString().isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.note_outlined,
                          size: 14,
                          color: AppColors.kGreyText,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱$price',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.kBlack,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kBlack,
                      foregroundColor: AppColors.kWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        _acceptOffer(offerId, offer['provider_id']),
                    child: const Text(
                      "Accept",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOffer(String offerId, String providerId) async {
    final orderId = widget.request['order_id'];
    if (orderId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': 'accepted',
            'provider_id': providerId,
            'accepted_at': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance.collection('offers').doc(offerId).update(
        {'status': 'accepted'},
      );

      final otherOffers = await FirebaseFirestore.instance
          .collection('offers')
          .where('order_id', isEqualTo: orderId)
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
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSearchingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(Icons.radar, size: 40, color: AppColors.kBlack),
            ),
            const SizedBox(height: 20),
            const Text(
              "Looking for nearby providers...",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.kGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Waiting for offers to come in",
              style: TextStyle(fontSize: 12, color: AppColors.kGreyText),
            ),
          ],
        ),
      ),
    );
  }
}
