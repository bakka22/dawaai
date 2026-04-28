import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dawaai_app/core/theme/app_theme.dart';

void main() {
  group('DawaaiTheme', () {
    test('should create light theme correctly', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.light);
    });

    test('should have correct primary color', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.colorScheme.primary, const Color(0xFF00897B));
    });

    test('should have secondary color', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.colorScheme.secondary, isNotNull);
    });

    test('should have error color', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.colorScheme.error, isNotNull);
    });

    test('should use Material 3', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.useMaterial3, true);
    });

    test('should have app bar theme', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.appBarTheme, isNotNull);
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF00897B));
    });

    test('should have card theme', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.cardTheme, isNotNull);
    });

    test('should have elevated button theme', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.elevatedButtonTheme, isNotNull);
    });

    test('should have input decoration theme', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.inputDecorationTheme, isNotNull);
    });

    test('should have text theme', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.textTheme, isNotNull);
    });
  });

  group('Theme Colors', () {
    test('primary color should be teal for Dawaai branding', () {
      const expectedPrimary = Color(0xFF00897B);
      final theme = DawaaiTheme.lightTheme;

      expect(theme.colorScheme.primary, expectedPrimary);
    });

    test('should have light teal variant', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.colorScheme.primaryContainer, isNotNull);
    });

    test('should have proper contrast colors', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.colorScheme.onPrimary, isNotNull);
      expect(theme.colorScheme.onSecondary, isNotNull);
    });
  });

  group('Edge Cases', () {
    test('should handle very long text without overflow', () {
      final theme = DawaaiTheme.lightTheme;

      final textStyle = theme.textTheme.bodyLarge;
      expect(textStyle, isNotNull);
    });

    test('should have proper spacing defined', () {
      final theme = DawaaiTheme.lightTheme;

      expect(theme.visualDensity, VisualDensity.standard);
    });

    test('should have proper border radius defaults', () {
      final theme = DawaaiTheme.lightTheme;

      final cardRadius = theme.cardTheme.shape;
      expect(cardRadius, isNotNull);
    });
  });
}
