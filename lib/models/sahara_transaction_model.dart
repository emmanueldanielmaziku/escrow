enum SaharaTransactionType { deposit, withdrawal }

enum SaharaTransactionStatus { pending, processing, completed, failed }

class SaharaTransactionModel {
  final String id;
  final String budgetId;
  final String ownerId;
  final SaharaTransactionType type;
  final double amount;
  final double? fee;
  final double? netAmount;
  final String currency;
  final SaharaTransactionStatus status;
  final String msisdn;
  final String channel;
  final String? recipientName;
  final String? depositId;
  final String? withdrawalId;
  final String? narration;
  final String? temboTxnId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SaharaTransactionModel({
    required this.id,
    required this.budgetId,
    required this.ownerId,
    required this.type,
    required this.amount,
    this.fee,
    this.netAmount,
    required this.currency,
    required this.status,
    required this.msisdn,
    required this.channel,
    this.recipientName,
    this.depositId,
    this.withdrawalId,
    this.narration,
    this.temboTxnId,
    required this.createdAt,
    this.completedAt,
  });

  static SaharaTransactionType _typeFromString(String? s) {
    switch (s) {
      case 'withdrawal':
        return SaharaTransactionType.withdrawal;
      default:
        return SaharaTransactionType.deposit;
    }
  }

  static SaharaTransactionStatus _statusFromString(String? s) {
    switch (s) {
      case 'processing':
        return SaharaTransactionStatus.processing;
      case 'completed':
        return SaharaTransactionStatus.completed;
      case 'failed':
        return SaharaTransactionStatus.failed;
      default:
        return SaharaTransactionStatus.pending;
    }
  }

  factory SaharaTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      // Firestore Timestamp
      try {
        return (v as dynamic).toDate() as DateTime;
      } catch (_) {}
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return SaharaTransactionModel(
      id: docId,
      budgetId: map['budgetId'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      type: _typeFromString(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (map['fee'] as num?)?.toDouble(),
      netAmount: (map['netAmount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'TZS',
      status: _statusFromString(map['status'] as String?),
      msisdn: map['msisdn'] as String? ?? '',
      channel: map['channel'] as String? ?? '',
      recipientName: map['recipientName'] as String?,
      depositId: map['depositId'] as String?,
      withdrawalId: map['withdrawalId'] as String?,
      narration: map['narration'] as String?,
      temboTxnId: map['temboTxnId'] as String?,
      createdAt: parseDate(map['createdAt']),
      completedAt: map['completedAt'] != null ? parseDate(map['completedAt']) : null,
    );
  }

  String get typeLabel => type == SaharaTransactionType.deposit ? 'Deposit' : 'Withdrawal';

  String get statusLabel {
    switch (status) {
      case SaharaTransactionStatus.pending:
        return 'Pending';
      case SaharaTransactionStatus.processing:
        return 'Processing';
      case SaharaTransactionStatus.completed:
        return 'Completed';
      case SaharaTransactionStatus.failed:
        return 'Failed';
    }
  }

  bool get isDeposit => type == SaharaTransactionType.deposit;
  bool get isWithdrawal => type == SaharaTransactionType.withdrawal;
  bool get isCompleted => status == SaharaTransactionStatus.completed;
  bool get isFailed => status == SaharaTransactionStatus.failed;
  bool get isPending => status == SaharaTransactionStatus.pending || status == SaharaTransactionStatus.processing;
}

