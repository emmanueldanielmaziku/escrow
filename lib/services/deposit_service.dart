import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deposit_model.dart';

class DepositService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DepositModel> createDeposit({
    required String contractId,
    required String userId,
    required String contractFund,
    required String provider,
    required String channel,
    required String paymentMessage,
  }) async {
    try {
      final depositData = DepositModel(
        id: _firestore.collection('deposits').doc().id,
        contractId: contractId,
        userId: userId,
        provider: provider,
        contractFund: contractFund,
        channel: channel,
        paymentMessage: paymentMessage,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('deposits')
          .doc(depositData.id)
          .set(depositData.toMap());

      return depositData;
    } catch (e) {
      throw Exception('Failed to create deposit: $e');
    }
  }

  Stream<List<DepositModel>> getContractDeposits(String contractId) {
    return _firestore
        .collection('deposits')
        .where('contractId', isEqualTo: contractId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DepositModel.fromMap(doc.data()))
          .toList();
    });
  }
}
