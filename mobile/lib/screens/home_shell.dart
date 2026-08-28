import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'booking_history_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'station_list_screen.dart';
import 'wallet_screen.dart';

/// Lets any descendant jump to another bottom-nav tab
/// (e.g. the dashboard's "View all" links).
class HomeShellScope extends InheritedWidget {
  const HomeShellScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final void Function(int index) goToTab;

  static HomeShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>();

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) => false;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const int tabHome = 0;
  static const int tabStations = 1;
  static const int tabBookings = 2;
  static const int tabWallet = 3;
  static const int tabProfile = 4;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // IndexedStack keeps each tab's scroll position and loaded data alive;
  // every tab supports pull-to-refresh for fresh data.
  final List<Widget> _pages = const [
    DashboardScreen(),
    StationListScreen(),
    BookingHistoryScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  void _goToTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return HomeShellScope(
      goToTab: _goToTab,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 66,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.14),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryDark),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.ev_station_outlined),
              selectedIcon:
                  Icon(Icons.ev_station_rounded, color: AppTheme.primaryDark),
              label: 'Stations',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long_rounded, color: AppTheme.primaryDark),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryDark),
              label: 'Wallet',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryDark),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
