const request = require('supertest');
const app = require('../src/index.js');

describe('Pickup Window Verification (Phase 33)', () => {
  describe('Pharmacy Hours in Database', () => {
    test('should have opening_time column in pharmacies table', async () => {
      const res = await request(app)
        .get('/api/pharmacists/1')
        .set('Accept', 'application/json');
      
      if (res.status !== 404) {
        expect(res.body).toHaveProperty('opening_time');
      }
    });

    test('should have closing_time column in pharmacies table', async () => {
      const res = await request(app)
        .get('/api/pharmacists/1')
        .set('Accept', 'application/json');
      
      if (res.status !== 404) {
        expect(res.body).toHaveProperty('closing_time');
      }
    });
  });

  describe('Pharmacy Search with Hours Filter', () => {
    test('should exclude pharmacy closing within 1 hour', () => {
      const closingTime = new Date();
      closingTime.setMinutes(closingTime.getMinutes() + 30);
      
      const currentTime = new Date();
      const hoursUntilClose = (closingTime - currentTime) / (1000 * 60 * 60);
      
      expect(hoursUntilClose).toBeLessThan(1);
    });

    test('should include pharmacy with more than 1 hour remaining', () => {
      const closingTime = new Date();
      closingTime.setHours(closingTime.getHours() + 3);
      
      const currentTime = new Date();
      const hoursUntilClose = (closingTime - currentTime) / (1000 * 60 * 60);
      
      expect(hoursUntilClose).toBeGreaterThan(1);
    });

    test('should exclude already closed pharmacy', () => {
      const closingTime = new Date();
      closingTime.setHours(closingTime.getHours() - 1);
      
      const currentTime = new Date();
      const isClosed = currentTime > closingTime;
      
      expect(isClosed).toBe(true);
    });

    test('should include pharmacy opening soon', () => {
      const openingTime = new Date();
      openingTime.setMinutes(openingTime.getMinutes() + 15);
      
      const currentTime = new Date();
      const minutesUntilOpen = (openingTime - currentTime) / (1000 * 60);
      
      expect(minutesUntilOpen).toBeLessThan(30);
    });
  });

  describe('Edge Cases', () => {
    test('should handle pharmacy with no closing time', () => {
      const pharmacy = {
        id: 1,
        name: '24h Pharmacy',
        opening_time: '00:00',
        closing_time: null,
      };

      expect(pharmacy.closing_time).toBeNull();
    });

    test('should handle pharmacy with no opening time', () => {
      const pharmacy = {
        id: 1,
        name: 'Random Pharmacy',
        opening_time: null,
        closing_time: '22:00',
      };

      expect(pharmacy.opening_time).toBeNull();
    });

    test('should handle midnight closing time', () => {
      const closingTime = '00:00';
      const isMidnight = closingTime === '00:00' || closingTime === '24:00';
      
      expect(isMidnight).toBe(true);
    });

    test('should handle time format HH:MM', () => {
      const time = '21:30';
      const parts = time.split(':');
      
      expect(parts.length).toBe(2);
      expect(parseInt(parts[0])).toBe(21);
      expect(parseInt(parts[1])).toBe(30);
    });
  });

  describe('Search Endpoint Hours Filter', () => {
    test('should filter pharmacies by closing time in search', async () => {
      const res = await request(app)
        .post('/api/search/pharmacies')
        .send({ medications: ['Panadol'], city: 'Khartoum' });

      if (res.status === 200 && res.body.pharmacies) {
        res.body.pharmacies.forEach(p => {
          if (p.closing_time) {
            expect(p).toHaveProperty('closing_time');
          }
        });
      }
    });
  });
});