import 'package:flutter/material.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class ServiceForm extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController deliveryController;
  final TextEditingController noteController;
  final bool sameAsPickup;
  final bool isLocating;
  final int selectedQuantity;

  final String quantityLabel; // Basket or Gallon

  final Function(bool?) onSameLocationChanged;
  final Function(int?) onQuantityChanged;
  final VoidCallback locateMe;
  final VoidCallback openPickupMap;
  final VoidCallback openDeliveryMap;

  const ServiceForm({
    super.key,
    required this.pickupController,
    required this.deliveryController,
    required this.sameAsPickup,
    required this.selectedQuantity,
    required this.quantityLabel,
    required this.noteController,
    required this.onSameLocationChanged,
    required this.onQuantityChanged,
    required this.locateMe,
    required this.openPickupMap,
    required this.openDeliveryMap,
    this.isLocating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pickup Location",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pickupController,
                    decoration: const InputDecoration(
                      hintText: "Enter pickup address",
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: isLocating ? null : locateMe,
                  icon: isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.kBlack,
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),

                InkWell(
                  onTap: openPickupMap,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.map, color: AppColors.kWhite),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(value: sameAsPickup, onChanged: onSameLocationChanged),
                const SizedBox(width: 10),
                const Text("Deliver to the same location"),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              "Delivery Location",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: deliveryController,
                    readOnly: sameAsPickup,
                    decoration: InputDecoration(
                      hintText: sameAsPickup
                          ? "Same as pickup"
                          : "Enter delivery address",
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                    ),
                  ),
                ),

                if (!sameAsPickup) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: openDeliveryMap,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.map, color: AppColors.kWhite),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Number of $quantityLabel",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            DropdownButton<int>(
              value: selectedQuantity,
              isExpanded: true,
              items: List.generate(20, (index) => index + 1)
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        "$value $quantityLabel${value > 1 ? 's' : ''}",
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onQuantityChanged,
            ),

            const SizedBox(height: 20),

            const Text(
              "Notes from Customer",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: TextField(
                controller: noteController,
                maxLines: 4,
                cursorColor: AppColors.kBlack,
                decoration: const InputDecoration(
                  hintText: "Add special instructions (optional)",
                  hintStyle: TextStyle(color: AppColors.kGreyText),
                  prefixIcon: Icon(
                    Icons.notes_outlined,
                    color: AppColors.kBlack,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
