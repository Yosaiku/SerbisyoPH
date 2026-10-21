import 'package:flutter/material.dart';
import 'package:serbisyo_ph/pages/provider/incoming_orders.dart';
import 'package:serbisyo_ph/pages/provider/provider_orders.dart';
import 'package:serbisyo_ph/pages/provider/provider_settings.dart';
import 'package:serbisyo_ph/pages/provider/provider_home_page.dart';
import 'package:serbisyo_ph/pages/notifications/notifications_page.dart';
import 'package:serbisyo_ph/theme/design_system.dart';

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
              padding: const EdgeInsets.fromLTRB(DS.spaceLg, 50, DS.spaceLg, DS.spaceLg),
              decoration: const BoxDecoration(
                color: AppColors.kBlack,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(DS.radiusXl),
                  bottomRight: Radius.circular(DS.radiusXl),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DSText.headlineMedium(
                      currentPageIndex == 1
                          ? "INCOMING ORDERS"
                          : currentPageIndex == 2
                              ? "MY ORDERS"
                              : "NOTIFICATIONS",
                      color: AppColors.kWhite,
                    ),
                  ),
                  if (currentPageIndex > 0)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProviderSettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, color: AppColors.kWhite, size: DS.iconMd),
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
          DSNavDestination(
            label: "Home",
            selectedIcon: Icons.home,
            unselectedIcon: Icons.home_outlined,
          ),
          DSNavDestination(
            label: "Incoming",
            selectedIcon: Icons.inbox,
            unselectedIcon: Icons.inbox_outlined,
          ),
          DSNavDestination(
            label: "My Orders",
            selectedIcon: Icons.list_alt,
            unselectedIcon: Icons.list_alt_outlined,
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
