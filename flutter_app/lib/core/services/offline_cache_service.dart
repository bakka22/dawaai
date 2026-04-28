import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class OfflineCacheService {
  static const String _ordersBoxName = 'offline_orders';
  static const String _customerIdKey = 'cached_customer_id';

  late Box _ordersBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    _ordersBox = await Hive.openBox(_ordersBoxName);
    _isInitialized = true;
  }

  Future<void> cacheOrders(
    int customerId,
    List<Map<String, dynamic>> orders,
  ) async {
    await initialize();
    final ordersJson = jsonEncode(orders);
    await _ordersBox.put(_customerIdKey, customerId);
    await _ordersBox.put('orders_$customerId', ordersJson);
  }

  Future<List<Map<String, dynamic>>?> getCachedOrders(int customerId) async {
    await initialize();
    final cachedCustomerId = _ordersBox.get(_customerIdKey);
    if (cachedCustomerId != customerId) {
      return null;
    }
    final ordersJson = _ordersBox.get('orders_$customerId') as String?;
    if (ordersJson == null) return null;
    final decoded = jsonDecode(ordersJson) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> clearCache() async {
    await initialize();
    await _ordersBox.clear();
  }

  Future<bool> hasCachedOrders(int customerId) async {
    await initialize();
    final cachedCustomerId = _ordersBox.get(_customerIdKey);
    return cachedCustomerId == customerId &&
        _ordersBox.get('orders_$customerId') != null;
  }
}

final offlineCacheServiceProvider = OfflineCacheService();
