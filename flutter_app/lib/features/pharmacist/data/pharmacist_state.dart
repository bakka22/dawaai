import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pharmacist_service.dart';

class QuoteItem {
  final int medicationId;
  final String name;
  final bool isOutOfStock;

  QuoteItem({
    required this.medicationId,
    required this.name,
    this.isOutOfStock = false,
  });

  QuoteItem copyWith({bool? isOutOfStock}) {
    return QuoteItem(
      medicationId: medicationId,
      name: name,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
    );
  }
}

class QuoteResponse {
  final int quoteId;
  final String status;
  final DateTime expiresAt;
  final List<QuoteItem> items;

  QuoteResponse({
    required this.quoteId,
    required this.status,
    required this.expiresAt,
    required this.items,
  });
}

class PharmacistState {
  final List<QuoteResponse> pendingQuotes;
  final bool isLoading;
  final String? error;

  const PharmacistState({
    this.pendingQuotes = const [],
    this.isLoading = false,
    this.error,
  });

  PharmacistState copyWith({
    List<QuoteResponse>? pendingQuotes,
    bool? isLoading,
    String? error,
  }) {
    return PharmacistState(
      pendingQuotes: pendingQuotes ?? this.pendingQuotes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PharmacistNotifier extends StateNotifier<PharmacistState> {
  final PharmacistService _service;
  final int pharmacyId;

  PharmacistNotifier(this._service, this.pharmacyId)
    : super(const PharmacistState());

  Future<void> loadPendingQuotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quotes = await _service.getIncomingQuotes(pharmacyId);
      state = state.copyWith(
        pendingQuotes: quotes
            .map(
              (q) => QuoteResponse(
                quoteId: q['id'] as int,
                status: q['status'] as String,
                expiresAt: DateTime.parse(q['expires_at'] as String),
                items: (q['items'] as List<dynamic>? ?? [])
                    .map(
                      (item) => QuoteItem(
                        medicationId: item['medication_id'] as int,
                        name: item['name'] as String,
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitResponse({
    required int quoteId,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      final items = state.pendingQuotes
          .firstWhere((q) => q.quoteId == quoteId)
          .items
          .map(
            (item) => {
              'medication_id': item.medicationId,
              'is_out_of_stock': item.isOutOfStock,
            },
          )
          .toList();

      await _service.respondToQuote(
        quoteId: quoteId,
        pharmacyId: pharmacyId,
        totalPrice: totalPrice,
        notes: notes,
        items: items,
      );

      final updated = state.pendingQuotes
          .where((q) => q.quoteId != quoteId)
          .toList();
      state = state.copyWith(pendingQuotes: updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void toggleItemOutOfStock(int quoteId, int medicationId) {
    final updatedQuotes = state.pendingQuotes.map((quote) {
      if (quote.quoteId == quoteId) {
        final updatedItems = quote.items.map((item) {
          if (item.medicationId == medicationId) {
            return item.copyWith(isOutOfStock: !item.isOutOfStock);
          }
          return item;
        }).toList();
        return QuoteResponse(
          quoteId: quote.quoteId,
          status: quote.status,
          expiresAt: quote.expiresAt,
          items: updatedItems,
        );
      }
      return quote;
    }).toList();
    state = state.copyWith(pendingQuotes: updatedQuotes);
  }
}

final pharmacistProvider =
    StateNotifierProvider<PharmacistNotifier, PharmacistState>((ref) {
      final service = ref.watch(pharmacistServiceProvider);
      return PharmacistNotifier(service, 1);
    });
