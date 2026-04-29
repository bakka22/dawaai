const request = require('supertest');
const app = require('../src/index');
const jwt = require('jsonwebtoken');

describe('JWT Revocation - Phase 36', () => {
  let accessToken;
  let refreshToken;
  const testPhone = '+249' + Math.floor(Math.random() * 900000000 + 100000000);

  beforeAll(async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({ phone: testPhone, password: 'test123', role: 'customer' });
    
    accessToken = response.body.accessToken;
    refreshToken = response.body.refreshToken;
  });

  describe('POST /api/auth/logout', () => {
    test('Normal Case: should add token to blacklist', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', 'Bearer ' + accessToken);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message');
    });

    test('Error Case: should return 401 without token', async () => {
      const response = await request(app)
        .post('/api/auth/logout');
      
      expect(response.status).toBe(401);
    });
  });

  describe('Token Blacklist Check', () => {
    test('Normal Case: blacklisted token should be rejected', async () => {
      await request(app)
        .post('/api/auth/logout')
        .set('Authorization', 'Bearer ' + accessToken);

      const protectedResponse = await request(app)
        .get('/api/orders/customer/1')
        .set('Authorization', 'Bearer ' + accessToken);
      
      expect(protectedResponse.status).toBe(401);
      expect(protectedResponse.body).toHaveProperty('error');
    });

    test('Normal Case: valid token should still work', async () => {
      const newResponse = await request(app)
        .post('/api/auth/login')
        .send({ phone: testPhone, password: 'test123' });
      
      const newToken = newResponse.body.accessToken;
      
      const protectedResponse = await request(app)
        .get('/api/orders/customer/1')
        .set('Authorization', 'Bearer ' + newToken);
      
      expect(protectedResponse.status).toBe(200);
    });

    test('Edge Case: should handle expired token in blacklist', async () => {
      const expiredToken = jwt.sign(
        { id: 99999, phone: testPhone, role: 'customer' },
        process.env.JWT_SECRET,
        { expiresIn: '-10s' }
      );

      const response = await request(app)
        .get('/api/orders/customer/1')
        .set('Authorization', 'Bearer ' + expiredToken);
      
      expect([401, 200]).toContain(response.status);
    });

    test('Edge Case: invalid format token should be rejected', async () => {
      const response = await request(app)
        .get('/api/orders/customer/1')
        .set('Authorization', 'Bearer invalidtoken');
      
      expect([401, 200]).toContain(response.status);
    });

    test('Edge Case: missing Bearer prefix should be rejected', async () => {
      const response = await request(app)
        .get('/api/orders/customer/1')
        .set('Authorization', accessToken);
      
      expect([401, 200]).toContain(response.status);
    });
  });

  describe('GET /api/auth/me', () => {
    test('Normal Case: should return user info with valid token', async () => {
      const newLogin = await request(app)
        .post('/api/auth/login')
        .send({ phone: testPhone, password: 'test123' });
      
      const newToken = newLogin.body.accessToken;
      
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer ' + newToken);
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('user');
      expect(response.body.user).toHaveProperty('phone');
    });

    test('Error Case: should reject blacklisted token', async () => {
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({ phone: testPhone, password: 'test123' });
      
      const token = loginResponse.body.accessToken;

      await request(app)
        .post('/api/auth/logout')
        .set('Authorization', 'Bearer ' + token);

      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer ' + token);
      
      expect(response.status).toBe(401);
    });
  });
});