import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contract_model.dart';

class ContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new contract
  Future<ContractModel> createContract({
    required String userId,
    required String title,
    required String description,
    required double reward,
    required String role,
    required String userFullName,
    required String userPhone,
  }) async {
    try {
      // Create contract data with role-based user information
      final contractData = ContractModel(
        id: _firestore.collection('contracts').doc().id,
        title: title,
        description: description,
        reward: reward,
        status: 'non-active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: role,
        // Assign user information based on role
        benefactorId: role == 'Benefactor' ? userId : null,
        benefactorName: role == 'Benefactor' ? userFullName : null,
        benefactorPhone: role == 'Benefactor' ? userPhone : null,
        beneficiaryId: role == 'Beneficiary' ? userId : null,
        beneficiaryName: role == 'Beneficiary' ? userFullName : null,
        beneficiaryPhone: role == 'Beneficiary' ? userPhone : null,
      );

      // Save to Firestore
      await _firestore
          .collection('contracts')
          .doc(contractData.id)
          .set(contractData.toMap());

      return contractData;
    } catch (e) {
      throw Exception('Failed to create contract: $e');
    }
  }

  // Accept contract invitation
  Future<void> acceptContract({
    required String contractId,
    required String userId,
    required String userFullName,
    required String userPhone,
  }) async {
    try {
      final contractRef = _firestore.collection('contracts').doc(contractId);
      final contractDoc = await contractRef.get();

      if (!contractDoc.exists) {
        throw Exception('Contract not found');
      }

      final contract = ContractModel.fromMap(contractDoc.data()!);

      // Determine which role to assign based on existing role
      final updates = <String, dynamic>{
        'status': 'active',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (contract.role == 'Benefactor') {
        // If creator was Benefactor, assign new user as Beneficiary
        updates.addAll({
          'beneficiaryId': userId,
          'beneficiaryName': userFullName,
          'beneficiaryPhone': userPhone,
        });
      } else {
        // If creator was Beneficiary, assign new user as Benefactor
        updates.addAll({
          'benefactorId': userId,
          'benefactorName': userFullName,
          'benefactorPhone': userPhone,
        });
      }

      await contractRef.update(updates);
    } catch (e) {
      throw Exception('Failed to accept contract: $e');
    }
  }

  // Get authenticated user's contracts
  Stream<List<ContractModel>> getAuthenticatedUserContracts(String userId) {
    return _firestore
        .collection('contracts')
        .where(Filter.or(
          Filter('benefactorId', isEqualTo: userId),
          Filter('beneficiaryId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ContractModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get authenticated user's contracts by status
  Stream<List<ContractModel>> getAuthenticatedUserContractsByStatus(
      String userId, String status) {
    return _firestore
        .collection('contracts')
        .where(Filter.or(
          Filter('benefactorId', isEqualTo: userId),
          Filter('beneficiaryId', isEqualTo: userId),
        ))
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ContractModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get user's role in a contract
  Future<String?> getUserRoleInContract(
      String contractId, String userId) async {
    try {
      final doc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (!doc.exists) return null;

      final contract = ContractModel.fromMap(doc.data()!);
      if (contract.benefactorId == userId) return 'Benefactor';
      if (contract.beneficiaryId == userId) return 'Beneficiary';
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  // Get contract details
  Future<ContractModel?> getContractDetails(String contractId) async {
    try {
      final doc = await _firestore.collection('contracts').doc(contractId).get();
      if (!doc.exists) return null;
      return ContractModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get contract details: $e');
    }
  }
}
