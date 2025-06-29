import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:escrow_app/services/notification_settings_service.dart';

void main() {
  group('NotificationSettingsService Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should return default settings when no settings are saved', () async {
      final settings =
          await NotificationSettingsService.getNotificationSettings();

      expect(settings.notificationsEnabled, true);
      expect(settings.contractUpdates, true);
      expect(settings.paymentNotifications, true);
      expect(settings.systemNotifications, true);
      expect(settings.soundEnabled, true);
      expect(settings.vibrationEnabled, true);
    });

    test('should save and retrieve custom settings', () async {
      final customSettings = NotificationSettings(
        notificationsEnabled: false,
        contractUpdates: true,
        paymentNotifications: false,
        systemNotifications: true,
        soundEnabled: false,
        vibrationEnabled: true,
      );

      await NotificationSettingsService.updateNotificationSettings(
          customSettings);

      final retrievedSettings =
          await NotificationSettingsService.getNotificationSettings();

      expect(retrievedSettings.notificationsEnabled, false);
      expect(retrievedSettings.contractUpdates, true);
      expect(retrievedSettings.paymentNotifications, false);
      expect(retrievedSettings.systemNotifications, true);
      expect(retrievedSettings.soundEnabled, false);
      expect(retrievedSettings.vibrationEnabled, true);
    });

    test('should reset to default settings', () async {
      // First set custom settings
      final customSettings = NotificationSettings(
        notificationsEnabled: false,
        contractUpdates: false,
        paymentNotifications: false,
        systemNotifications: false,
        soundEnabled: false,
        vibrationEnabled: false,
      );

      await NotificationSettingsService.updateNotificationSettings(
          customSettings);

      // Then reset to defaults
      await NotificationSettingsService.resetToDefaults();

      final settings =
          await NotificationSettingsService.getNotificationSettings();

      expect(settings.notificationsEnabled, true);
      expect(settings.contractUpdates, true);
      expect(settings.paymentNotifications, true);
      expect(settings.systemNotifications, true);
      expect(settings.soundEnabled, true);
      expect(settings.vibrationEnabled, true);
    });

    test('should check notification type enabled correctly', () async {
      // Set notifications enabled but contract updates disabled
      final settings = NotificationSettings(
        notificationsEnabled: true,
        contractUpdates: false,
        paymentNotifications: true,
        systemNotifications: true,
        soundEnabled: true,
        vibrationEnabled: true,
      );

      await NotificationSettingsService.updateNotificationSettings(settings);

      // Test contract updates (should be false)
      final contractUpdatesEnabled =
          await NotificationSettingsService.isNotificationTypeEnabled(
        NotificationType.contractUpdates,
      );
      expect(contractUpdatesEnabled, false);

      // Test payment notifications (should be true)
      final paymentNotificationsEnabled =
          await NotificationSettingsService.isNotificationTypeEnabled(
        NotificationType.paymentNotifications,
      );
      expect(paymentNotificationsEnabled, true);
    });

    test(
        'should return false for all notification types when main toggle is off',
        () async {
      // Set main notifications to disabled
      final settings = NotificationSettings(
        notificationsEnabled: false,
        contractUpdates: true,
        paymentNotifications: true,
        systemNotifications: true,
        soundEnabled: true,
        vibrationEnabled: true,
      );

      await NotificationSettingsService.updateNotificationSettings(settings);

      // All notification types should return false when main toggle is off
      final contractUpdatesEnabled =
          await NotificationSettingsService.isNotificationTypeEnabled(
        NotificationType.contractUpdates,
      );
      expect(contractUpdatesEnabled, false);

      final paymentNotificationsEnabled =
          await NotificationSettingsService.isNotificationTypeEnabled(
        NotificationType.paymentNotifications,
      );
      expect(paymentNotificationsEnabled, false);

      final systemNotificationsEnabled =
          await NotificationSettingsService.isNotificationTypeEnabled(
        NotificationType.systemNotifications,
      );
      expect(systemNotificationsEnabled, false);
    });
  });
}
