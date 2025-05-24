class AppConstants {
  // Contract Status
  static const String dormant = 'dormant';
  static const String notFunded = 'not_funded';
  static const String awaitingAdminApproval = 'awaiting_admin_approval';
  static const String active = 'active';
  static const String closed = 'closed';
  static const String terminated = 'terminated';
  static const String declined = 'declined';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String contractsCollection = 'contracts';

  // App Constants
  static const String appName = 'Escrow';
  static const String appTagline = 'Secure Contracts Made Simple';
  static const String appDescription = 'Create and manage secure escrow contracts with ease.';
  
  // Shared Preferences Keys
  static const String userIdKey = 'userId';
  static const String userPhoneKey = 'userPhone';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String isOnboardingCompletedKey = 'isOnboardingCompleted';
  
  // Error Messages
  static const String networkErrorMsg = 'Network error, please check your connection';
  static const String authErrorMsg = 'Authentication failed';
  static const String generalErrorMsg = 'Something went wrong, please try again';
  
  // Success Messages
  static const String loginSuccessMsg = 'Login successful';
  static const String registerSuccessMsg = 'Registration successful';
  static const String contractCreatedMsg = 'Contract created successfully';
  static const String contractAcceptedMsg = 'Contract accepted successfully';
  static const String contractDeclinedMsg = 'Contract declined';
  static const String paymentUploadedMsg = 'Payment proof uploaded successfully';
  static const String withdrawalRequestedMsg = 'Withdrawal requested successfully';
  static const String withdrawalConfirmedMsg = 'Withdrawal confirmed, funds released';
  
  // WhatsApp Invite Template
  static String generateInviteMessage({
    required String title,
    required double amount,
    required String contractId,
  }) {
    return '''You've been invited to join a contract agreement on Escrow.
Title: $title
Amount: $amount TSh
Tap to view & accept: https://escrow.app/invite/$contractId''';
  }
}
