import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

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
      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmailAndPassword(
      String email, String password, String fullName, String phone) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }

      // Generate a unique wallet number (you can modify this logic)
      final walletNumber = 'W${DateTime.now().millisecondsSinceEpoch}';

      // Create user data
      final userData = UserModel(
        id: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        phone: phone,
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

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userCredential.user!.uid);

      return userData;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      }
      throw Exception(e.message ?? 'An error occurred during registration');
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user data from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>);

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userCredential.user!.uid);

      return userData;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
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
      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');
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

  String _generateWalletNumber() {
    // Generate a unique 10-digit wallet number
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String random = _uuid.v4().substring(0, 6);
    return '${timestamp.substring(timestamp.length - 4)}$random';
  }
}
