import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';

class AdminService {
  final Dio _dio;

  AdminService(ApiClient apiClient) : _dio = apiClient.dio;

  Future<List<dynamic>> getPharmacies({String? status, String? city}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (city != null) queryParams['city'] = city;

    final response = await _dio.get(
      '/admin/pharmacies',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return response.data['pharmacies'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPharmacyDetails(int id) async {
    final response = await _dio.get('/admin/pharmacies/$id');
    return response.data['pharmacy'] as Map<String, dynamic>;
  }

  Future<void> approvePharmacy(
    int id, {
    bool approved = true,
    String? reason,
  }) async {
    await _dio.put(
      '/admin/pharmacies/$id/approve',
      data: {'approved': approved, 'reason': reason},
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/admin/stats');
    return response.data['stats'] as Map<String, dynamic>;
  }
}

final adminServiceProvider = Provider<AdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminService(apiClient);
});
