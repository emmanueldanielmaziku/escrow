import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by phone number
  Stream<List<UserModel>> searchUsersByPhone(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where('phone', isGreaterThanOrEqualTo: phoneNumber)
        .where('phone', isLessThanOrEqualTo: '$phoneNumber\uf8ff')
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  // Get user by phone number
  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get user by phone: $e');
    }
  }

  // Search users by name
  Stream<List<UserModel>> searchUsersByName(String name) {
    if (name.isEmpty) {
      return Stream.value([]);
    }

    final searchTerm = name.toLowerCase();
    return _firestore
        .collection('users')
        .where('fullName', isGreaterThanOrEqualTo: searchTerm)
        .where('fullName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  // Search users by name or phone number (combined search)
  Stream<List<UserModel>> searchUsersByNameOrPhone(String searchQuery) {
    if (searchQuery.isEmpty) {
      return Stream.value([]);
    }

    final searchTerm = searchQuery.trim().toLowerCase();
    
    // Check if search query looks like a phone number (contains digits)
    final isPhoneSearch = RegExp(r'\d').hasMatch(searchTerm);
    
    if (isPhoneSearch) {
      // Search by phone number
      return _firestore
          .collection('users')
          .where('phone', isGreaterThanOrEqualTo: searchTerm)
          .where('phone', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(10)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      });
    } else {
      // Search by name
      return _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: searchTerm)
          .where('fullName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(10)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      });
    }
  }

  // Get all users for contacts picker
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }
}
