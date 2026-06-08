import 'package:dio/dio.dart';
import '../utils/constants.dart';

class PaymentService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> nameLookup({
    required String accountNumber,
    required String provider,
    required String channel,
    required String authToken,
  }) async {
    final url = '${AppConstants.baseUrl}/api/payouts/namelookup';
    final headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    };
    final body = {
      'accountNumber': accountNumber,
      'provider': provider,
      'channel': channel,
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Name lookup failed: ${response.statusMessage}');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map
          ? (data['message']?.toString() ?? data['error']?.toString() ?? 'Name lookup failed')
          : 'Name lookup failed';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String contractId,
    required double amount,
    required String initiatorId,
    required String beneficiaryId,
    required String currency,
    required String msisdn,
    String? channel,
    required String narration,
  }) async {
    try {
      // Prepare the request data
      final requestData = {
        'contractId': contractId,
        'amount': amount,
        'initiatorId': initiatorId,
        'currency': currency,
        'msisdn': msisdn,
        if (channel != null) 'channel': channel,
        'narration': narration,
      };

      final url = '${AppConstants.baseUrl}/api/payments/initiate';
      final headers = {
        'Authorization': 'Bearer $beneficiaryId',
        'Content-Type': 'application/json',
      };

      // Debug prints
      print('🚀 PAYMENT API REQUEST DEBUG:');
      print('📡 URL: $url');
      print('📦 BODY: $requestData');
      print('🔑 HEADERS: $headers');
      print('----------------------------------------');

      // Make the API call
      final response = await _dio.post(
        url,
        data: requestData,
        options: Options(
          headers: headers,
        ),
      );

      // Debug prints for response
      print('✅ PAYMENT API RESPONSE DEBUG:');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Data: ${response.data}');
      print('📋 Response Headers: ${response.headers}');
      print('========================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Payment initiation failed: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ PAYMENT API ERROR: $e');

      // Enhanced error logging for DioException
      if (e is DioException) {
        print('🔍 DETAILED ERROR DEBUG:');
        print('📡 Request URL: ${e.requestOptions.uri}');
        print('📦 Request Body: ${e.requestOptions.data}');
        print('🔑 Request Headers: ${e.requestOptions.headers}');
        print('📊 Response Status: ${e.response?.statusCode}');
        print('📄 Response Data: ${e.response?.data}');
        print('📋 Response Headers: ${e.response?.headers}');
        print('========================================');
      }

      throw Exception('Failed to initiate payment: $e');
    }
  }
}
