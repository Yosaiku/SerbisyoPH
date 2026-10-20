import 'package:flutter/material.dart';

IconData serviceIcon(String? serviceType) {
  switch (serviceType) {
    case 'Laundry':
      return Icons.local_laundry_service_outlined;
    case 'Water Refill':
      return Icons.water_drop_outlined;
    case 'LPG Refill':
      return Icons.gas_meter_rounded;
    default:
      return Icons.miscellaneous_services_outlined;
  }
}
