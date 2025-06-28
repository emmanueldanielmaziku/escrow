import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ContractStatus { active, unfunded, completed, rejected, terminated }

class Contract {
  final String id;
  final String remitterId;
  final String remitterName;
  final String remitterNumber;
  final String beneficiaryId;
  final String beneficiaryName;
  final String beneficiaryNumber;
  final String title;
  final String description;
  final ContractStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contract({
    required this.id,
    required this.remitterId,
    required this.remitterName,
    required this.remitterNumber,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.beneficiaryNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Contract to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remitterId': remitterId,
      'remitterName': remitterName,
      'remitterNumber': remitterNumber,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
      'beneficiaryNumber': beneficiaryNumber,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Contract from Firestore document
  factory Contract.fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'] ?? '',
      remitterId: map['remitterId'] ?? '',
      remitterName: map['remitterName'] ?? '',
      remitterNumber: map['remitterNumber'] ?? '',
      beneficiaryId: map['beneficiaryId'] ?? '',
      beneficiaryName: map['beneficiaryName'] ?? '',
      beneficiaryNumber: map['beneficiaryNumber'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: ContractStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContractStatus.unfunded,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy of Contract with updated fields
  Contract copyWith({
    String? id,
    String? remitterId,
    String? remitterName,
    String? remitterNumber,
    String? beneficiaryId,
    String? beneficiaryName,
    String? beneficiaryNumber,
    String? title,
    String? description,
    ContractStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      remitterId: remitterId ?? this.remitterId,
      remitterName: remitterName ?? this.remitterName,
      remitterNumber: remitterNumber ?? this.remitterNumber,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      beneficiaryNumber: beneficiaryNumber ?? this.beneficiaryNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get status color based on contract status
  static Color getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.unfunded:
        return Colors.orange;
      case ContractStatus.completed:
        return Colors.blue;
      case ContractStatus.rejected:
        return Colors.red;
      case ContractStatus.terminated:
        return Colors.grey;
    }
  }

  // Get status text based on contract status
  static String getStatusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.unfunded:
        return 'Unfunded';
      case ContractStatus.completed:
        return 'Completed';
      case ContractStatus.rejected:
        return 'Rejected';
      case ContractStatus.terminated:
        return 'Terminated';
    }
  }
}
