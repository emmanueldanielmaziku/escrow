import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';

Future<void> sendFCMV1Notification({
  required String fcmToken,
  required String title,
  required String body,
}) async {
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

  final projectId = 'escrow-app-7702f';

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

  client.close();
}
