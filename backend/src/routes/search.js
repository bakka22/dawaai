const express = require('express');
const router = express.Router();
const pool = require('../db/config');

function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

router.post('/pharmacies', async (req, res) => {
  try {
    const { medications, city, lat, lng, limit = 5 } = req.body;

    if (!medications || !Array.isArray(medications) || medications.length === 0) {
      return res.status(400).json({ error: 'Array of medications required' });
    }

    const userLat = lat ? parseFloat(lat) : null;
    const userLng = lng ? parseFloat(lng) : null;

    const searchTerms = medications.map(m => `%${m}%`);
    const placeholders = searchTerms.map((_, i) => `$${i + 1}`).join(',');
    const medicationQuery = `
      SELECT id FROM medications 
      WHERE name ILIKE ANY(ARRAY[${placeholders}])
         OR active_ingredient ILIKE ANY(ARRAY[${placeholders}])
    `;
    const medResult = await pool.query(medicationQuery, searchTerms);
    const medicationIds = medResult.rows.map(r => r.id);

    if (medicationIds.length === 0) {
      return res.json({ pharmacies: [], message: 'No medications found in database' });
    }

    let whereClause = 'WHERE p.is_approved = true AND pi.is_in_stock = true AND pi.medication_id = ANY($1)';
    const params = [medicationIds];
    
    if (city) {
      whereClause += ' AND p.city = $2';
      params.push(city);
    }

    const pharmacyQuery = `
      SELECT 
        p.id as pharmacy_id,
        p.name,
        p.lat,
        p.lng,
        p.city,
        COUNT(pi.medication_id) as match_count
      FROM pharmacies p
      JOIN pharmacy_inventory pi ON p.id = pi.pharmacy_id
      ${whereClause}
      GROUP BY p.id, p.name, p.lat, p.lng, p.city
      ORDER BY match_count DESC
      LIMIT ${parseInt(limit) + 1}
    `;

    const pharmacyResult = await pool.query(pharmacyQuery, params);

    const pharmacies = pharmacyResult.rows.map(p => {
      const distance = (userLat && userLng && p.lat && p.lng)
        ? calculateDistance(userLat, userLng, parseFloat(p.lat), parseFloat(p.lng))
        : null;
      
      return {
        pharmacy_id: p.pharmacy_id,
        name: p.name,
        city: p.city,
        match_count: parseInt(p.match_count),
        distance: distance ? parseFloat(distance.toFixed(2)) : null,
      };
    });

    pharmacies.sort((a, b) => {
      if (b.match_count !== a.match_count) {
        return b.match_count - a.match_count;
      }
      if (a.distance !== null && b.distance !== null) {
        return a.distance - b.distance;
      }
      return 0;
    });

    res.json({
      search_criteria: { medications, city, lat, lng },
      total_found: pharmacies.length,
      pharmacies: pharmacies.slice(0, parseInt(limit)),
    });
  } catch (err) {
    console.error('Pharmacy search error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;