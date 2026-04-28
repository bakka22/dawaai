const request = require('supertest');
const app = require('../src/index.js');

describe('Prescription Handover (Phase 32)', () => {
  describe('POST /api/orders/:id/confirm-prescription', () => {
    test('should return 404 for non-existent order', async () => {
      const res = await request(app)
        .post('/api/orders/99999/confirm-prescription')
        .send({ driver_id: 1 });

      expect(res.status).toBe(404);
    });

    test('should require driver_id', async () => {
      const res = await request(app)
        .post('/api/orders/1/confirm-prescription')
        .send({});

      expect(res.status).toBe(400);
    });

    test('should accept valid confirmation request', async () => {
      const res = await request(app)
        .post('/api/orders/1/confirm-prescription')
        .send({ driver_id: 1 });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('success');
    });
  });

  describe('GET /api/orders/:id/pharmacy-address (with handover check)', () => {
    test('should return 400 for invalid order ID', async () => {
      const res = await request(app)
        .get('/api/orders/invalid/pharmacy-address');

      expect(res.status).toBe(400);
    });

    test('should reject non-numeric order ID', async () => {
      const res = await request(app)
        .get('/api/orders/-1/pharmacy-address');

      expect(res.status).toBe(400);
    });
  });

  describe('Edge Cases', () => {
    test('should handle invalid order ID on confirm', async () => {
      const res = await request(app)
        .post('/api/orders/invalid/confirm-prescription')
        .send({ driver_id: 1 });

      expect(res.status).toBe(400);
    });

    test('should reject null driver_id', async () => {
      const res = await request(app)
        .post('/api/orders/1/confirm-prescription')
        .send({ driver_id: null });

      expect(res.status).toBe(400);
    });

    test('should reject missing driver_id', async () => {
      const res = await request(app)
        .post('/api/orders/1/confirm-prescription')
        .send({});

      expect(res.status).toBe(400);
    });
  });
});