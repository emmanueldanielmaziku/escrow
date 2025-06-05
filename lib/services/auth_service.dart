import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        await signOut();
        return null;
      }

      final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      
      // Save user data to SharedPreferences
      await _saveUserData(userData);
      
      return userData;
    } catch (e) {
      print('Error getting current user: $e');
      await signOut();
      return null;
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(user.toMap()));
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', user.id);
  }

  // Get stored user data
  Future<UserModel?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        final userData = UserModel.fromMap(
          jsonDecode(userDataString) as Map<String, dynamic>,
        );
        return userData;
      }
      return null;
    } catch (e) {
      print('Error getting stored user data: $e');
      return null;
    }
  }

  // Register with phone number and password
  Future<UserModel> registerWithPhoneAndPassword(
      String fullName, String phone, String password) async {
    try {
      // Check if phone number already exists
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        throw Exception('Phone number already registered');
      }

      // Create user with phone number and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: '$phone@escrow.app',
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      // Generate a unique wallet number
      final walletNumber = 'W${DateTime.now().millisecondsSinceEpoch}';

      // Create user data
      final userData = UserModel(
        id: userCredential.user!.uid,
        fullName: fullName,
        phone: phone,
        email: '$phone@escrow.app',
        walletNumber: walletNumber,
        balance: 0.0,
        totalContracts: 0,
        totalInvitations: 0,
      );

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData.toMap());

      // Save user data to SharedPreferences
      await _saveUserData(userData);

      return userData;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('This phone number is already registered.');
      }
      throw Exception(e.message ?? 'An error occurred during registration');
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Sign in with phone number and password

Future<UserModel> signInWithPhoneAndPassword(
    String phone, String password) async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: '$phone@escrow.app',
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('Failed to sign in');
    }

    final uid = userCredential.user!.uid;

    // Fetch device token
    final fcmToken = await FirebaseMessaging.instance.getToken();

    // Update Firestore with the device token
    await _firestore.collection('users').doc(uid).update({
      'deviceToken': fcmToken,
    });

    // Get updated user data
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User data not found');
    }

    final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>);

    // Save user data locally
    await _saveUserData(userData);

    return userData;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      throw Exception('No user found with this phone number.');
    } else if (e.code == 'wrong-password') {
      throw Exception('Wrong password provided.');
    }
    throw Exception(e.message ?? 'An error occurred during sign in');
  } catch (e) {
    throw Exception('Failed to sign in: $e');
  }
}

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear login state and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');
      await prefs.remove('userData');
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Check if user is logged in from SharedPreferences
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get stored user ID
  Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}
