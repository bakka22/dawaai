const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.get('/inventory/lookup', async (req, res) => {
  try {
    const { barcode, medication_id, name } = req.query;

    let query = 'SELECT id, name, active_ingredient FROM medications WHERE 1=1';
    const params = [];

    if (barcode) {
      params.push(`%${barcode}%`);
      query += ` AND (name LIKE $${params.length} OR active_ingredient LIKE $${params.length})`;
    } else if (medication_id) {
      params.push(medication_id);
      query += ` AND id = $${params.length}`;
    } else if (name) {
      params.push(`%${name}%`);
      query += ` AND name LIKE $${params.length}`;
    }

    query += ' LIMIT 1';

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.json({ medication: null });
    }

    res.json({ medication: result.rows[0] });
  } catch (err) {
    console.error('Lookup error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/inventory/update', async (req, res) => {
  try {
    const { pharmacy_id, medication_id, is_in_stock, price, quantity } = req.body;

    if (!pharmacy_id || !medication_id) {
      return res.status(400).json({ error: 'pharmacy_id and medication_id required' });
    }

    const existing = await pool.query(
      'SELECT id FROM pharmacy_inventory WHERE pharmacy_id = $1 AND medication_id = $2',
      [pharmacy_id, medication_id]
    );

    if (existing.rows.length === 0) {
      await pool.query(
        `INSERT INTO pharmacy_inventory (pharmacy_id, medication_id, is_in_stock, price, quantity)
         VALUES ($1, $2, $3, $4, $5)`,
        [pharmacy_id, medication_id, is_in_stock ?? true, price ?? null, quantity ?? 0]
      );
    } else {
      let updateQuery = 'UPDATE pharmacy_inventory SET is_in_stock = $1, updated_at = NOW()';
      const params = [is_in_stock];

      if (price !== undefined) {
        params.push(price);
        updateQuery += `, price = $${params.length}`;
      }
      if (quantity !== undefined) {
        params.push(quantity);
        updateQuery += `, quantity = $${params.length}`;
      }

      params.push(pharmacy_id, medication_id);
      updateQuery += ' WHERE pharmacy_id = $' + (params.length - 1) + ' AND medication_id = $' + params.length;

      await pool.query(updateQuery, params);
    }

    res.json({ success: true, message: 'Inventory updated' });
  } catch (err) {
    console.error('Inventory update error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/inventory/:pharmacyId', async (req, res) => {
  try {
    const { pharmacyId } = req.params;

    const pharmacyResult = await pool.query(
      'SELECT id FROM pharmacies WHERE id = $1',
      [pharmacyId]
    );

    if (pharmacyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }

    const result = await pool.query(
      `SELECT pi.id, pi.medication_id, pi.is_in_stock, pi.price, pi.quantity, m.name, m.active_ingredient
       FROM pharmacy_inventory pi
       JOIN medications m ON pi.medication_id = m.id
       WHERE pi.pharmacy_id = $1
       ORDER BY m.name`,
      [pharmacyId]
    );

    res.json({ inventory: result.rows });
  } catch (err) {
    console.error('Get inventory error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;