import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sahara_contract_model.dart';

class SaharaContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new sahara contract
  Future<SaharaContractModel> createSaharaContract({
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

      final saharaContract = SaharaContractModel(
        id: _firestore.collection('budget_contracts').doc().id,
        title: title,
        description: description,
        amount: amount,
        fundedAmount: 0.0,
        contractType: contractType,
        status: SaharaContractStatus.unfunded,
        createdAt: DateTime.now(),
        contractEndDate: contractEndDate,
        ownerId: userId,
        ownerName: userFullName,
      );

      // Save to Firestore
      await _firestore
          .collection('budget_contracts')
          .doc(saharaContract.id)
          .set(saharaContract.toMap());

      return saharaContract;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating sahara contract: $e');
      }
      throw Exception('Failed to create sahara contract: $e');
    }
  }

  // Get authenticated user's sahara contracts
  Stream<List<SaharaContractModel>> getAuthenticatedUserSaharaContracts(
      String userId) {
    if (kDebugMode) {
      print('🔍 SAHARA SERVICE: Getting sahara contracts for user: $userId');
      print(
          '🔍 SAHARA SERVICE: Query: budget_contracts where ownerId == $userId orderBy createdAt desc');
    }

    return _firestore
        .collection('budget_contracts')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      if (kDebugMode) {
        print('❌ SAHARA SERVICE STREAM ERROR: $error');
        print('❌ SAHARA SERVICE ERROR TYPE: ${error.runtimeType}');
        print('❌ SAHARA SERVICE ERROR DETAILS: ${error.toString()}');

        // Check if it's an index error
        if (error.toString().contains('index') ||
            error.toString().contains('indexes')) {
          print('⚠️ SAHARA SERVICE: Firebase index required!');
          print(
              '⚠️ Create composite index: budget_contracts (ownerId, createdAt)');
        }
      }
    }).map((snapshot) {
      if (kDebugMode) {
        print(
            '🔍 SAHARA SERVICE: Snapshot received with ${snapshot.docs.length} documents');
      }

      final contracts = snapshot.docs
          .map((doc) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] ??= doc.id; // ensure id is set when missing from payload
              return SaharaContractModel.fromMap(data);
            } catch (e) {
              if (kDebugMode) {
                print('❌ SAHARA SERVICE: Error parsing document ${doc.id}: $e');
              }
              return null;
            }
          })
          .whereType<SaharaContractModel>()
          .toList();

      if (kDebugMode) {
        print(
            '🔍 SAHARA SERVICE: Successfully parsed ${contracts.length} sahara contracts');
      }

      return contracts;
    });
  }

  // Get sahara contract details
  Future<SaharaContractModel?> getSaharaContractDetails(
      String contractId) async {
    try {
      final doc =
          await _firestore.collection('budget_contracts').doc(contractId).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] ??= doc.id;
      return SaharaContractModel.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get sahara contract details: $e');
    }
  }

  // Update sahara contract status
  Future<void> updateSaharaContractStatus(
    String contractId,
    SaharaContractStatus newStatus,
  ) async {
    try {
      await _firestore.collection('budget_contracts').doc(contractId).update({
        'status': newStatus.name,
      });
    } catch (e) {
      throw Exception('Failed to update sahara contract status: $e');
    }
  }

  // Add funds to sahara contract
  Future<void> addFunds(String contractId, double amount) async {
    try {
      final doc =
          await _firestore.collection('budget_contracts').doc(contractId).get();
      if (!doc.exists) {
        throw Exception('Sahara contract not found');
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
        updates['status'] = SaharaContractStatus.active.name;
      }

      await _firestore
          .collection('budget_contracts')
          .doc(contractId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to add funds: $e');
    }
  }

  // Delete sahara contract
  Future<void> deleteSaharaContract(String contractId) async {
    try {
      await _firestore.collection('budget_contracts').doc(contractId).delete();
      if (kDebugMode) {
        print(
            '✅ SAHARA SERVICE: Successfully deleted sahara contract: $contractId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SAHARA SERVICE: Error deleting sahara contract: $e');
      }
      throw Exception('Failed to delete sahara contract: $e');
    }
  }
}
