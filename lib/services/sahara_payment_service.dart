import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Handles sahara-specific deposit (fund) and withdrawal (payout) API calls.
class SaharaPaymentService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ──────────────────────────────────────────────
  //  DEPOSIT  (fund a sahara via mobile money)
  // ──────────────────────────────────────────────
  /// Calls POST /api/budget-payments/initiate
  /// [ownerId] is passed as the Bearer token.
  Future<Map<String, dynamic>> initiateSaharaDeposit({
    required String budgetId,
    required double amount,
    required String ownerId,
    required String msisdn,
    String? channel,
    String? narration,
    String? provider,
  }) async {
    final url = '${AppConstants.baseUrl}/api/budget-payments/initiate';
    final headers = {
      'Authorization': 'Bearer $ownerId',
      'Content-Type': 'application/json',
    };
    final body = {
      'budgetId': budgetId,
      'amount': amount,
      'msisdn': msisdn,
      if (provider != null) 'provider': provider,
      if (channel != null) 'channel': channel,
      if (narration != null) 'narration': narration,
    };

    print('🚀 [SAHARA DEPOSIT] POST $url');
    print('📦 Body: $body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ [SAHARA DEPOSIT] ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] != true) {
          throw Exception(
            data['message']?.toString() ?? 'Sahara deposit failed',
          );
        }

        final inner = data['data'];
        if (inner is Map && inner['status'] == 'FAILED') {
          throw Exception(
            data['message']?.toString() ?? 'Payment gateway rejected the request',
          );
        }

        return data;
      }
      throw Exception('Sahara deposit failed: ${response.statusMessage}');
    } on DioException catch (e) {
      print(
          '❌ [SAHARA DEPOSIT] DioException: ${e.response?.data ?? e.message}');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    }
  }

  // ──────────────────────────────────────────────
  //  WITHDRAWAL  (withdraw from sahara to mobile)
  // ──────────────────────────────────────────────
  /// Calls POST /api/budget-payouts/initiate
  /// [ownerId] is passed as the Bearer token.
  Future<Map<String, dynamic>> initiateSaharaWithdrawal({
    required String budgetId,
    required double amount,
    required String ownerId,
    String msisdn = '',
    required String channel,
    required String recipientName,
    String? recipientBank,
    String? recipientAccount,
    String? narration,
    String? provider,
  }) async {
    final url = '${AppConstants.baseUrl}/api/budget-payouts/initiate';
    final headers = {
      'Authorization': 'Bearer $ownerId',
      'Content-Type': 'application/json',
    };
    final body = {
      'budgetId': budgetId,
      'amount': amount,
      'msisdn': msisdn,
      'channel': channel,
      'recipientName': recipientName,
      if (recipientBank != null) 'recipient_bank': recipientBank,
      if (recipientAccount != null) 'recipient_account': recipientAccount,
      if (narration != null) 'narration': narration,
      if (provider != null) 'provider': provider,
    };

    print('🚀 [SAHARA WITHDRAWAL] POST $url');
    print('📦 Body: $body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ [SAHARA WITHDRAWAL] ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Sahara withdrawal failed: ${response.statusMessage}');
    } on DioException catch (e) {
      print(
          '❌ [SAHARA WITHDRAWAL] DioException: ${e.response?.data ?? e.message}');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          e.message ??
          'Unknown error';
    }
    return e.message ?? 'Unknown error';
  }
}
