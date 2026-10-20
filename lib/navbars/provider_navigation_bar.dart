import 'package:flutter/material.dart';
import 'package:serbisyo_ph/pages/provider/incoming_orders.dart';
import 'package:serbisyo_ph/pages/provider/provider_orders.dart';
import 'package:serbisyo_ph/pages/provider/provider_settings.dart';
import 'package:serbisyo_ph/pages/provider/provider_home_page.dart';
import 'package:serbisyo_ph/pages/notifications/notifications_page.dart';
import 'package:serbisyo_ph/navbars/nav_bar_item.dart';
import 'package:serbisyo_ph/theme/colors.dart';

class ProviderNavigationBar extends StatefulWidget {
  const ProviderNavigationBar({super.key});

  @override
  State<ProviderNavigationBar> createState() => _ProviderNavigationBarState();
}

class _ProviderNavigationBarState extends State<ProviderNavigationBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Column(
        children: [
          if (currentPageIndex > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 28),
              decoration: const BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      currentPageIndex == 1
                          ? "INCOMING ORDERS"
                          : currentPageIndex == 2
                          ? "MY ORDERS"
                          : "NOTIFICATIONS",
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.kWhite,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (currentPageIndex > 0)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProviderSettingsPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.settings,
                          color: AppColors.kWhite,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: <Widget>[
              const ProviderHomePage(),
              const IncomingOrders(),
              const ProviderOrders(),
              const NotificationsPage(),
            ][currentPageIndex],
          ),
        ],
      ),
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
            label: "Incoming",
            iconWhenSelected: Icons.inbox,
            iconWhenIdle: Icons.inbox_outlined,
          ),
          NavBarItem(
            label: "My Orders",
            iconWhenSelected: Icons.list_alt,
            iconWhenIdle: Icons.list_alt_outlined,
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
