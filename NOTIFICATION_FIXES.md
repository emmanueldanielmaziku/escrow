# FCM Notification Fixes

## Problem Identified

The app was experiencing 404 "UNREGISTERED" errors when sending FCM notifications. This typically occurs when:

- FCM tokens are invalid or expired
- Tokens are not properly saved to Firestore
- Token refresh is not handled
- Invalid tokens are not cleaned up

## Root Causes

1. **Token Management**: FCM tokens were not being properly saved to Firestore during login/registration
2. **Token Refresh**: No handling of token refresh events
3. **Invalid Token Cleanup**: No mechanism to remove invalid tokens from Firestore
4. **Permission Handling**: Inconsistent permission requests and token management

## Fixes Implemented

### 1. Enhanced Notification Settings Service

- **File**: `lib/services/notification_settings_service.dart`
- **Improvements**:
  - Added proper FCM token saving to Firestore
  - Implemented token refresh listening
  - Added token removal when notifications are disabled
  - Added initialization method for app startup
  - Better error handling and logging

### 2. Updated Main App Initialization

- **File**: `lib/main.dart`
- **Improvements**:
  - Integrated notification settings service initialization
  - Better permission handling
  - Proper token management on app startup

### 3. Enhanced Auth Service

- **File**: `lib/services/auth_service.dart`
- **Improvements**:
  - Removed manual FCM token handling (now handled by notification service)
  - Added notification service initialization after login/registration
  - Cleaner separation of concerns

### 4. Improved Notification Service

- **File**: `lib/services/notification.dart`
- **Improvements**:
  - Added token validation before sending
  - Implemented invalid token cleanup
  - Better error handling for UNREGISTERED errors
  - Automatic removal of invalid tokens from Firestore

### 5. Android Notification Icon

- **File**: `android/app/src/main/res/drawable/ic_stat_notify.png`
- **Status**: ✅ Already exists and properly configured

## Key Features Added

### Token Management

```dart
// Save token to Firestore
await _saveTokenToFirestore(token);

// Listen for token refresh
messaging.onTokenRefresh.listen((newToken) async {
  await _saveTokenToFirestore(newToken);
});

// Remove invalid tokens
await _removeInvalidToken(fcmToken);
```

### Notification Settings Integration

```dart
// Initialize on app startup
await NotificationSettingsService.initializeTokenManagement();

// Check if notifications are enabled for specific types
final isEnabled = await NotificationSettingsService.isNotificationTypeEnabled(
  NotificationType.contractUpdates,
);
```

### Error Handling

```dart
// Handle UNREGISTERED errors
if (response.statusCode == 404) {
  final responseBody = jsonDecode(response.body);
  if (responseBody['error']?['details']?[0]?['errorCode'] == 'UNREGISTERED') {
    await _removeInvalidToken(fcmToken);
  }
}
```

## Testing

- Created comprehensive tests for notification settings service
- All tests pass successfully
- Core functionality verified

## Usage Instructions

### For Users

1. Go to Profile → Settings → Notifications
2. Toggle notification preferences
3. Settings are automatically saved and applied

### For Developers

1. FCM tokens are automatically managed
2. Invalid tokens are automatically cleaned up
3. Token refresh is handled automatically
4. All notification calls respect user preferences

## Expected Results

- ✅ No more 404 UNREGISTERED errors
- ✅ Notifications work reliably
- ✅ Invalid tokens are automatically cleaned up
- ✅ Token refresh is handled properly
- ✅ User preferences are respected
- ✅ Better error handling and logging

## Monitoring

The system now includes comprehensive logging:

- `🔔 Notifications enabled. FCM Token: [token]`
- `🔄 FCM Token refreshed: [token]`
- `💾 FCM Token saved to Firestore for user: [uid]`
- `🗑️ Removed invalid FCM token for user: [uid]`
- `❌ FCM Token is unregistered. User may have uninstalled the app or token expired.`
