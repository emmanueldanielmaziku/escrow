import 'package:flutter/material.dart';
import 'tabs/contracts_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/invitations_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:iconsax/iconsax.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const ContractsTab(),
    const InvitationsTab(),
    const ProfileTab(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: NavigationBar(
        height: 70.0,
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
            NavigationDestination(icon: Icon(Iconsax.archive), label: "Contracts"),
          NavigationDestination(
              icon: Icon(Iconsax.direct_inbox), label: "Invitations"),
        
          NavigationDestination(
              icon: Icon(Iconsax.user), label: "Profile")
        ]),
        ),
      ),
    );
  }
}
