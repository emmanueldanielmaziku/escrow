import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/budget_contract_model.dart';

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
    Duration?
        contractTerm, // Contract term: when contract can be closed (for non-negotiable contracts)
  }) async {
    try {
      DateTime? contractEndDate;
      // For non-negotiable contracts, use contractTerm to calculate when contract can be closed
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
        ownerId: userId,
        ownerName: userFullName,
      );

      // Save to Firestore
      await _firestore
          .collection('budget_contracts')
          .doc(budgetContract.id)
          .set(budgetContract.toMap());

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
    if (kDebugMode) {
      print('🔍 BUDGET SERVICE: Getting budget contracts for user: $userId');
      print(
          '🔍 BUDGET SERVICE: Query: budget_contracts where ownerId == $userId orderBy createdAt desc');
    }

    return _firestore
        .collection('budget_contracts')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      if (kDebugMode) {
        print('❌ BUDGET SERVICE STREAM ERROR: $error');
        print('❌ BUDGET SERVICE ERROR TYPE: ${error.runtimeType}');
        print('❌ BUDGET SERVICE ERROR DETAILS: ${error.toString()}');

        // Check if it's an index error
        if (error.toString().contains('index') ||
            error.toString().contains('indexes')) {
          print('⚠️ BUDGET SERVICE: Firebase index required!');
          print(
              '⚠️ Create composite index: budget_contracts (ownerId, createdAt)');
        }
      }
    }).map((snapshot) {
      if (kDebugMode) {
        print(
            '🔍 BUDGET SERVICE: Snapshot received with ${snapshot.docs.length} documents');
      }

      final contracts = snapshot.docs
          .map((doc) {
            try {
              return BudgetContractModel.fromMap(doc.data());
            } catch (e) {
              if (kDebugMode) {
                print('❌ BUDGET SERVICE: Error parsing document ${doc.id}: $e');
              }
              return null;
            }
          })
          .whereType<BudgetContractModel>()
          .toList();

      if (kDebugMode) {
        print(
            '🔍 BUDGET SERVICE: Successfully parsed ${contracts.length} budget contracts');
      }

      return contracts;
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
      final currentFunded =
          (currentData['fundedAmount'] as num?)?.toDouble() ?? 0.0;
      final newFunded = currentFunded + amount;
      final totalAmount = (currentData['amount'] as num).toDouble();

      // Update funded amount and status if fully funded
      final updates = <String, dynamic>{
        'fundedAmount': newFunded,
      };

      if (newFunded >= totalAmount) {
        updates['status'] = BudgetContractStatus.active.name;
      }

      await _firestore
          .collection('budget_contracts')
          .doc(contractId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to add funds: $e');
    }
  }

  // Delete budget contract
  Future<void> deleteBudgetContract(String contractId) async {
    try {
      await _firestore.collection('budget_contracts').doc(contractId).delete();
      if (kDebugMode) {
        print(
            '✅ BUDGET SERVICE: Successfully deleted budget contract: $contractId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ BUDGET SERVICE: Error deleting budget contract: $e');
      }
      throw Exception('Failed to delete budget contract: $e');
    }
  }
}
