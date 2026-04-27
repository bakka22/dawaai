const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.post('/create', async (req, res) => {
  try {
    const { customer_id, quote_id, quote_response_id, pharmacy_id, medications, total_price, notes } = req.body;

    if (!customer_id || !pharmacy_id || !medications || !Array.isArray(medications)) {
      return res.status(400).json({ error: 'customer_id, pharmacy_id and medications array required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const quoteResult = await client.query(
        `UPDATE quotes SET status = 'ACCEPTED', updated_at = NOW() 
         WHERE id = $1 AND status = 'BROADCASTING' 
         RETURNING id`,
        [quote_id]
      );

      if (quoteResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Quote not found or already accepted' });
      }

      await client.query(
        `UPDATE quote_responses SET status = 'ACCEPTED', responded_at = NOW() 
         WHERE id = $1 AND quote_id = $2`,
        [quote_response_id, quote_id]
      );

      const orderResult = await client.query(
        `INSERT INTO orders (customer_id, pharmacy_id, quote_id, status, total_price, notes, created_at)
         VALUES ($1, $2, $3, 'PENDING', $4, $5, NOW())
         RETURNING id, status, created_at`,
        [customer_id, pharmacy_id, quote_id, total_price || 0, notes || null]
      );

      const order = orderResult.rows[0];

      for (const med of medications) {
        await client.query(
          `INSERT INTO order_items (order_id, medication_id, quantity, price)
           VALUES ($1, $2, $3, $4)`,
          [order.id, med.medication_id, med.quantity || 1, med.price || 0]
        );
      }

      await client.query('COMMIT');

      res.json({
        order_id: order.id,
        status: order.status,
        created_at: order.created_at,
        message: 'Order created successfully',
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('Create order error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/customer/:customer_id', async (req, res) => {
  try {
    const { customer_id } = req.params;
    const { status } = req.query;

    let query = `
      SELECT o.*, p.name as pharmacy_name, p.city as pharmacy_city
      FROM orders o
      JOIN pharmacies p ON o.pharmacy_id = p.id
      WHERE o.customer_id = $1
    `;
    const params = [customer_id];

    if (status) {
      query += ' AND o.status = $2';
      params.push(status);
    }

    query += ' ORDER BY o.created_at DESC';

    const result = await pool.query(query, params);

    res.json({
      orders: result.rows,
    });
  } catch (err) {
    console.error('Get customer orders error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:order_id', async (req, res) => {
  try {
    const { order_id } = req.params;

    const orderResult = await pool.query(
      `SELECT o.*, p.name as pharmacy_name, p.city as pharmacy_city, p.phone as pharmacy_phone
       FROM orders o
       JOIN pharmacies p ON o.pharmacy_id = p.id
       WHERE o.id = $1`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const itemsResult = await pool.query(
      `SELECT oi.*, m.name as medication_name
       FROM order_items oi
       JOIN medications m ON oi.medication_id = m.id
       WHERE oi.order_id = $1`,
      [order_id]
    );

    res.json({
      order: orderResult.rows[0],
      items: itemsResult.rows,
    });
  } catch (err) {
    console.error('Get order error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;