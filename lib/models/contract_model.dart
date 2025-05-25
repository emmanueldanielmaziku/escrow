class ContractModel {
  final String id;
  final String title;
  final String description;
  final double reward;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;

  // Benefactor information
  final String? benefactorId;
  final String? benefactorName;
  final String? benefactorPhone;

  // Beneficiary information
  final String? beneficiaryId;
  final String? beneficiaryName;
  final String? beneficiaryPhone;

  ContractModel({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
    this.benefactorId,
    this.benefactorName,
    this.benefactorPhone,
    this.beneficiaryId,
    this.beneficiaryName,
    this.beneficiaryPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'role': role,
      'benefactorId': benefactorId,
      'benefactorName': benefactorName,
      'benefactorPhone': benefactorPhone,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'beneficiaryPhone': beneficiaryPhone,
    };
  }

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      reward: (map['reward'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      role: map['role'] as String,
      benefactorId: map['benefactorId'] as String?,
      benefactorName: map['benefactorName'] as String?,
      benefactorPhone: map['benefactorPhone'] as String?,
      beneficiaryId: map['beneficiaryId'] as String?,
      beneficiaryName: map['beneficiaryName'] as String?,
      beneficiaryPhone: map['beneficiaryPhone'] as String?,
    );
  }
}
