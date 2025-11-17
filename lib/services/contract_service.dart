import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contract_model.dart';
import 'notification.dart';
import 'notification_settings_service.dart';

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
    required String secondParticipantId,
    required String secondParticipantName,
    required String secondParticipantPhone,
  }) async {
    try {
      final contractData = ContractModel(
        id: _firestore.collection('contracts').doc().id,
        title: title,
        description: description,
        reward: reward,
        status: 'non-active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        role: role,
        remitterId: role == 'Remitter' ? userId : secondParticipantId,
        remitterName: role == 'Remitter' ? userFullName : secondParticipantName,
        remitterPhone: role == 'Remitter' ? userPhone : secondParticipantPhone,
        beneficiaryId: role == 'Beneficiary' ? userId : secondParticipantId,
        beneficiaryName:
            role == 'Beneficiary' ? userFullName : secondParticipantName,
        beneficiaryPhone:
            role == 'Beneficiary' ? userPhone : secondParticipantPhone,
      );

      // Save to Firestore
      await _firestore
          .collection('contracts')
          .doc(contractData.id)
          .set(contractData.toMap());

      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(secondParticipantId)
          .get();

      if (receiverDoc.exists) {
        final receiverData = receiverDoc.data();
        final receiverToken = receiverData?['deviceToken'];
        final receiverName = receiverData?['fullName'] ?? 'Unknown';
        
        if (kDebugMode) {
          print('🔍 Sending notification to: $receiverName');
          print('   Token exists: ${receiverToken != null}');
        }

        if (receiverToken != null &&
            receiverToken != 'null' &&
            receiverToken.toString().isNotEmpty) {
          await sendFCMV1Notification(
            fcmToken: receiverToken.toString(),
            title: userFullName,
            body: 'New contract invitation: "${contractData.title}"',
          );
        } else {
          if (kDebugMode) {
            print(
                '⚠️ Cannot send notification - no valid device token found for user');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Receiver user document does not exist');
        }
      }

      return contractData;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw Exception('Failed to create contract: $e');
    }
  }

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
        'status': 'unfunded',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (contract.role == 'Remitter') {
        // If creator was Remitter, assign new user as Beneficiary
        updates.addAll({
          'beneficiaryId': userId,
          'beneficiaryName': userFullName,
          'beneficiaryPhone': userPhone,
        });
      } else {
        // If creator was Beneficiary, assign new user as Remitter
        updates.addAll({
          'remitterId': userId,
          'remitterName': userFullName,
          'remitterPhone': userPhone,
        });
      }

      // Update the contract in Firestore
      await contractRef.update(updates);

      // Send notification to the original contract creator
      final originalCreatorId = contract.role == 'Remitter'
          ? contract.remitterId
          : contract.beneficiaryId;

      if (originalCreatorId != null && originalCreatorId != userId) {
        final creatorDoc =
            await _firestore.collection('users').doc(originalCreatorId).get();

        if (creatorDoc.exists) {
          final creatorToken = creatorDoc.data()?['deviceToken'];
          if (creatorToken != null) {
            await sendFCMV1Notification(
              fcmToken: creatorToken,
              title: userFullName,
              body:
                  '$userFullName has accepted your contract "${contract.title}"',
              notificationType: NotificationType.contractUpdates,
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to accept contract: $e');
    }
  }

  // Get authenticated user's contracts
  Stream<List<ContractModel>> getAuthenticatedUserContracts(String userId) {
    print('🔍 CONTRACT SERVICE: Getting contracts for user: $userId');
    print(
        '🔍 CONTRACT SERVICE: Query: contracts where (remitterId == $userId OR beneficiaryId == $userId) orderBy createdAt desc');

    return _firestore
        .collection('contracts')
        .where(Filter.or(
          Filter('remitterId', isEqualTo: userId),
          Filter('beneficiaryId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ CONTRACT SERVICE STREAM ERROR: $error');
      print('❌ CONTRACT SERVICE ERROR TYPE: ${error.runtimeType}');
      print('❌ CONTRACT SERVICE ERROR DETAILS: ${error.toString()}');
    }).map((snapshot) {
      print(
          '🔍 CONTRACT SERVICE: Snapshot received with ${snapshot.docs.length} documents');
      return snapshot.docs
          .map((doc) => ContractModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get authenticated user's contracts by status
  Stream<List<ContractModel>> getAuthenticatedUserContractsByStatus(
      String userId, String status) {
    print(
        '🔍 CONTRACT SERVICE: Getting contracts for user: $userId with status: $status');
    print(
        '🔍 CONTRACT SERVICE: Query: contracts where (remitterId == $userId OR beneficiaryId == $userId) AND status == $status orderBy createdAt desc');

    return _firestore
        .collection('contracts')
        .where(Filter.or(
          Filter('remitterId', isEqualTo: userId),
          Filter('beneficiaryId', isEqualTo: userId),
        ))
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ CONTRACT SERVICE STATUS STREAM ERROR: $error');
      print('❌ CONTRACT SERVICE STATUS ERROR TYPE: ${error.runtimeType}');
      print('❌ CONTRACT SERVICE STATUS ERROR DETAILS: ${error.toString()}');
    }).map((snapshot) {
      print(
          '🔍 CONTRACT SERVICE: Status snapshot received with ${snapshot.docs.length} documents');
      return snapshot.docs
          .map((doc) => ContractModel.fromMap(doc.data()))
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
      if (contract.remitterId == userId) return 'Remitter';
      if (contract.beneficiaryId == userId) return 'Beneficiary';
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  // Get contract details
  Future<ContractModel?> getContractDetails(String contractId) async {
    try {
      final doc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (!doc.exists) return null;
      return ContractModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get contract details: $e');
    }
  }

  // Delete contract
  Future<void> deleteContract(String contractId) async {
    try {
      await _firestore.collection('contracts').doc(contractId).delete();
    } catch (e) {
      throw Exception('Failed to delete contract: $e');
    }
  }

  // Update contract status
  Future<void> updateContractStatus(
    String contractId,
    String newStatus, {
    String? currentUserName,
  }) async {
    try {
      final contractDoc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (!contractDoc.exists) {
        throw Exception('Contract not found');
      }

      final contract = ContractModel.fromMap(contractDoc.data()!);

      await _firestore.collection('contracts').doc(contractId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Determine who to notify based on the status change
      String? receiverId;
      String notificationTitle;
      String notificationBody;

      // Use current user's name as the sender
      final senderName = currentUserName ?? 'Someone';

      switch (newStatus) {
        case 'active':
          receiverId = contract.beneficiaryId;
          notificationTitle = senderName;
          notificationBody =
              '$senderName has funded your contract "${contract.title}" and it is now active.';
          break;
        case 'withdraw':
          receiverId = contract.remitterId;
          notificationTitle = senderName;
          notificationBody =
              '$senderName has requested a withdrawal for contract "${contract.title}".';
          break;
        case 'completed':
          receiverId = contract.remitterId;
          notificationTitle = senderName;
          notificationBody =
              '$senderName has marked contract "${contract.title}" as completed.';
          break;
        case 'terminated':
          receiverId = contract.beneficiaryId;
          notificationTitle = senderName;
          notificationBody =
              '$senderName has terminated contract "${contract.title}".';
          break;
        case 'closed':
          receiverId = contract.remitterId;
          notificationTitle = senderName;
          notificationBody =
              '$senderName has closed contract "${contract.title}".';
          break;
        default:
          return;
      }

      if (receiverId != null) {
        final receiverDoc =
            await _firestore.collection('users').doc(receiverId).get();
        if (receiverDoc.exists) {
          final receiverToken = receiverDoc.data()?['deviceToken'];
          if (receiverToken != null) {
            await sendFCMV1Notification(
              fcmToken: receiverToken,
              title: notificationTitle,
              body: notificationBody,
              notificationType: NotificationType.contractUpdates,
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update contract status: $e');
    }
  }

  // Terminate contract
  Future<void> terminateContract(
    String contractId, {
    String? terminationReason,
    String? currentUserName,
  }) async {
    try {
      final updates = {
        'status': 'terminated',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (terminationReason != null && terminationReason.isNotEmpty) {
        updates['terminationReason'] = terminationReason;
      }

      await _firestore.collection('contracts').doc(contractId).update(updates);

      // Send notification
      final contractDoc =
          await _firestore.collection('contracts').doc(contractId).get();
      if (contractDoc.exists) {
        final contract = ContractModel.fromMap(contractDoc.data()!);
        final receiverId = contract.beneficiaryId;

        if (receiverId != null) {
          final receiverDoc =
              await _firestore.collection('users').doc(receiverId).get();
          if (receiverDoc.exists) {
            final receiverToken = receiverDoc.data()?['deviceToken'];
            if (receiverToken != null) {
              final senderName = currentUserName ?? 'Someone';
              await sendFCMV1Notification(
                fcmToken: receiverToken,
                title: senderName,
                body:
                    '$senderName has terminated contract "${contract.title}". Please review the termination reason.',
                notificationType: NotificationType.contractUpdates,
              );
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to terminate contract: $e');
    }
  }

  // Request withdrawal
  Future<void> requestWithdrawal(String contractId,
      {String? currentUserName}) async {
    await updateContractStatus(contractId, 'withdraw',
        currentUserName: currentUserName);
  }

  // Confirm withdrawal
  Future<void> confirmWithdrawal(String contractId,
      {String? currentUserName}) async {
    await updateContractStatus(contractId, 'completed',
        currentUserName: currentUserName);
  }

  // Decline withdrawal request
  Future<void> declineWithdrawal(String contractId,
      {String? currentUserName}) async {
    await updateContractStatus(contractId, 'active',
        currentUserName: currentUserName);
  }

  // Approve termination
  Future<void> approveTermination(String contractId,
      {String? currentUserName}) async {
    await updateContractStatus(contractId, 'closed',
        currentUserName: currentUserName);
  }

  // Close contract
  Future<void> closeContract(String contractId,
      {String? currentUserName}) async {
    await updateContractStatus(contractId, 'closed',
        currentUserName: currentUserName);
  }
}
