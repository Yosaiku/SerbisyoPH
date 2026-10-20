import 'package:flutter/material.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class NavBarItem extends StatelessWidget {
  final String label;
  final IconData iconWhenSelected;
  final IconData iconWhenIdle;

  const NavBarItem({
    super.key,
    required this.label,
    required this.iconWhenSelected,
    required this.iconWhenIdle,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: NavigationDestination(
        selectedIcon: Icon(iconWhenSelected, color: AppColors.kWhite),
        icon: Icon(iconWhenIdle, color: AppColors.kBlack),
        label: label,
      ),
    );
  }
}
