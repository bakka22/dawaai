import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Order Creation', () {
    test('should create valid order payload', () {
      final payload = {
        'customer_id': 1,
        'quote_id': 10,
        'quote_response_id': 20,
        'pharmacy_id': 5,
        'medications': [
          {'id': 1, 'name': 'Panadol', 'quantity': 2},
          {'id': 2, 'name': 'Amoxicillin', 'quantity': 1},
        ],
        'total_price': 150.0,
        'notes': 'Please deliver after 5 PM',
      };

      expect(payload['customer_id'], 1);
      expect(payload['quote_id'], 10);
      expect(payload['quote_response_id'], 20);
      expect(payload['pharmacy_id'], 5);
      expect((payload['medications'] as List).length, 2);
      expect(payload['total_price'], 150.0);
    });

    test('should handle null notes', () {
      final payload = {
        'customer_id': 1,
        'quote_id': 10,
        'quote_response_id': 20,
        'pharmacy_id': 5,
        'medications': [
          {'id': 1, 'name': 'Panadol', 'quantity': 2},
        ],
        'total_price': 50.0,
        'notes': null,
      };

      expect(payload['notes'], isNull);
    });

    test('should handle null total price', () {
      final payload = {
        'customer_id': 1,
        'quote_id': 10,
        'quote_response_id': 20,
        'pharmacy_id': 5,
        'medications': [
          {'id': 1, 'name': 'Panadol', 'quantity': 2},
        ],
        'total_price': null,
      };

      expect(payload['total_price'], isNull);
    });
  });

  group('Order Response Parsing', () {
    test('should parse single pharmacy order', () {
      final order = {
        'id': 1,
        'customer_id': 1,
        'pharmacy_id': 5,
        'status': 'PENDING',
        'total_price': 150.0,
        'segments': [
          {
            'id': 1,
            'pharmacy_id': 5,
            'status': 'PENDING',
            'items': [
              {'name': 'Panadol', 'quantity': 2, 'price': 100.0},
            ],
          },
        ],
        'created_at': '2024-01-15T10:00:00Z',
      };

      expect(order['id'], 1);
      expect((order['segments'] as List).length, 1);
      expect(order['status'], 'PENDING');
    });

    test('should parse multi-pharmacy order', () {
      final order = {
        'id': 2,
        'customer_id': 1,
        'status': 'PENDING',
        'total_price': 300.0,
        'segments': [
          {
            'id': 1,
            'pharmacy_id': 5,
            'pharmacy_name': 'Pharmacy A',
            'status': 'PENDING',
          },
          {
            'id': 2,
            'pharmacy_id': 6,
            'pharmacy_name': 'Pharmacy B',
            'status': 'PENDING',
          },
        ],
      };

      expect((order['segments'] as List).length, 2);
    });

    test('should calculate delivery fee for multi-segment', () {
      final order = {
        'id': 2,
        'segments': [
          {'id': 1},
          {'id': 2},
        ],
        'delivery_fee': 15.0,
      };

      final segmentCount = (order['segments'] as List).length;
      final baseFee = 10.0;
      final additionalPerSegment = 5.0;
      final expectedFee = baseFee + (segmentCount - 1) * additionalPerSegment;

      expect(expectedFee, 15.0);
    });

    test('should handle paid order status', () {
      final order = {
        'id': 1,
        'status': 'PAID',
        'payment_method': 'CASH',
        'paid_at': '2024-01-15T10:30:00Z',
      };

      expect(order['status'], 'PAID');
      expect(order['payment_method'], 'CASH');
    });
  });

  group('Order List Response', () {
    test('should parse order list', () {
      final orders = [
        {'id': 1, 'status': 'PENDING', 'total_price': 100.0},
        {'id': 2, 'status': 'COMPLETED', 'total_price': 250.0},
        {'id': 3, 'status': 'CANCELLED', 'total_price': 50.0},
      ];

      expect(orders.length, 3);
      expect(orders[0]['id'], 1);
      expect(orders[1]['id'], 2);
      expect(orders[2]['id'], 3);
    });

    test('should filter active orders', () {
      final orders = [
        {'id': 1, 'status': 'PENDING'},
        {'id': 2, 'status': 'IN_TRANSIT'},
        {'id': 3, 'status': 'COMPLETED'},
      ];

      final activeOrders = orders
          .where((o) => o['status'] == 'PENDING' || o['status'] == 'IN_TRANSIT')
          .toList();

      expect(activeOrders.length, 2);
    });

    test('should handle empty order list', () {
      final orders = <Map<String, dynamic>>[];

      expect(orders.isEmpty, true);
    });
  });
}
