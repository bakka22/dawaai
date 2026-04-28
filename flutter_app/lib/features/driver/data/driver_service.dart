import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class DriverService {
  final ApiClient _apiClient;

  DriverService(this._apiClient);

  Future<Map<String, dynamic>> getTripStatus(int orderId) async {
    final response = await _apiClient.dio.get('/orders/$orderId/trip-status');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyDelivery({
    required int orderId,
    required int driverId,
    String? prescriptionPhotoUrl,
  }) async {
    final response = await _apiClient.dio.post(
      '/orders/$orderId/verify-delivery',
      data: {
        'driver_id': driverId,
        'prescription_photo_url': prescriptionPhotoUrl,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeOrder({
    required int orderId,
    required int driverId,
  }) async {
    final response = await _apiClient.dio.post(
      '/orders/$orderId/complete',
      data: {'driver_id': driverId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> planTrip(
    int orderId,
    double customerLat,
    double customerLng,
  ) async {
    final response = await _apiClient.dio.post(
      '/logistics/plan-trip',
      data: {
        'order_id': orderId,
        'customer_lat': customerLat,
        'customer_lng': customerLng,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

final driverServiceProvider = Provider<DriverService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DriverService(apiClient);
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
