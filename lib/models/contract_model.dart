import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class ContractModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  String status;
  final String creatorId;
  final String inviteeId;
  final Timestamp createdAt;
  Timestamp? acceptedAt;
  String? proofOfPaymentUrl;
  String? receiptNumber;
  bool withdrawalRequested;
  bool userAConfirmed;

  ContractModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    this.status = AppConstants.dormant,
    required this.creatorId,
    required this.inviteeId,
    required this.createdAt,
    this.acceptedAt,
    this.proofOfPaymentUrl,
    this.receiptNumber,
    this.withdrawalRequested = false,
    this.userAConfirmed = false,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? AppConstants.dormant,
      creatorId: json['creatorId'] ?? '',
      inviteeId: json['inviteeId'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      acceptedAt: json['acceptedAt'],
      proofOfPaymentUrl: json['proofOfPaymentUrl'],
      receiptNumber: json['receiptNumber'],
      withdrawalRequested: json['withdrawalRequested'] ?? false,
      userAConfirmed: json['userAConfirmed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'status': status,
      'creatorId': creatorId,
      'inviteeId': inviteeId,
      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'proofOfPaymentUrl': proofOfPaymentUrl,
      'receiptNumber': receiptNumber,
      'withdrawalRequested': withdrawalRequested,
      'userAConfirmed': userAConfirmed,
    };
  }

  // Helper method to create a copy with modified fields
  ContractModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? status,
    String? creatorId,
    String? inviteeId,
    Timestamp? createdAt,
    Timestamp? acceptedAt,
    String? proofOfPaymentUrl,
    String? receiptNumber,
    bool? withdrawalRequested,
    bool? userAConfirmed,
  }) {
    return ContractModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      inviteeId: inviteeId ?? this.inviteeId,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      proofOfPaymentUrl: proofOfPaymentUrl ?? this.proofOfPaymentUrl,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      withdrawalRequested: withdrawalRequested ?? this.withdrawalRequested,
      userAConfirmed: userAConfirmed ?? this.userAConfirmed,
    );
  }
}
