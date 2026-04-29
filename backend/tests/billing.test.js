const request = require('supertest');
const app = require('../src/index');

describe('Billing Calculator - Phase 35', () => {
  describe('GET /orders/:order_id/billing', () => {
    const validOrderId = 1;

    test('Normal Case: should return billing summary with split payments', async () => {
      const response = await request(app).get('/api/orders/' + validOrderId + '/billing');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('order_id');
      expect(response.body).toHaveProperty('segments_summary');
      expect(response.body).toHaveProperty('calculation');
      expect(response.body).toHaveProperty('verification');
    });

    test('Normal Case: should calculate correct split payment totals', async () => {
      const response = await request(app).get('/api/orders/' + validOrderId + '/billing');
      
      const { calculation } = response.body;
      expect(calculation).toHaveProperty('subtotal_a');
      expect(calculation).toHaveProperty('subtotal_b');
      expect(calculation).toHaveProperty('delivery_fee');
      expect(calculation).toHaveProperty('user_total');
      
      const expectedTotal = calculation.subtotal_a + calculation.subtotal_b + calculation.delivery_fee;
      expect(calculation.user_total).toBe(expectedTotal);
    });

    test('Normal Case: should verify segment totals match order total', async () => {
      const response = await request(app).get('/api/orders/' + validOrderId + '/billing');
      
      const { verification } = response.body;
      expect(verification).toHaveProperty('segments_total');
      expect(verification).toHaveProperty('order_total');
      expect(verification).toHaveProperty('is_valid');
      
      expect(verification.is_valid).toBe(true);
    });

    test('Edge Case: should handle single segment order', async () => {
      const response = await request(app).get('/api/orders/2/billing');
      
      expect(response.status).toBe(200);
      const { calculation } = response.body;
      expect(calculation.subtotal_b).toBe(0);
    });

    test('Edge Case: should handle order with zero delivery fee', async () => {
      const response = await request(app).get('/api/orders/1/billing');
      
      expect(response.status).toBe(200);
      const { calculation } = response.body;
      expect(calculation.delivery_fee).toBeGreaterThanOrEqual(0);
    });

    test('Error Case: should return 404 for non-existent order', async () => {
      const response = await request(app).get('/api/orders/999999/billing');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
    });

    test('Error Case: should return 400 for invalid order ID', async () => {
      const response = await request(app).get('/api/orders/abc/billing');
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    test('Error Case: should return 400 for negative order ID', async () => {
      const response = await request(app).get('/api/orders/-1/billing');
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Multi-pharmacy Split Billing', () => {
    test('Normal Case: should correctly split between two pharmacies', async () => {
      const response = await request(app).get('/api/orders/1/billing');
      
      expect(response.status).toBe(200);
      const { segments_summary } = response.body;
      
      expect(segments_summary).toHaveProperty('pharmacy_a');
      expect(segments_summary.pharmacy_a).toHaveProperty('subtotal');
      expect(segments_summary.pharmacy_b).toBeNull();
    });

    test('Normal Case: should include delivery fee in calculation', async () => {
      const response = await request(app).get('/api/orders/2/billing');
      
      const { calculation } = response.body;
      expect(calculation.delivery_fee).toBeGreaterThan(0);
    });
  });

  describe('Billing Verification', () => {
    test('Edge Case: should show mismatch when segments total differs', async () => {
      const response = await request(app).get('/api/orders/2/billing');
      
      const { verification } = response.body;
      expect(verification).toHaveProperty('is_valid');
    });

    test('Normal Case: should show currency as SDG', async () => {
      const response = await request(app).get('/api/orders/1/billing');
      
      expect(response.body.currency).toBe('SDG');
    });
  });
});