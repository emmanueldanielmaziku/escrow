import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check for Play Store updates before proceeding
      await UpdateService.checkForUpdate(context);

      if (!mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // First check if user is logged in from SharedPreferences
      final isLoggedIn = await authService.checkLoginStatus();

      if (isLoggedIn) {
        // Try to get stored user data first
        final storedUser = await authService.getStoredUserData();
        if (storedUser != null) {
          // Set the stored user data in the provider
          userProvider.setUser(storedUser);

          // Verify the user data with Firestore
          final currentUser = await authService.getCurrentUser();
          if (currentUser != null) {
            // Update provider with fresh data from Firestore
            userProvider.setUser(currentUser);
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
            return;
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/icons/green.png',
              scale: 30,),
              const SizedBox(height: 24),
       
       
              const SizedBox(height: 48),
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
