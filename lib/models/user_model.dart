class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String walletNumber;
  final double balance;
  final int totalContracts;
  final int totalInvitations;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.walletNumber,
    required this.balance,
    required this.totalContracts,
    required this.totalInvitations,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      walletNumber: json['walletNumber'],
      balance: json['balance'].toDouble(),
      totalContracts: json['totalContracts'],
      totalInvitations: json['totalInvitations'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'walletNumber': walletNumber,
      'balance': balance,
      'totalContracts': totalContracts,
      'totalInvitations': totalInvitations,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      walletNumber: map['walletNumber'] as String,
      balance: (map['balance'] as num).toDouble(),
      totalContracts: (map['totalContracts'] as num).toInt(),
      totalInvitations: (map['totalInvitations'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'walletNumber': walletNumber,
      'balance': balance,
      'totalContracts': totalContracts,
      'totalInvitations': totalInvitations,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? walletNumber,
    double? balance,
    int? totalContracts,
    int? totalInvitations,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      walletNumber: walletNumber ?? this.walletNumber,
      balance: balance ?? this.balance,
      totalContracts: totalContracts ?? this.totalContracts,
      totalInvitations: totalInvitations ?? this.totalInvitations,
    );
  }
}
