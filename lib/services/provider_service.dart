import 'package:dio/dio.dart';
import '../models/provider_model.dart';
import '../utils/constants.dart';

class ProviderService {
  final Dio _dio = Dio();

  Future<List<ProviderModel>> fetchProviders() async {
    final url = '${AppConstants.baseUrl}/api/providers';

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final rawProviders = data['data'];
          if (rawProviders is List) {
            return rawProviders
                .map((provider) => ProviderModel.fromMap(
                      Map<String, dynamic>.from(provider as Map),
                    ))
                .toList();
          }
        }
      }

      throw Exception('Failed to fetch providers');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? (data['message']?.toString() ??
              data['error']?.toString() ??
              'Failed to fetch providers')
          : 'Failed to fetch providers';
      throw Exception(message);
    }
  }
}
