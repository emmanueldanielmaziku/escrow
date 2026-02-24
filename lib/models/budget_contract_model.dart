import 'package:flutter/material.dart';

enum ContractType {
  negotiable, // Flexible, can be closed anytime
  nonNegotiable, // Cannot be terminated before term
}

enum BudgetContractStatus {
  active,
  inProgress, // Partially funded, not yet fully funded
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
  final DateTime? contractEndDate; // For non-negotiable contracts (calculated from contractTerm)
  final String ownerId; // Budget owner/creator (required - budgets have single owner)
  final String ownerName; // Budget owner/creator name (required)

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
    required this.ownerId,
    required this.ownerName,
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
      case BudgetContractStatus.inProgress:
        return Colors.orange;
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
      case BudgetContractStatus.inProgress:
        return 'In Progress';
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
      'ownerId': ownerId,
      'ownerName': ownerName,
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
      status: () {
        final s = map['status'];
        if (s == 'inProgress' || s == 'in_progress') return BudgetContractStatus.inProgress;
        final parsed = BudgetContractStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BudgetContractStatus.unfunded,
        );
        // Backward compatibility: partially funded but stored as unfunded → show as inProgress
        if (parsed == BudgetContractStatus.unfunded) {
          final amt = (map['amount'] as num?)?.toDouble();
          final funded = (map['fundedAmount'] as num?)?.toDouble() ?? 0.0;
          if (amt != null && funded > 0 && funded < amt) return BudgetContractStatus.inProgress;
        }
        return parsed;
      }(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      contractEndDate: map['contractEndDate'] != null
          ? DateTime.parse(map['contractEndDate'] as String)
          : null,
      // Handle backward compatibility: use remitterId/remitterName if ownerId/ownerName don't exist
      ownerId: map['ownerId'] as String? ?? map['remitterId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? map['remitterName'] as String? ?? '',
    );
  }
}

