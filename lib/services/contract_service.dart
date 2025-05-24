import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/contract_model.dart';
import '../utils/constants.dart';

class ContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Create a new contract
  Future<String> createContract({
    required String title,
    required String description,
    required double amount,
    required String creatorId,
    required String inviteeId,
  }) async {
    try {
      final contractId = _uuid.v4();
      final contractData = {
        'id': contractId,
        'title': title,
        'description': description,
        'amount': amount,
        'status': AppConstants.dormant,
        'creatorId': creatorId,
        'inviteeId': inviteeId,
        'createdAt': Timestamp.now(),
        'withdrawalRequested': false,
        'userAConfirmed': false,
      };

      // Create the contract document
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .set(contractData);

      // Update user stats in a separate try-catch to prevent contract creation failure
      try {
        // Update creator's total contracts
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(creatorId)
            .update({'totalContracts': FieldValue.increment(1)});

        // Update invitee's total invitations
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(inviteeId)
            .update({'totalInvitations': FieldValue.increment(1)});
      } catch (e) {
        // Log the error but don't fail the contract creation
        print('Error updating user stats: $e');
      }

      return contractId;
    } catch (e) {
      rethrow;
    }
  }

  // Get all contracts for a user (as creator or invitee)
  Stream<List<ContractModel>> getUserContracts(String userId) {
    return _firestore
        .collection(AppConstants.contractsCollection)
        .where(Filter.or(
          Filter('creatorId', isEqualTo: userId),
          Filter('inviteeId', isEqualTo: userId),
        ))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  // Get user invitations (contracts where user is invitee and status is dormant)
  Stream<List<ContractModel>> getUserInvitations(String userId) {
    return _firestore
        .collection(AppConstants.contractsCollection)
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.dormant)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractModel.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  // Get a single contract by ID
  Future<ContractModel?> getContractById(String contractId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .get();
      if (doc.exists) {
        return ContractModel.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Accept contract invitation
  Future<void> acceptContract(String contractId) async {
    try {
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'status': AppConstants.notFunded,
        'acceptedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Decline contract invitation
  Future<void> declineContract(String contractId) async {
    try {
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'status': AppConstants.declined,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Upload payment proof
  Future<String> uploadPaymentProof(String contractId, File imageFile) async {
    try {
      final ref = _storage.ref().child('payment_proofs/$contractId.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'proofOfPaymentUrl': downloadUrl,
        'status': AppConstants.awaitingAdminApproval,
      });

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Submit receipt number
  Future<void> submitReceiptNumber(
      String contractId, String receiptNumber) async {
    try {
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'receiptNumber': receiptNumber,
        'status': AppConstants.awaitingAdminApproval,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Admin approve payment (simulated for MVP)
  Future<void> approvePayment(String contractId) async {
    try {
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'status': AppConstants.active,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Request withdrawal
  Future<void> requestWithdrawal(String contractId) async {
    try {
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'withdrawalRequested': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Confirm withdrawal
  Future<void> confirmWithdrawal(
      String contractId, double amount, String inviteeId) async {
    try {
      // Update contract status
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'status': AppConstants.closed,
        'userAConfirmed': true,
      });

      // Update invitee's wallet balance
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(inviteeId)
          .update({
        'balance': FieldValue.increment(amount),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Decline withdrawal
  Future<void> declineWithdrawal(String contractId) async {
    try {
      await _firestore
          .collection(AppConstants.contractsCollection)
          .doc(contractId)
          .update({
        'status': AppConstants.terminated,
        'withdrawalRequested': false,
      });
    } catch (e) {
      rethrow;
    }
  }
}
