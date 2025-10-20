class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String nidaNumber;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.nidaNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      nidaNumber: json['nidaNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'nidaNumber': nidaNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      nidaNumber: map['nidaNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'nidaNumber': nidaNumber,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? nidaNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nidaNumber: nidaNumber ?? this.nidaNumber,
    );
  }
}
