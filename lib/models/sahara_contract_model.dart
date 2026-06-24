import 'package:flutter/material.dart';

enum ContractType {
  negotiable, // Flexible, can be closed anytime
  nonNegotiable, // Cannot be terminated before term
}

enum SaharaContractStatus {
  active,
  inProgress, // Partially funded, not yet fully funded
  sahara, // Completed/closed state
  unfunded,
}

class SaharaContractModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final double fundedAmount;
  final ContractType contractType;
  final SaharaContractStatus status;
  final DateTime createdAt;
  final DateTime? contractEndDate; // For non-negotiable contracts (calculated from contractTerm)
  final String ownerId; // Sahara owner/creator (required - sahara contracts have single owner)
  final String ownerName; // Sahara owner/creator name (required)

  SaharaContractModel({
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

  static Color getStatusColor(SaharaContractStatus status) {
    switch (status) {
      case SaharaContractStatus.active:
        return Colors.green;
      case SaharaContractStatus.inProgress:
        return Colors.orange;
      case SaharaContractStatus.sahara:
        return Colors.blue;
      case SaharaContractStatus.unfunded:
        return Colors.orange;
    }
  }

  static String getStatusText(SaharaContractStatus status) {
    switch (status) {
      case SaharaContractStatus.active:
        return 'Active';
      case SaharaContractStatus.inProgress:
        return 'In Progress';
      case SaharaContractStatus.sahara:
        return 'Sahara';
      case SaharaContractStatus.unfunded:
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

  factory SaharaContractModel.fromMap(Map<String, dynamic> map) {
    return SaharaContractModel(
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
        if (s == 'inProgress' || s == 'in_progress') return SaharaContractStatus.inProgress;
        final parsed = SaharaContractStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SaharaContractStatus.unfunded,
        );
        // Backward compatibility: partially funded but stored as unfunded → show as inProgress
        if (parsed == SaharaContractStatus.unfunded) {
          final amt = (map['amount'] as num?)?.toDouble();
          final funded = (map['fundedAmount'] as num?)?.toDouble() ?? 0.0;
          if (amt != null && funded > 0 && funded < amt) return SaharaContractStatus.inProgress;
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

