import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sahara_transaction_model.dart';

/// Reads sahara transaction records from Firestore (written by the backend).
class SaharaTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Real-time stream of all transactions for a given sahara (newest first).
  Stream<List<SaharaTransactionModel>> getSaharaTransactions(String budgetId) {
    return _firestore
        .collection('budget_transactions')
        .where('budgetId', isEqualTo: budgetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SaharaTransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetch all transactions for a user across all their sahara contracts.
  Stream<List<SaharaTransactionModel>> getUserSaharaTransactions(String ownerId) {
    return _firestore
        .collection('budget_transactions')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SaharaTransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// One-time fetch for the latest deposit or withdrawal for a sahara contract.
  Future<SaharaTransactionModel?> getLatestTransaction(String budgetId) async {
    final snap = await _firestore
        .collection('budget_transactions')
        .where('budgetId', isEqualTo: budgetId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return SaharaTransactionModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Poll until a specific transaction (by depositId or withdrawalId) reaches a terminal status.
  Future<SaharaTransactionModel?> pollTransactionStatus({
    required String budgetId,
    required String transactionId,
    required bool isDeposit,
    Duration timeout = const Duration(seconds: 90),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final field = isDeposit ? 'depositId' : 'withdrawalId';
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final snap = await _firestore
          .collection('budget_transactions')
          .where('budgetId', isEqualTo: budgetId)
          .where(field, isEqualTo: transactionId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final tx = SaharaTransactionModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
        if (tx.status == SaharaTransactionStatus.completed ||
            tx.status == SaharaTransactionStatus.failed) {
          return tx;
        }
      }

      await Future.delayed(interval);
    }

    return null; // timeout
  }
}

