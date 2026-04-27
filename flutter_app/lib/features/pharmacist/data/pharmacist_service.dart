import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';

class PharmacistService {
  final Dio _dio;

  PharmacistService(ApiClient apiClient) : _dio = apiClient.dio;

  Future<List<dynamic>> getIncomingQuotes(int pharmacyId) async {
    final response = await _dio.get('/quotes/pharmacy/$pharmacyId');
    return response.data['quotes'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> respondToQuote({
    required int quoteId,
    required int pharmacyId,
    required double totalPrice,
    String? notes,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await _dio.put(
      '/quotes/$quoteId/respond',
      data: {
        'pharmacy_id': pharmacyId,
        'total_price': totalPrice,
        'notes': notes,
        'items': items,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getQuoteResponses(int quoteId) async {
    final response = await _dio.get('/quotes/$quoteId/responses');
    return response.data as Map<String, dynamic>;
  }
}

final pharmacistServiceProvider = Provider<PharmacistService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PharmacistService(apiClient);
});
