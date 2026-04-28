import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService(this._apiClient);

  Future<void> saveProfile({
    required int userId,
    required String skinType,
    required List<String> concerns,
  }) async {
    await _apiClient.dio.post(
      '/user/profile',
      data: {'user_id': userId, 'skin_type': skinType, 'concerns': concerns},
    );
  }

  Future<Map<String, dynamic>?> getProfile(int userId) async {
    try {
      final response = await _apiClient.dio.get('/user/profile/$userId');
      return response.data['user'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingService(apiClient);
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
