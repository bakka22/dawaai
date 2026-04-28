import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dawaai_app/features/auth/data/auth_state.dart';
import 'package:dawaai_app/features/auth/data/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('AuthState', () {
    test('initial state should have correct default values', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.error, isNull);
      expect(state.phone, isNull);
      expect(state.role, isNull);
      expect(state.userId, isNull);
    });

    test('copyWith should create new state with updated values', () {
      const initialState = AuthState();
      final newState = initialState.copyWith(
        status: AuthStatus.loading,
        phone: '+249123456789',
        role: 'customer',
        userId: 1,
      );

      expect(newState.status, AuthStatus.loading);
      expect(newState.phone, '+249123456789');
      expect(newState.role, 'customer');
      expect(newState.userId, 1);
      expect(newState.error, isNull);
    });

    test('copyWith should preserve unchanged values', () {
      const initialState = AuthState(
        status: AuthStatus.authenticated,
        phone: '+249123456789',
        role: 'customer',
        userId: 1,
      );

      final newState = initialState.copyWith(error: 'Some error');

      expect(newState.status, AuthStatus.authenticated);
      expect(newState.phone, '+249123456789');
      expect(newState.role, 'customer');
      expect(newState.userId, 1);
      expect(newState.error, 'Some error');
    });

    test('copyWith with null should preserve original value', () {
      const initialState = AuthState(
        status: AuthStatus.authenticated,
        phone: '+249123456789',
      );

      final newState = initialState.copyWith(status: null);

      expect(newState.status, AuthStatus.authenticated);
    });
  });

  group('AuthStatus', () {
    test('should have all expected statuses', () {
      expect(AuthStatus.values, contains(AuthStatus.initial));
      expect(AuthStatus.values, contains(AuthStatus.loading));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.error));
    });
  });
}
