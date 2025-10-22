class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://maipay-dmrtw.ondigitalocean.app';

  // Collections
  static const String usersCollection = 'users';
  static const String contractsCollection = 'contracts';
  static const String depositsCollection = 'deposits';

  // Contract Status
  static const String dormant = 'dormant';
  static const String notFunded = 'not_funded';
  static const String active = 'active';
  static const String completed = 'completed';
  static const String rejected = 'rejected';
  static const String closed = 'closed';
  static const String terminated = 'terminated';

  // Messages
  static const String contractAcceptedMsg = 'Contract accepted successfully';
  static const String contractDeclinedMsg = 'Contract declined';
  static const String contractCompletedMsg = 'Task marked as completed';
  static const String contractConfirmedMsg = 'Task completion confirmed';
  static const String contractRejectedMsg = 'Task completion rejected';
  static const String contractUpdatedMsg = 'Contract status updated';
  static const String paymentUploadedMsg =
      'Payment proof uploaded successfully';
  static const String insufficientBalanceMsg =
      'Insufficient balance. Please recharge your account.';
  static const String depositPendingMsg =
      'Deposit request submitted. Waiting for admin approval.';
  static const String depositApprovedMsg = 'Deposit approved. Balance updated.';
  static const String depositRejectedMsg =
      'Deposit rejected. Please contact support.';


  static String generateInviteMessage({
    required String title,
    required double amount,
    required String contractId,
  }) {
    return '''
🎉 New Contract Invitation

Title: $title
Amount: TSh ${amount.toStringAsFixed(2)}

Please log in to your Escrow App to review and accept this contract.

Contract ID: $contractId
''';
  }
}
