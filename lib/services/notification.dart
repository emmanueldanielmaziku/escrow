import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'notification_settings_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendFCMV1Notification({
  required String fcmToken,
  required String title,
  required String body,
  NotificationType? notificationType,
}) async {
  // Check if notifications are enabled for this type
  if (notificationType != null) {
    final isEnabled =
        await NotificationSettingsService.isNotificationTypeEnabled(
            notificationType);
    if (!isEnabled) {
      if (kDebugMode) {
        print('🔕 Notification disabled for type: $notificationType');
      }
      return;
    }
  }

  // Validate FCM token
  if (fcmToken.isEmpty || fcmToken == 'null') {
    if (kDebugMode) {
      print('❌ Invalid FCM token: $fcmToken');
    }
    return;
  }

  try {
    // Load the service account key from assets
    final String serviceAccountJson =
        await rootBundle.loadString('assets/env/service-account-key.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(
      json.decode(serviceAccountJson),
    );

    final client = await clientViaServiceAccount(
      serviceAccount,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    final projectId = 'mai-escrow';

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final message = {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": title,
          "body": body,
        },
        "android": {
          "priority": "high",
          "notification": {
            "icon": "notification",
            "color": "#2196F3",
            "sound": "default"
          }
        },
        "apns": {
          "headers": {"apns-priority": "10"},
          "payload": {
            "aps": {
              "alert": {"title": title, "body": body},
              "sound": "default"
            }
          }
        }
      }
    };

    final response = await client.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(message),
    );

    if (kDebugMode) {
      print('📨 V1 FCM response: ${response.statusCode} ${response.body}');
    }

    // Handle specific error cases
    if (response.statusCode == 404) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error']?['details']?[0]?['errorCode'] ==
          'UNREGISTERED') {
        if (kDebugMode) {
          print(
              '❌ FCM Token is unregistered. User may have uninstalled the app or token expired.');
        }

        await _removeInvalidToken(fcmToken);
      }
    }

    client.close();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error sending FCM notification: $e');
    }
  }
}

// Remove invalid token from Firestore
Future<void> _removeInvalidToken(String invalidToken) async {
  try {
    // Find and remove the invalid token from all users
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('deviceToken', isEqualTo: invalidToken)
        .get();

    for (final doc in usersQuery.docs) {
      await doc.reference.update({
        'deviceToken': null,
        'lastTokenUpdate': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('🗑️ Removed invalid FCM token for user: ${doc.id}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error removing invalid token: $e');
    }
  }
}
