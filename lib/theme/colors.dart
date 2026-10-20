import 'package:flutter/material.dart';

class AppColors {
  static const Color kBlack = Color(0xFF0F0F0F);
  static const Color kWhite = Color(0xFFFFFFFF);
  static const Color kBackground = Color(0xFFFAFAFA);
  static const Color kBorder = Color(0xFFE0E0E0);
  static const Color kGreyText = Color(0xFF757575);

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : kBackground;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : kWhite;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : kBorder;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? kWhite : kBlack;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9E9E9E)
        : kGreyText;
  }
}
