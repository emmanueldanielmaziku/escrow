import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Handles budget-specific deposit (fund) and withdrawal (payout) API calls.
class BudgetPaymentService {
  final Dio _dio = Dio();

  // ──────────────────────────────────────────────
  //  DEPOSIT  (fund a budget via mobile money)
  // ──────────────────────────────────────────────
  /// Calls POST /api/budget-payments/initiate
  /// [ownerId] is passed as the Bearer token.
  Future<Map<String, dynamic>> initiateBudgetDeposit({
    required String budgetId,
    required double amount,
    required String ownerId,
    required String msisdn,
    required String channel,
    String? narration,
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
      'channel': channel,
      if (narration != null) 'narration': narration,
    };

    print('🚀 [BUDGET DEPOSIT] POST $url');
    print('📦 Body: $body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ [BUDGET DEPOSIT] ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Budget deposit failed: ${response.statusMessage}');
    } on DioException catch (e) {
      print('❌ [BUDGET DEPOSIT] DioException: ${e.response?.data ?? e.message}');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    }
  }

  // ──────────────────────────────────────────────
  //  WITHDRAWAL  (withdraw from budget to mobile)
  // ──────────────────────────────────────────────
  /// Calls POST /api/budget-payouts/initiate
  /// [ownerId] is passed as the Bearer token.
  Future<Map<String, dynamic>> initiateBudgetWithdrawal({
    required String budgetId,
    required double amount,
    required String ownerId,
    required String msisdn,
    required String channel,
    required String recipientName,
    String? narration,
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
      if (narration != null) 'narration': narration,
    };

    print('🚀 [BUDGET WITHDRAWAL] POST $url');
    print('📦 Body: $body');

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      print('✅ [BUDGET WITHDRAWAL] ${response.statusCode}: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Budget withdrawal failed: ${response.statusMessage}');
    } on DioException catch (e) {
      print('❌ [BUDGET WITHDRAWAL] DioException: ${e.response?.data ?? e.message}');
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

