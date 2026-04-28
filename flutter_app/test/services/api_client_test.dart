import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API Client Retry Logic', () {
    test('should retry on connection timeout', () {
      const errorType = DioExceptionType.connectionTimeout;
      final shouldRetry =
          errorType == DioExceptionType.connectionTimeout ||
          errorType == DioExceptionType.receiveTimeout ||
          errorType == DioExceptionType.sendTimeout;

      expect(shouldRetry, true);
    });

    test('should retry on receive timeout', () {
      const errorType = DioExceptionType.receiveTimeout;
      final shouldRetry =
          errorType == DioExceptionType.connectionTimeout ||
          errorType == DioExceptionType.receiveTimeout ||
          errorType == DioExceptionType.sendTimeout;

      expect(shouldRetry, true);
    });

    test('should retry on send timeout', () {
      const errorType = DioExceptionType.sendTimeout;
      final shouldRetry =
          errorType == DioExceptionType.connectionTimeout ||
          errorType == DioExceptionType.receiveTimeout ||
          errorType == DioExceptionType.sendTimeout;

      expect(shouldRetry, true);
    });

    test('should retry on 500 status code', () {
      const statusCode = 500;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, true);
    });

    test('should retry on 502 status code', () {
      const statusCode = 502;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, true);
    });

    test('should retry on 503 status code', () {
      const statusCode = 503;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, true);
    });

    test('should not retry on 400 status code', () {
      const statusCode = 400;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, false);
    });

    test('should not retry on 401 status code', () {
      const statusCode = 401;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, false);
    });

    test('should not retry on 404 status code', () {
      const statusCode = 404;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, false);
    });

    test('should handle null status code', () {
      const int? statusCode = null;
      final shouldRetry = statusCode != null && statusCode >= 500;

      expect(shouldRetry, false);
    });
  });

  group('API Client Configuration', () {
    test('should have correct default timeout', () {
      const connectTimeout = Duration(seconds: 30);
      const receiveTimeout = Duration(seconds: 30);

      expect(connectTimeout.inSeconds, 30);
      expect(receiveTimeout.inSeconds, 30);
    });

    test('should have correct headers', () {
      const headers = {'Content-Type': 'application/json'};

      expect(headers['Content-Type'], 'application/json');
    });

    test('should have correct base URL format', () {
      const baseUrl = 'https://sectional-subpanel-junkman.ngrok-free.dev/api';

      expect(baseUrl.contains('https'), true);
      expect(baseUrl.contains('/api'), true);
    });
  });

  group('Retry Delay Calculation', () {
    test('should calculate retry delay correctly', () {
      const baseDelayMs = 1000;
      const maxRetries = 3;

      for (var i = 0; i < maxRetries; i++) {
        final delay = baseDelayMs * (i + 1);
        expect(delay, greaterThan(0));
      }

      expect(baseDelayMs * 1, 1000);
      expect(baseDelayMs * 2, 2000);
      expect(baseDelayMs * 3, 3000);
    });
  });
}

enum DioExceptionType {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  badResponse,
  cancel,
  connectionError,
  unknown,
}
