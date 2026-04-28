import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class CosmeticProduct {
  final int id;
  final String name;
  final String? brand;
  final String? targetSkinType;
  final List<dynamic> concerns;
  final double? price;
  final String? description;
  final String? imageUrl;
  final List<String> whyThis;

  CosmeticProduct({
    required this.id,
    required this.name,
    this.brand,
    this.targetSkinType,
    this.concerns = const [],
    this.price,
    this.description,
    this.imageUrl,
    this.whyThis = const [],
  });

  factory CosmeticProduct.fromJson(Map<String, dynamic> json) {
    return CosmeticProduct(
      id: json['id'],
      name: json['name'] ?? '',
      brand: json['brand'],
      targetSkinType: json['target_skin_type'],
      concerns: json['concerns'] ?? [],
      price: json['price']?.toDouble(),
      description: json['description'],
      imageUrl: json['image_url'],
      whyThis: List<String>.from(json['why_this'] ?? []),
    );
  }
}

class CosmeticState {
  final List<CosmeticProduct> products;
  final bool isLoading;
  final String? error;

  CosmeticState({this.products = const [], this.isLoading = false, this.error});

  CosmeticState copyWith({
    List<CosmeticProduct>? products,
    bool? isLoading,
    String? error,
  }) {
    return CosmeticState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CosmeticNotifier extends StateNotifier<CosmeticState> {
  final ApiClient _apiClient;

  CosmeticNotifier(this._apiClient) : super(CosmeticState());

  Future<void> loadRecommendations(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(
        '/cosmetics/recommendations',
        queryParameters: {'user_id': userId},
      );
      final List<dynamic> productsJson = response.data['products'] ?? [];
      final products = productsJson
          .map((json) => CosmeticProduct.fromJson(json))
          .toList();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recommendations',
      );
    }
  }

  Future<void> loadAllCosmetics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/cosmetics');
      final List<dynamic> productsJson = response.data['products'] ?? [];
      final products = productsJson
          .map((json) => CosmeticProduct.fromJson(json))
          .toList();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load cosmetics',
      );
    }
  }
}

final cosmeticProvider = StateNotifierProvider<CosmeticNotifier, CosmeticState>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    return CosmeticNotifier(apiClient);
  },
);
