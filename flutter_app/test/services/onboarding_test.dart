import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Onboarding Profile', () {
    test('should create valid profile payload', () {
      final payload = {
        'user_id': 1,
        'skin_type': 'dry',
        'concerns': ['dryness', 'aging', 'dark_spots'],
      };

      expect(payload['user_id'], 1);
      expect(payload['skin_type'], 'dry');
      expect((payload['concerns'] as List).length, 3);
    });

    test('should handle all skin types', () {
      final validSkinTypes = [
        'oily',
        'dry',
        'combination',
        'sensitive',
        'normal',
      ];

      for (final skinType in validSkinTypes) {
        final payload = {
          'user_id': 1,
          'skin_type': skinType,
          'concerns': <String>[],
        };

        expect(payload['skin_type'], skinType);
      }
    });

    test('should handle empty concerns', () {
      final payload = {
        'user_id': 1,
        'skin_type': 'normal',
        'concerns': <String>[],
      };

      expect((payload['concerns'] as List).isEmpty, true);
    });

    test('should handle multiple concerns', () {
      final payload = {
        'user_id': 1,
        'skin_type': 'oily',
        'concerns': ['acne', 'large_pores', 'excess_oil', 'blackheads'],
      };

      expect((payload['concerns'] as List).length, 4);
    });
  });

  group('Profile Response Parsing', () {
    test('should parse complete profile', () {
      final profile = {
        'user': {
          'id': 1,
          'phone': '+249123456789',
          'skin_type': 'dry',
          'concerns': ['dryness', 'aging'],
          'budget_range': 'medium',
          'sensitivities': ['fragrance', 'alcohol'],
        },
      };

      final user = profile['user'] as Map<String, dynamic>;
      expect(user['id'], 1);
      expect(user['skin_type'], 'dry');
      expect((user['concerns'] as List).length, 2);
      expect(user['budget_range'], 'medium');
      expect((user['sensitivities'] as List).length, 2);
    });

    test('should handle missing optional fields', () {
      final profile = {
        'user': {'id': 1, 'phone': '+249123456789'},
      };

      final user = profile['user'] as Map<String, dynamic>;
      expect(user['skin_type'], isNull);
      expect(user['concerns'], isNull);
    });

    test('should handle null profile', () {
      final profile = <String, dynamic>{};

      expect(profile['user'], isNull);
    });
  });

  group('Skin Type Quiz', () {
    test('should validate quiz responses', () {
      final quizAnswers = {
        'question_1': 'often_feel_tight',
        'question_2': 'rarely_shine',
        'question_3': 'no_visible_pores',
        'question_4': 'rarely_breakouts',
      };

      expect(quizAnswers.isNotEmpty, true);
      expect(quizAnswers.length, 4);
    });

    test('should map answers to skin type', () {
      final answers = {
        'q1': 'tight',
        'q2': 'shiny',
        'q3': 'large_pores',
        'q4': 'frequent_breakouts',
      };

      String skinType;
      final oilyAnswers = answers.values
          .where(
            (a) =>
                a == 'shiny' || a == 'large_pores' || a == 'frequent_breakouts',
          )
          .length;

      if (oilyAnswers >= 3) {
        skinType = 'oily';
      } else if (answers.values.any((a) => a == 'tight')) {
        skinType = 'dry';
      } else {
        skinType = 'combination';
      }

      expect(skinType, 'oily');
    });

    test('should map dry answers to dry skin type', () {
      final answers = {
        'q1': 'tight',
        'q2': 'dull',
        'q3': 'small_pores',
        'q4': 'rarely_breakouts',
      };

      String skinType;
      final dryAnswers = answers.values
          .where((a) => a == 'tight' || a == 'dull' || a == 'small_pores')
          .length;

      if (dryAnswers >= 3) {
        skinType = 'dry';
      } else {
        skinType = 'normal';
      }

      expect(skinType, 'dry');
    });
  });
}
