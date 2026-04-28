const request = require('supertest');
const app = require('../src/index.js');

describe('Order Status Endpoint (Phase 31)', () => {
  const validToken = 'valid-test-token';
  const orderId = 1;

  describe('GET /api/orders/:id/status', () => {
    test('should return order status for valid order', async () => {
      const res = await request(app)
        .get(`/api/orders/${orderId}/status`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('order_id');
      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('current_waypoint');
    });

    test('should include estimated arrival for in-transit orders', async () => {
      const res = await request(app)
        .get(`/api/orders/${orderId}/status`);

      if (res.body.status === 'IN_TRANSIT') {
        expect(res.body).toHaveProperty('estimated_arrival');
      }
    });

    test('should return 404 for non-existent order', async () => {
      const res = await request(app)
        .get('/api/orders/99999/status');

      expect(res.status).toBe(404);
    });

    test('should include waypoints for active orders', async () => {
      const res = await request(app)
        .get(`/api/orders/${orderId}/status`);

      const activeStatuses = ['PENDING', 'PREPARING', 'READY_FOR_PICKUP', 'IN_TRANSIT'];
      if (activeStatuses.includes(res.body.status)) {
        expect(res.body).toHaveProperty('waypoints');
      }
    });

    test('should indicate high-risk medication orders', async () => {
      const res = await request(app)
        .get(`/api/orders/${orderId}/status`);

      expect(res.body).toHaveProperty('is_high_risk');
    });
  });

  describe('Polling Interval Validation', () => {
    test('should respond within 1 second for polling', async () => {
      const start = Date.now();
      const res = await request(app)
        .get(`/api/orders/${orderId}/status`);
      const duration = Date.now() - start;

      expect(res.status).toBe(200);
      expect(duration).toBeLessThan(1000);
    });

    test('should handle rapid consecutive requests', async () => {
      const promises = [];
      for (let i = 0; i < 5; i++) {
        promises.push(
          request(app)
            .get(`/api/orders/${orderId}/status`)
        );
      }

      const results = await Promise.all(promises);
      results.forEach(res => expect(res.status).toBe(200));
    });
  });

  describe('Edge Cases', () => {
    test('should handle invalid order ID format', async () => {
      const res = await request(app)
        .get('/api/orders/invalid/status');

      expect(res.status).toBe(400);
    });

    test('should handle negative order ID', async () => {
      const res = await request(app)
        .get('/api/orders/-1/status');

      expect(res.status).toBe(400);
    });

    test('should handle order ID zero', async () => {
      const res = await request(app)
        .get('/api/orders/0/status');

      expect(res.status).toBe(400);
    });
  });
});