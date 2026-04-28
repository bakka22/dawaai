const express = require('express');
const router = express.Router();
const pool = require('../db/config');

const QUOTE_TTL_MINUTES = 20;

router.post('/broadcast', async (req, res) => {
  const client = await pool.connect();
  try {
    const { customer_id, medications, city, lat, lng } = req.body;

    if (!customer_id || !medications || !Array.isArray(medications) || medications.length === 0) {
      return res.status(400).json({ error: 'customer_id and medications array required' });
    }

    await client.query('BEGIN');

    const expiresAt = new Date(Date.now() + QUOTE_TTL_MINUTES * 60 * 1000);
    const quoteResult = await client.query(
      `INSERT INTO quotes (customer_id, status, expires_at)
       VALUES ($1, 'BROADCASTING', $2)
       RETURNING id, status, expires_at`,
      [customer_id, expiresAt]
    );
    const quote = quoteResult.rows[0];

    const searchTerms = medications.map(m => `%${m}%`);
    const placeholders = searchTerms.map((_, i) => `$${i + 1}`).join(',');
    const medResult = await client.query(
      `SELECT id FROM medications 
       WHERE name ILIKE ANY(ARRAY[${placeholders}])
          OR active_ingredient ILIKE ANY(ARRAY[${placeholders}])`,
      searchTerms
    );
    const medicationIds = medResult.rows.map(r => r.id);

    if (medicationIds.length === 0) {
      await client.query('ROLLBACK');
      return res.json({ quote_id: quote.id, pharmacies: [], message: 'No medications found' });
    }

    let whereClause = 'WHERE p.is_approved = true AND pi.is_in_stock = true AND pi.medication_id = ANY($1)';
    const params = [medicationIds];
    if (city) {
      whereClause += ' AND p.city = $2';
      params.push(city);
    }

    const pharmacyResult = await client.query(
      `SELECT 
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
      LIMIT 3`,
      params
    );

    for (const pharmacy of pharmacyResult.rows) {
      await client.query(
        `INSERT INTO quote_responses (quote_id, pharmacy_id, status)
         VALUES ($1, $2, 'PENDING')`,
        [quote.id, pharmacy.pharmacy_id]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      quote: {
        id: quote.id,
        status: quote.status,
        expires_at: quote.expires_at,
      },
      medications_requested: medications,
      notified_pharmacies: pharmacyResult.rows.length,
      pharmacies: pharmacyResult.rows.map(p => ({
        pharmacy_id: p.pharmacy_id,
        name: p.name,
        city: p.city,
        match_count: parseInt(p.match_count),
      })),
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Broadcast quote error:', err);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

router.get('/:quote_id', async (req, res) => {
  try {
    const { quote_id } = req.params;
    const result = await pool.query(
      'SELECT * FROM quotes WHERE id = $1',
      [quote_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Quote not found' });
    }

    res.json({ quote: result.rows[0] });
  } catch (err) {
    console.error('Get quote error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:quote_id/responses', async (req, res) => {
  try {
    const { quote_id } = req.params;
    const { status } = req.query;

    let query = `
      SELECT qr.*, p.name as pharmacy_name, p.city as pharmacy_city
      FROM quote_responses qr
      JOIN pharmacies p ON qr.pharmacy_id = p.id
      WHERE qr.quote_id = $1
    `;
    const params = [quote_id];

    if (status) {
      query += ' AND qr.status = $2';
      params.push(status);
    }

    query += ' ORDER BY qr.responded_at DESC';

    const result = await pool.query(query, params);

    const quoteResult = await pool.query(
      'SELECT status, expires_at FROM quotes WHERE id = $1',
      [quote_id]
    );

    if (quoteResult.rows.length === 0) {
      return res.status(404).json({ error: 'Quote not found' });
    }

    const quote = quoteResult.rows[0];
    const now = new Date();
    let currentStatus = quote.status;
    
    if (currentStatus === 'BROADCASTING' && new Date(quote.expires_at) < now) {
      currentStatus = 'EXPIRED';
    }

    res.json({
      quote_id: parseInt(quote_id),
      status: currentStatus,
      expires_at: quote.expires_at,
      responses: result.rows,
    });
  } catch (err) {
    console.error('Get responses error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:quote_id/respond', async (req, res) => {
  try {
    const { quote_id } = req.params;
    const { pharmacy_id, total_price, notes, items } = req.body;

    if (!pharmacy_id || total_price === undefined) {
      return res.status(400).json({ error: 'pharmacy_id and total_price required' });
    }

    const result = await pool.query(
      `UPDATE quote_responses 
       SET total_price = $1, notes = $2, status = 'ACCEPTED', responded_at = NOW()
       WHERE quote_id = $3 AND pharmacy_id = $4
       RETURNING *`,
      [total_price, notes || null, quote_id, pharmacy_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Quote response not found' });
    }

    if (items && Array.isArray(items)) {
      for (const item of items) {
        if (item.is_out_of_stock === true) {
          await pool.query(
            `UPDATE pharmacy_inventory 
             SET is_in_stock = false, updated_at = NOW()
             WHERE pharmacy_id = $1 AND medication_id = $2`,
            [pharmacy_id, item.medication_id]
          );
        }
      }
    }

    res.json({
      success: true,
      response: result.rows[0],
    });
  } catch (err) {
    console.error('Respond to quote error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;