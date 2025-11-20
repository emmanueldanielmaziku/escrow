import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/notification_settings_service.dart';
import '../utils/custom_snackbar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings =
          await NotificationSettingsService.getNotificationSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to load notification settings',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _updateSetting({
    required bool notificationsEnabled,
    bool? contractUpdates,
    bool? paymentNotifications,
    bool? systemNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    if (_settings == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedSettings = _settings!.copyWith(
        notificationsEnabled: notificationsEnabled,
        contractUpdates: contractUpdates,
        paymentNotifications: paymentNotifications,
        systemNotifications: systemNotifications,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
      );

      await NotificationSettingsService.updateNotificationSettings(
          updatedSettings);

      setState(() {
        _settings = updatedSettings;
        _isSaving = false;
      });

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Settings updated successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to update settings',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await NotificationSettingsService.resetToDefaults();
      await _loadSettings();

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Settings reset to defaults',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to reset settings',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF22C55E),
              ),
            )
          : _settings == null
              ? const Center(
                  child: Text('Failed to load settings'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main notification toggle
                      _buildMainToggle(),
                      const SizedBox(height: 24),

                      // Notification types section
                      if (_settings!.notificationsEnabled) ...[
                        _buildNotificationTypesSection(),
                        const SizedBox(height: 24),
                      ],

                      // Sound and vibration section
                      if (_settings!.notificationsEnabled) ...[
                        _buildSoundVibrationSection(),
                        const SizedBox(height: 24),
                      ],

                      // Reset button
                      _buildResetButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.notification,
              color: const Color(0xFF22C55E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Receive notifications about contracts and payments',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings!.notificationsEnabled,
            onChanged: (value) => _updateSetting(notificationsEnabled: value),
            activeThumbColor: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationTypeItem(
            icon: Iconsax.document_text,
            title: 'Contract Updates',
            subtitle: 'New contracts, status changes, and updates',
            value: _settings!.contractUpdates,
            onChanged: (value) => _updateSetting(
              notificationsEnabled: _settings!.notificationsEnabled,
              contractUpdates: value,
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationTypeItem(
            icon: Iconsax.wallet_money,
            title: 'Payment Notifications',
            subtitle: 'Payment confirmations and balance updates',
            value: _settings!.paymentNotifications,
            onChanged: (value) => _updateSetting(
              notificationsEnabled: _settings!.notificationsEnabled,
              paymentNotifications: value,
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationTypeItem(
            icon: Iconsax.setting_3,
            title: 'System Notifications',
            subtitle: 'App updates and maintenance notices',
            value: _settings!.systemNotifications,
            onChanged: (value) => _updateSetting(
              notificationsEnabled: _settings!.notificationsEnabled,
              systemNotifications: value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF22C55E),
        ),
      ],
    );
  }

  Widget _buildSoundVibrationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sound & Vibration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationTypeItem(
            icon: Iconsax.volume_high,
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            value: _settings!.soundEnabled,
            onChanged: (value) => _updateSetting(
              notificationsEnabled: _settings!.notificationsEnabled,
              soundEnabled: value,
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationTypeItem(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrate device for notifications',
            value: _settings!.vibrationEnabled,
            onChanged: (value) => _updateSetting(
              notificationsEnabled: _settings!.notificationsEnabled,
              vibrationEnabled: value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _resetToDefaults,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.grey[700],
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Reset to Defaults',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
