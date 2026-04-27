import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';

class OrderService {
  final Dio _dio;

  OrderService(ApiClient apiClient) : _dio = apiClient.dio;

  Future<Map<String, dynamic>> createOrder({
    required int customerId,
    required int quoteId,
    required int quoteResponseId,
    required int pharmacyId,
    required List<Map<String, dynamic>> medications,
    double? totalPrice,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/orders/create',
      data: {
        'customer_id': customerId,
        'quote_id': quoteId,
        'quote_response_id': quoteResponseId,
        'pharmacy_id': pharmacyId,
        'medications': medications,
        'total_price': totalPrice,
        'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCustomerOrders(int customerId) async {
    final response = await _dio.get('/orders/customer/$customerId');
    return response.data['orders'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final response = await _dio.get('/orders/$orderId');
    return response.data as Map<String, dynamic>;
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});
