import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class OrderStatusPollingService {
  final ApiClient _apiClient;
  Timer? _pollingTimer;
  bool _isPolling = false;

  static const int pollingIntervalMs = 60000;

  final _statusController = StreamController<OrderStatusUpdate>.broadcast();

  Stream<OrderStatusUpdate> get statusStream => _statusController.stream;

  OrderStatusPollingService(this._apiClient);

  void startPolling(int orderId) {
    if (_isPolling) return;

    _isPolling = true;
    _pollingTimer?.cancel();

    _pollOrderStatus(orderId);

    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: pollingIntervalMs),
      (_) => _pollOrderStatus(orderId),
    );
  }

  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollOrderStatus(int orderId) async {
    try {
      final response = await _apiClient.dio.get('/orders/$orderId/status');
      final data = response.data as Map<String, dynamic>;

      final update = OrderStatusUpdate(
        orderId: data['order_id'] as int,
        status: data['status'] as String,
        currentWaypoint: data['current_waypoint'] as int?,
        isHighRisk: data['is_high_risk'] as bool? ?? false,
        waypoints: data['waypoints'] != null
            ? (data['waypoints'] as List)
                  .map((w) => Waypoint.fromJson(w))
                  .toList()
            : null,
        estimatedArrival: data['estimated_arrival'] != null
            ? DateTime.parse(data['estimated_arrival'] as String)
            : null,
      );

      _statusController.add(update);

      if (_isTerminalStatus(update.status)) {
        stopPolling();
      }
    } catch (e) {
      _statusController.addError(e);
    }
  }

  bool _isTerminalStatus(String status) {
    return status == 'COMPLETED' ||
        status == 'DELIVERED' ||
        status == 'CANCELLED';
  }

  void dispose() {
    stopPolling();
    _statusController.close();
  }
}

class OrderStatusUpdate {
  final int orderId;
  final String status;
  final int? currentWaypoint;
  final bool isHighRisk;
  final List<Waypoint>? waypoints;
  final DateTime? estimatedArrival;

  OrderStatusUpdate({
    required this.orderId,
    required this.status,
    this.currentWaypoint,
    this.isHighRisk = false,
    this.waypoints,
    this.estimatedArrival,
  });
}

class Waypoint {
  final String type;
  final String name;
  final double? lat;
  final double? lng;
  final int order;
  final String? status;

  Waypoint({
    required this.type,
    required this.name,
    this.lat,
    this.lng,
    required this.order,
    this.status,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      type: json['type'] as String,
      name: json['name'] as String,
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      order: json['order'] as int,
      status: json['status'] as String?,
    );
  }
}

final orderPollingServiceProvider = Provider<OrderStatusPollingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderStatusPollingService(apiClient);
});
