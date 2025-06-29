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

  // Get all users for contacts picker
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }
}
