import 'package:flutter/material.dart';
import 'package:serbisyo_ph/pages/active_orders/active_orders.dart';
import 'package:serbisyo_ph/pages/home/home.dart';
import 'package:serbisyo_ph/pages/home/map_view.dart';
import 'package:serbisyo_ph/pages/notifications/notifications_page.dart';
import 'package:serbisyo_ph/navbars/nav_bar_item.dart';
import 'package:serbisyo_ph/theme/colors.dart';

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
          NavBarItem(
            label: "Home",
            iconWhenSelected: Icons.home,
            iconWhenIdle: Icons.home_outlined,
          ),
          NavBarItem(
            label: "Map",
            iconWhenSelected: Icons.map,
            iconWhenIdle: Icons.map_outlined,
          ),
          NavBarItem(
            label: "Orders",
            iconWhenSelected: Icons.list,
            iconWhenIdle: Icons.list_outlined,
          ),
          NavBarItem(
            label: "Alerts",
            iconWhenSelected: Icons.notifications,
            iconWhenIdle: Icons.notifications_outlined,
          ),
        ],
      ),
    );
  }
}
