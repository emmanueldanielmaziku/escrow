import 'package:flutter/material.dart';

enum ContractType {
  negotiable, // Flexible, can be closed anytime
  nonNegotiable, // Cannot be terminated before term
}

enum BudgetContractStatus {
  active,
  sahara, // Completed/closed state
  unfunded,
}

class BudgetContractModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final double fundedAmount;
  final ContractType contractType;
  final BudgetContractStatus status;
  final DateTime createdAt;
  final DateTime? contractEndDate; // For non-negotiable contracts
  final Duration? contractTerm; // Duration of contract
  final String? remitterId;
  final String? remitterName;
  final String? beneficiaryId;
  final String? beneficiaryName;

  BudgetContractModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    this.fundedAmount = 0.0,
    required this.contractType,
    required this.status,
    required this.createdAt,
    this.contractEndDate,
    this.contractTerm,
    this.remitterId,
    this.remitterName,
    this.beneficiaryId,
    this.beneficiaryName,
  });

  bool get isFullyFunded => fundedAmount >= amount;
  bool get canBeTerminated {
    if (contractType == ContractType.negotiable) return true;
    if (contractType == ContractType.nonNegotiable) {
      return contractEndDate != null && DateTime.now().isAfter(contractEndDate!);
    }
    return false;
  }

  Duration? get remainingTime {
    if (contractEndDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(contractEndDate!)) return Duration.zero;
    return contractEndDate!.difference(now);
  }

  static Color getStatusColor(BudgetContractStatus status) {
    switch (status) {
      case BudgetContractStatus.active:
        return Colors.green;
      case BudgetContractStatus.sahara:
        return Colors.blue;
      case BudgetContractStatus.unfunded:
        return Colors.orange;
    }
  }

  static String getStatusText(BudgetContractStatus status) {
    switch (status) {
      case BudgetContractStatus.active:
        return 'Active';
      case BudgetContractStatus.sahara:
        return 'Sahara';
      case BudgetContractStatus.unfunded:
        return 'Unfunded';
    }
  }

  static String getContractTypeText(ContractType type) {
    switch (type) {
      case ContractType.negotiable:
        return 'Negotiable';
      case ContractType.nonNegotiable:
        return 'Non-Negotiable';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'fundedAmount': fundedAmount,
      'contractType': contractType.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'contractTerm': contractTerm?.inDays,
      'remitterId': remitterId,
      'remitterName': remitterName,
      'beneficiaryId': beneficiaryId,
      'beneficiaryName': beneficiaryName,
    };
  }

  factory BudgetContractModel.fromMap(Map<String, dynamic> map) {
    return BudgetContractModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      fundedAmount: (map['fundedAmount'] as num?)?.toDouble() ?? 0.0,
      contractType: ContractType.values.firstWhere(
        (e) => e.name == map['contractType'],
        orElse: () => ContractType.negotiable,
      ),
      status: BudgetContractStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BudgetContractStatus.unfunded,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      contractEndDate: map['contractEndDate'] != null
          ? DateTime.parse(map['contractEndDate'] as String)
          : null,
      contractTerm: map['contractTerm'] != null
          ? Duration(days: map['contractTerm'] as int)
          : null,
      remitterId: map['remitterId'] as String?,
      remitterName: map['remitterName'] as String?,
      beneficiaryId: map['beneficiaryId'] as String?,
      beneficiaryName: map['beneficiaryName'] as String?,
    );
  }
}

