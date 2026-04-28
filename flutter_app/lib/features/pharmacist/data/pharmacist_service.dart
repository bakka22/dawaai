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

  Future<Map<String, dynamic>?> lookupMedicationByBarcode(
    String barcode,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacist/inventory/lookup',
        queryParameters: {'barcode': barcode},
      );
      if (response.data['medication'] != null) {
        return response.data['medication'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateInventoryStock({
    required int pharmacyId,
    required int medicationId,
    required bool isInStock,
  }) async {
    await _dio.put(
      '/pharmacist/inventory/update',
      data: {
        'pharmacy_id': pharmacyId,
        'medication_id': medicationId,
        'is_in_stock': isInStock,
      },
    );
  }
}

final pharmacistServiceProvider = Provider<PharmacistService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PharmacistService(apiClient);
});
