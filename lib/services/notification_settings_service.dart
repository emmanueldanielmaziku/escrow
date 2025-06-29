import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _contractUpdatesKey = 'contract_updates_enabled';
  static const String _paymentNotificationsKey =
      'payment_notifications_enabled';
  static const String _systemNotificationsKey = 'system_notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  // Default settings
  static const bool _defaultNotificationsEnabled = true;
  static const bool _defaultContractUpdates = true;
  static const bool _defaultPaymentNotifications = true;
  static const bool _defaultSystemNotifications = true;
  static const bool _defaultSoundEnabled = true;
  static const bool _defaultVibrationEnabled = true;

  // Get notification settings
  static Future<NotificationSettings> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return NotificationSettings(
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ??
          _defaultNotificationsEnabled,
      contractUpdates:
          prefs.getBool(_contractUpdatesKey) ?? _defaultContractUpdates,
      paymentNotifications: prefs.getBool(_paymentNotificationsKey) ??
          _defaultPaymentNotifications,
      systemNotifications:
          prefs.getBool(_systemNotificationsKey) ?? _defaultSystemNotifications,
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? _defaultSoundEnabled,
      vibrationEnabled:
          prefs.getBool(_vibrationEnabledKey) ?? _defaultVibrationEnabled,
    );
  }

  // Update notification settings
  static Future<void> updateNotificationSettings(
      NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        _notificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setBool(_contractUpdatesKey, settings.contractUpdates);
    await prefs.setBool(
        _paymentNotificationsKey, settings.paymentNotifications);
    await prefs.setBool(_systemNotificationsKey, settings.systemNotifications);
    await prefs.setBool(_soundEnabledKey, settings.soundEnabled);
    await prefs.setBool(_vibrationEnabledKey, settings.vibrationEnabled);

    // Update Firebase Messaging token based on main notification setting
    if (settings.notificationsEnabled) {
      await _enableNotifications();
    } else {
      await _disableNotifications();
    }
  }

  // Enable notifications
  static Future<void> _enableNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
          print('🔔 Notifications enabled. FCM Token: $token');
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) async {
          await _saveTokenToFirestore(newToken);
          print('🔄 FCM Token refreshed: $newToken');
        });
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error enabling notifications: $e');
    }
  }

  // Save token to Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'deviceToken': token,
          'lastTokenUpdate': DateTime.now().toIso8601String(),
        });
        print('💾 FCM Token saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  // Disable notifications
  static Future<void> _disableNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Delete FCM token
      await messaging.deleteToken();

      // Remove token from Firestore
      await _removeTokenFromFirestore();

      print('🔕 Notifications disabled');
    } catch (e) {
      print('❌ Error disabling notifications: $e');
    }
  }

  // Remove token from Firestore
  static Future<void> _removeTokenFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'deviceToken': null,
          'lastTokenUpdate': DateTime.now().toIso8601String(),
        });
        print('🗑️ FCM Token removed from Firestore for user: ${user.uid}');
      }
    } catch (e) {
      print('❌ Error removing FCM token from Firestore: $e');
    }
  }

  // Initialize FCM token management (call this on app startup)
  static Future<void> initializeTokenManagement() async {
    try {
      final settings = await getNotificationSettings();
      if (settings.notificationsEnabled) {
        await _enableNotifications();
      }
    } catch (e) {
      print('❌ Error initializing token management: $e');
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.notificationsEnabled;
  }

  // Check if specific notification type is enabled
  static Future<bool> isNotificationTypeEnabled(NotificationType type) async {
    final settings = await getNotificationSettings();

    if (!settings.notificationsEnabled) return false;

    switch (type) {
      case NotificationType.contractUpdates:
        return settings.contractUpdates;
      case NotificationType.paymentNotifications:
        return settings.paymentNotifications;
      case NotificationType.systemNotifications:
        return settings.systemNotifications;
    }
  }

  // Reset to default settings
  static Future<void> resetToDefaults() async {
    final defaultSettings = NotificationSettings(
      notificationsEnabled: _defaultNotificationsEnabled,
      contractUpdates: _defaultContractUpdates,
      paymentNotifications: _defaultPaymentNotifications,
      systemNotifications: _defaultSystemNotifications,
      soundEnabled: _defaultSoundEnabled,
      vibrationEnabled: _defaultVibrationEnabled,
    );

    await updateNotificationSettings(defaultSettings);
  }
}

// Notification settings model
class NotificationSettings {
  final bool notificationsEnabled;
  final bool contractUpdates;
  final bool paymentNotifications;
  final bool systemNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationSettings({
    required this.notificationsEnabled,
    required this.contractUpdates,
    required this.paymentNotifications,
    required this.systemNotifications,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? contractUpdates,
    bool? paymentNotifications,
    bool? systemNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      contractUpdates: contractUpdates ?? this.contractUpdates,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

// Notification types enum
enum NotificationType {
  contractUpdates,
  paymentNotifications,
  systemNotifications,
}
