import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? phone;
  final String? role;
  final int? userId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.phone,
    this.role,
    this.userId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? phone,
    String? role,
    int? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      userId: userId ?? this.userId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> checkAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    state = state.copyWith(
      status: isLoggedIn
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _authService.login(phone, password);
      final user = response['user'] as Map<String, dynamic>;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        phone: user['phone'] as String?,
        role: user['role'] as String?,
        userId: user['id'] as int?,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> register(String phone, String password, String role) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _authService.register(phone, password, role);
      final user = response['user'] as Map<String, dynamic>;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        phone: user['phone'] as String?,
        role: user['role'] as String?,
        userId: user['id'] as int?,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
