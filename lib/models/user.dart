import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus { active, suspended, blocked, inactive }

class User {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.status = UserStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert User to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create User from Firestore document
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get status color based on user status
  static String getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.blocked:
        return 'Blocked';
      case UserStatus.inactive:
        return 'Inactive';
    }
  }

  // Check if user is active
  bool get isActive => status == UserStatus.active;

  // Check if user is blocked
  bool get isBlocked => status == UserStatus.blocked;

  // Check if user is suspended
  bool get isSuspended => status == UserStatus.suspended;
}
