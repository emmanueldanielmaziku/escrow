import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'budgets_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _switchToProfile() {
    setState(() {
      _currentIndex = 3;
    });
  }

  void _switchToContracts() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _switchToBudgets() {
    setState(() {
      _currentIndex = 2;
    });
  }

  List<Widget> get _screens => [
        DashboardScreen(
          onContractsTap: _switchToContracts,
          onBudgetsTap: _switchToBudgets,
        ),
        HomeScreen(onProfileTap: _switchToProfile),
        const BudgetsScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CupertinoTabBar(
        height: 60,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        activeColor: Colors.green,
        inactiveColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.document_text),
            label: 'Contracts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.wallet_3),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.profile_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
