const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.get('/pharmacies', async (req, res) => {
  try {
    const { status, city } = req.query;
    
    let query = `
      SELECT p.id, p.name, p.city, p.address, p.phone, p.lat, p.lng, 
             p.is_approved, p.created_at,
             u.phone as owner_phone
      FROM pharmacies p
      JOIN users u ON p.owner_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (status === 'pending') {
      query += ' AND p.is_approved = false';
    } else if (status === 'approved') {
      query += ' AND p.is_approved = true';
    }

    if (city) {
      params.push(`%${city}%`);
      query += ` AND p.city LIKE $${params.length}`;
    }

    query += ' ORDER BY p.created_at DESC';

    const result = await pool.query(query, params);
    res.json({ pharmacies: result.rows });
  } catch (err) {
    console.error('Get pharmacies error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/pharmacies/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT p.*, u.phone as owner_phone, u.role as owner_role
       FROM pharmacies p
       JOIN users u ON p.owner_id = u.id
       WHERE p.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }

    const pharmacy = result.rows[0];

    const inventoryCount = await pool.query(
      'SELECT COUNT(*) as count FROM pharmacy_inventory WHERE pharmacy_id = $1',
      [id]
    );

    const inStockCount = await pool.query(
      'SELECT COUNT(*) as count FROM pharmacy_inventory WHERE pharmacy_id = $1 AND is_in_stock = true',
      [id]
    );

    res.json({
      pharmacy: {
        ...pharmacy,
        total_medications: parseInt(inventoryCount.rows[0].count),
        in_stock_count: parseInt(inStockCount.rows[0].count)
      }
    });
  } catch (err) {
    console.error('Get pharmacy error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/pharmacies/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { approved, reason } = req.body;

    if (approved !== true && approved !== false) {
      return res.status(400).json({ error: 'approved must be boolean' });
    }

    const existing = await pool.query(
      'SELECT id, is_approved FROM pharmacies WHERE id = $1',
      [id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }

    await pool.query(
      'UPDATE pharmacies SET is_approved = $1, updated_at = NOW() WHERE id = $2',
      [approved, id]
    );

    const statusText = approved ? 'موافق عليه' : 'مرفوض';
    console.log(`Pharmacy ${id} ${statusText}${reason ? `: ${reason}` : ''}`);

    res.json({
      success: true,
      pharmacy_id: id,
      is_approved: approved,
      message: approved ? 'Pharmacy approved successfully' : 'Pharmacy rejected'
    });
  } catch (err) {
    console.error('Approve pharmacy error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const totalPharmacies = await pool.query(
      'SELECT COUNT(*) as count FROM pharmacies'
    );
    const approvedPharmacies = await pool.query(
      'SELECT COUNT(*) as count FROM pharmacies WHERE is_approved = true'
    );
    const pendingPharmacies = await pool.query(
      'SELECT COUNT(*) as count FROM pharmacies WHERE is_approved = false'
    );
    const totalOrders = await pool.query(
      'SELECT COUNT(*) as count FROM orders'
    );
    const completedOrders = await pool.query(
      "SELECT COUNT(*) as count FROM orders WHERE status = 'COMPLETED'"
    );
    const totalUsers = await pool.query(
      "SELECT COUNT(*) as count FROM users WHERE role = 'customer'"
    );

    res.json({
      stats: {
        total_pharmacies: parseInt(totalPharmacies.rows[0].count),
        approved_pharmacies: parseInt(approvedPharmacies.rows[0].count),
        pending_pharmacies: parseInt(pendingPharmacies.rows[0].count),
        total_orders: parseInt(totalOrders.rows[0].count),
        completed_orders: parseInt(completedOrders.rows[0].count),
        total_customers: parseInt(totalUsers.rows[0].count)
      }
    });
  } catch (err) {
    console.error('Get stats error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;