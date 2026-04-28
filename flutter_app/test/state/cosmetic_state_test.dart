import 'package:flutter_test/flutter_test.dart';
import 'package:dawaai_app/features/cosmetic/data/cosmetic_service.dart';

void main() {
  group('CosmeticProduct', () {
    test('fromJson should parse all fields correctly', () {
      final json = {
        'id': 1,
        'name': 'Face Cream',
        'brand': 'Nivea',
        'target_skin_type': 'dry',
        'concerns': ['dryness', 'aging'],
        'price': 150.0,
        'description': 'Moisturizing cream',
        'image_url': 'https://example.com/image.jpg',
        'why_this': ['Safe for dry skin', 'Hydrating'],
      };

      final product = CosmeticProduct.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Face Cream');
      expect(product.brand, 'Nivea');
      expect(product.targetSkinType, 'dry');
      expect(product.concerns, ['dryness', 'aging']);
      expect(product.price, 150.0);
      expect(product.description, 'Moisturizing cream');
      expect(product.imageUrl, 'https://example.com/image.jpg');
      expect(product.whyThis, ['Safe for dry skin', 'Hydrating']);
    });

    test('fromJson should handle null optional fields', () {
      final json = {'id': 2, 'name': 'Shampoo'};

      final product = CosmeticProduct.fromJson(json);

      expect(product.id, 2);
      expect(product.name, 'Shampoo');
      expect(product.brand, isNull);
      expect(product.targetSkinType, isNull);
      expect(product.concerns, isEmpty);
      expect(product.price, isNull);
      expect(product.description, isNull);
      expect(product.imageUrl, isNull);
      expect(product.whyThis, isEmpty);
    });

    test('fromJson should handle missing why_this field', () {
      final json = {'id': 3, 'name': 'Soap', 'price': 50.0};

      final product = CosmeticProduct.fromJson(json);

      expect(product.whyThis, isEmpty);
      expect(product.price, 50.0);
    });

    test('fromJson should handle numeric price as int', () {
      final json = {'id': 4, 'name': 'Lotion', 'price': 100};

      final product = CosmeticProduct.fromJson(json);

      expect(product.price, 100.0);
    });
  });

  group('CosmeticState', () {
    test('initial state should have correct default values', () {
      final state = CosmeticState();

      expect(state.products, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith should update products correctly', () {
      final initialState = CosmeticState();
      final products = [
        CosmeticProduct(id: 1, name: 'Product 1'),
        CosmeticProduct(id: 2, name: 'Product 2'),
      ];
      final newState = initialState.copyWith(products: products);

      expect(newState.products.length, 2);
      expect(newState.isLoading, false);
    });

    test('copyWith should update isLoading correctly', () {
      final initialState = CosmeticState();
      final newState = initialState.copyWith(isLoading: true);

      expect(newState.isLoading, true);
      expect(newState.products, isEmpty);
    });

    test('copyWith should update error correctly', () {
      final initialState = CosmeticState();
      final newState = initialState.copyWith(error: 'Failed to load products');

      expect(newState.error, 'Failed to load products');
    });

    test('copyWith should preserve unchanged values', () {
      final initialState = CosmeticState(
        products: [CosmeticProduct(id: 1, name: 'Test')],
        isLoading: true,
      );

      final newState = initialState.copyWith(error: 'New error');

      expect(newState.products.length, 1);
      expect(newState.isLoading, true);
      expect(newState.error, 'New error');
    });
  });
}
