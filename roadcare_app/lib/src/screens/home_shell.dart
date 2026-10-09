import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../store.dart';
import 'citizen_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'incidents_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'work_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionProvider)!.role;
    final citizen = role == UserRole.citizen;
    final pages = citizen
        ? const [
            CitizenDashboardScreen(),
            IncidentsScreen(onlyMine: true),
            MapScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            MapScreen(),
            IncidentsScreen(),
            WorkScreen(),
            ProfileScreen(),
          ];
    final destinations = citizen
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'My reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.report_gmailerrorred_outlined),
              selectedIcon: Icon(Icons.report_rounded),
              label: 'Cases',
            ),
            NavigationDestination(
              icon: Icon(Icons.engineering_outlined),
              selectedIcon: Icon(Icons.engineering_rounded),
              label: 'Work',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ];
    if (index >= pages.length) index = 0;
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: index == pages.length - 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ReportScreen())),
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Report'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: destinations,
      ),
    );
  }
}
