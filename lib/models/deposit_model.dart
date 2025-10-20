
class DepositModel {
  final String id;
  final String contractId;
  final String userId;
  final String provider;
  final String contractFund;
  final String channel;
  final String paymentMessage;
  final DateTime createdAt;
  final String status;

  DepositModel({
    required this.id,
    required this.contractId,
    required this.userId,
    required this.provider,
    required this.contractFund,
    required this.channel,
    required this.paymentMessage,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'userId': userId,
      'provider': provider,
      'contractFund': contractFund,
      'channel': channel,
      'paymentMessage': paymentMessage,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory DepositModel.fromMap(Map<String, dynamic> map) {
    return DepositModel(
      id: map['id'] as String,
      contractId: map['contractId'] as String,
      userId: map['userId'] as String,
      provider: map['provider'] as String,
      contractFund: map['contractFund'] as String,
      channel: map['channel'] as String,
      paymentMessage: map['paymentMessage'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: map['status'] as String,
    );
  }
}
