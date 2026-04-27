import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';

const _storage = FlutterSecureStorage();

class AuthService {
  final Dio _dio;

  AuthService(ApiClient apiClient) : _dio = apiClient.dio;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'phone': phone, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    await _saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    await _saveUser(data['user'] as Map<String, dynamic>);

    return data;
  }

  Future<Map<String, dynamic>> register(
    String phone,
    String password,
    String role,
  ) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'phone': phone, 'password': password, 'role': role},
    );

    final data = response.data as Map<String, dynamic>;
    await _saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    await _saveUser(data['user'] as Map<String, dynamic>);

    return data;
  }

  Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = response.data as Map<String, dynamic>;
    await _saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: user.toString());
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});
