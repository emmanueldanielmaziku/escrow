import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/budget_contract_model.dart';
import 'notification.dart';

class BudgetContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new budget contract
  Future<BudgetContractModel> createBudgetContract({
    required String userId,
    required String title,
    required String description,
    required double amount,
    required ContractType contractType,
    required String userFullName,
    required String userPhone,
    required String secondParticipantId,
    required String secondParticipantName,
    required String secondParticipantPhone,
    Duration? contractTerm,
  }) async {
    try {
      DateTime? contractEndDate;
      if (contractType == ContractType.nonNegotiable && contractTerm != null) {
        contractEndDate = DateTime.now().add(contractTerm);
      }

      final budgetContract = BudgetContractModel(
        id: _firestore.collection('budget_contracts').doc().id,
        title: title,
        description: description,
        amount: amount,
        fundedAmount: 0.0,
        contractType: contractType,
        status: BudgetContractStatus.unfunded,
        createdAt: DateTime.now(),
        contractEndDate: contractEndDate,
        contractTerm: contractTerm,
        remitterId: userId,
        remitterName: userFullName,
        beneficiaryId: secondParticipantId,
        beneficiaryName: secondParticipantName,
      );

      // Save to Firestore
      await _firestore
          .collection('budget_contracts')
          .doc(budgetContract.id)
          .set(budgetContract.toMap());

      // Send notification to the second participant
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(secondParticipantId)
          .get();

      if (receiverDoc.exists) {
        final receiverData = receiverDoc.data();
        final receiverToken = receiverData?['deviceToken'];
        final receiverName = receiverData?['fullName'] ?? 'Unknown';

        if (kDebugMode) {
          print('🔍 Sending budget contract notification to: $receiverName');
        }

        if (receiverToken != null &&
            receiverToken != 'null' &&
            receiverToken.toString().isNotEmpty) {
          await sendFCMV1Notification(
            fcmToken: receiverToken.toString(),
            title: userFullName,
            body: 'New budget contract: "${budgetContract.title}"',
          );
        }
      }

      return budgetContract;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating budget contract: $e');
      }
      throw Exception('Failed to create budget contract: $e');
    }
  }

  // Get authenticated user's budget contracts
  Stream<List<BudgetContractModel>> getAuthenticatedUserBudgetContracts(
      String userId) {
    return _firestore
        .collection('budget_contracts')
        .where(Filter.or(
          Filter('remitterId', isEqualTo: userId),
          Filter('beneficiaryId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetContractModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get budget contract details
  Future<BudgetContractModel?> getBudgetContractDetails(
      String contractId) async {
    try {
      final doc =
          await _firestore.collection('budget_contracts').doc(contractId).get();
      if (!doc.exists) return null;
      return BudgetContractModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get budget contract details: $e');
    }
  }

  // Update budget contract status
  Future<void> updateBudgetContractStatus(
    String contractId,
    BudgetContractStatus newStatus,
  ) async {
    try {
      await _firestore.collection('budget_contracts').doc(contractId).update({
        'status': newStatus.name,
      });
    } catch (e) {
      throw Exception('Failed to update budget contract status: $e');
    }
  }

  // Add funds to budget contract
  Future<void> addFunds(String contractId, double amount) async {
    try {
      final doc =
          await _firestore.collection('budget_contracts').doc(contractId).get();
      if (!doc.exists) {
        throw Exception('Budget contract not found');
      }

      final currentData = doc.data()!;
      final currentFunded = (currentData['fundedAmount'] as num?)?.toDouble() ?? 0.0;
      final newFunded = currentFunded + amount;
      final totalAmount = (currentData['amount'] as num).toDouble();

      // Update funded amount and status if fully funded
      final updates = <String, dynamic>{
        'fundedAmount': newFunded,
      };

      if (newFunded >= totalAmount) {
        updates['status'] = BudgetContractStatus.active.name;
      }

      await _firestore.collection('budget_contracts').doc(contractId).update(updates);
    } catch (e) {
      throw Exception('Failed to add funds: $e');
    }
  }
}

