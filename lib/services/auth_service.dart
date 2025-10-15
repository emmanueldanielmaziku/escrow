import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/notification_settings_service.dart';

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

  // Register with email, phone, NIDA and password
  Future<UserModel> registerWithEmailPhoneAndPassword(String fullName,
      String email, String phone, String nidaNumber, String password) async {
    try {
      // Check if email already exists
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (emailQuery.docs.isNotEmpty) {
        throw Exception('Email already registered');
      }

      // Check if phone number already exists
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        throw Exception('Phone number already registered');
      }

      // Check if NIDA number already exists
      final nidaQuery = await _firestore
          .collection('users')
          .where('nidaNumber', isEqualTo: nidaNumber)
          .get();

      if (nidaQuery.docs.isNotEmpty) {
        throw Exception('NIDA number already registered');
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
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
        email: email.toLowerCase(),
        nidaNumber: nidaNumber,
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

      // Initialize FCM token management after successful registration
      await NotificationSettingsService.initializeTokenManagement();

      return userData;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      }
      throw Exception(e.message ?? 'An error occurred during registration');
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Sign in with email/phone and password
  Future<UserModel> signInWithEmailOrPhoneAndPassword(
      String emailOrPhone, String password) async {
    try {
      String email = emailOrPhone.toLowerCase();

      // If input looks like a phone number (doesn't contain @), search for user by phone
      if (!emailOrPhone.contains('@')) {
        final phoneQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: emailOrPhone)
            .limit(1)
            .get();

        if (phoneQuery.docs.isEmpty) {
          throw Exception('No user found with this phone number.');
        }

        // Get the email associated with this phone number
        final userDoc = phoneQuery.docs.first;
        final userData = UserModel.fromMap(userDoc.data());
        email = userData.email;
      }

      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }

      final uid = userCredential.user!.uid;

      // Get updated user data
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>);

      // Save user data locally
      await _saveUserData(userData);

      // Initialize FCM token management after successful login
      await NotificationSettingsService.initializeTokenManagement();

      return userData;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email address.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      } else if (e.code == 'invalid-credential') {
        throw Exception(
            'Invalid credentials. Please check your email/phone and password.');
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

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Check if email exists in Firestore
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (emailQuery.docs.isEmpty) {
        throw Exception('No account found with this email address');
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email.toLowerCase());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else if (e.code == 'user-not-found') {
        throw Exception('No account found with this email address');
      }
      throw Exception(e.message ?? 'Failed to send password reset email');
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Get the user's email
      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Reauthenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      }
      throw Exception(e.message ?? 'Failed to change password');
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Verify phone number exists in Firestore users collection
  Future<bool> verifyPhoneNumber(String phone) async {
    try {
      // Query Firestore users collection for the phone number
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      // Return true if user exists, false otherwise
      return userQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error verifying phone number: $e');
      return false;
    }
  }

  // Reset password directly (requires user to be signed in)
  Future<void> resetPassword(String phone, String newPassword) async {
    try {
      // First, check if user exists in Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('No account found with this phone number');
      }

      // Update the password using Firebase Admin SDK would be ideal here,
      // but since we're using client SDK, we need to sign in first
      // For now, we'll throw an error asking user to contact support
      throw Exception(
          'Password reset requires admin access. Please contact support.');
    } catch (e) {
      if (e.toString().contains('No account found')) {
        rethrow;
      }
      throw Exception('Failed to reset password: $e');
    }
  }

  // Reset password directly and login user
  // MVP Solution: Store password reset request in Firestore temporarily
  Future<UserModel> resetPasswordWithPhone(
      String phone, String newPassword) async {
    try {
      // First, verify the phone number exists in Firestore users collection
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('No account found with this phone number');
      }

      // Get user data from Firestore
      final userDoc = userQuery.docs.first;
      final userData = UserModel.fromMap(userDoc.data());
      final email = userData.email;

      // Store the password reset request temporarily in Firestore
      // This will be processed by a backend function or admin
      await _firestore.collection('password_resets').add({
        'phone': phone,
        'email': email,
        'userId': userData.id,
        'newPasswordHash': newPassword.hashCode.toString(), // Store hash only
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // For MVP: Try to sign in with the new password
      // This will work if an admin has already updated the password
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: newPassword,
        );

        if (userCredential.user != null) {
          // Success! Password was already updated
          await _saveUserData(userData);
          await NotificationSettingsService.initializeTokenManagement();
          return userData;
        }
      } on FirebaseAuthException catch (e) {
        // If sign in fails, it means password hasn't been updated yet
        // Return user data anyway and let them know to try again
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          // Password not updated yet, but request is stored
          return userData;
        }
        rethrow;
      }

      return userData;
    } catch (e) {
      if (e.toString().contains('No account found')) {
        rethrow;
      }
      throw Exception('Failed to reset password: $e');
    }
  }

  // Alternative: Update password using reauthentication (requires current password)
  Future<void> updatePasswordWithPhone(
      String phone, String currentPassword, String newPassword) async {
    try {
      // Convert phone to email format used in the app
      final email = '$phone@escrow.app';

      // Sign in with current credentials
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: currentPassword,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to verify current password');
      }

      // Update password
      await userCredential.user!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this phone number');
      } else if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      }
      throw Exception(e.message ?? 'Failed to update password');
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
}
