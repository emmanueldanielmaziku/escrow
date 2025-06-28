import 'package:flutter/material.dart';

class ContractModel {
  final String id;
  final String title;
  final String description;
  final double reward;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;

  // Remitter information
  final String? remitterId;
  final String? remitterName;
  final String? remitterPhone;

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
    this.remitterId,
    this.remitterName,
    this.remitterPhone,
    this.beneficiaryId,
    this.beneficiaryName,
    this.beneficiaryPhone,
  });

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'non-active':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'unfunded':
        return Colors.orange;
      case 'withdraw':
        return Colors.purple;
      case 'terminated':
        return Colors.red;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'non-active':
        return 'Inactive';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'unfunded':
        return 'Unfunded';
      case 'withdraw':
        return 'Withdrawal Requested';
      case 'terminated':
        return 'Terminated';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

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
      'remitterId': remitterId,
      'remitterName': remitterName,
      'remitterPhone': remitterPhone,
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
      remitterId: map['remitterId'] as String?,
      remitterName: map['remitterName'] as String?,
      remitterPhone: map['remitterPhone'] as String?,
      beneficiaryId: map['beneficiaryId'] as String?,
      beneficiaryName: map['beneficiaryName'] as String?,
      beneficiaryPhone: map['beneficiaryPhone'] as String?,
    );
  }
}
