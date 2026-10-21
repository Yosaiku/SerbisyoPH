import 'package:flutter/material.dart';
import 'package:serbisyo_ph/pages/active_orders/active_orders.dart';
import 'package:serbisyo_ph/pages/home/home.dart';
import 'package:serbisyo_ph/pages/home/map_view.dart';
import 'package:serbisyo_ph/pages/notifications/notifications_page.dart';
import 'package:serbisyo_ph/theme/design_system.dart';

class HomeNavigationBar extends StatefulWidget {
  const HomeNavigationBar({super.key});

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: <Widget>[
        const HomePage(),
        const MapView(),
        const ActiveOrders(),
        const NotificationsPage(),
      ][currentPageIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: AppColors.kBlack,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          DSNavDestination(
            label: "Home",
            selectedIcon: Icons.home,
            unselectedIcon: Icons.home_outlined,
          ),
          DSNavDestination(
            label: "Map",
            selectedIcon: Icons.map,
            unselectedIcon: Icons.map_outlined,
          ),
          DSNavDestination(
            label: "Orders",
            selectedIcon: Icons.list,
            unselectedIcon: Icons.list_outlined,
          ),
          DSNavDestination(
            label: "Alerts",
            selectedIcon: Icons.notifications,
            unselectedIcon: Icons.notifications_outlined,
          ),
        ],
      ),
    );
  }
}
