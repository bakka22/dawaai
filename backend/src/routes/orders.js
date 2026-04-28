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

      await client.query(
        `INSERT INTO order_segments (order_id, pharmacy_id, status, subtotal)
         VALUES ($1, $2, 'PENDING', $3)`,
        [order.id, pharmacy_id, total_price || 0]
      );

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

router.get('/:order_id/invoice', async (req, res) => {
  try {
    const { order_id } = req.params;

    const orderResult = await pool.query(
      `SELECT o.*, u.phone as customer_phone
       FROM orders o
       JOIN users u ON o.customer_id = u.id
       WHERE o.id = $1`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    const segmentsResult = await pool.query(
      `SELECT os.*, p.name as pharmacy_name, p.city as pharmacy_city
       FROM order_segments os
       JOIN pharmacies p ON os.pharmacy_id = p.id
       WHERE os.order_id = $1`,
      [order_id]
    );

    const itemsResult = await pool.query(
      `SELECT oi.*, m.name as medication_name
       FROM order_items oi
       JOIN medications m ON oi.medication_id = m.id
       WHERE oi.order_id = $1`,
      [order_id]
    );

    const segments = segmentsResult.rows;
    const items = itemsResult.rows;

    const subtotal = parseFloat(order.total_price) || 0;
    const deliveryFee = parseFloat(order.delivery_fee) || 0;
    const total = subtotal + deliveryFee;

    res.json({
      invoice: {
        order_id: order.id,
        status: order.status,
        created_at: order.created_at,
        customer_phone: order.customer_phone,
      },
      segments: segments.map(s => ({
        segment_id: s.id,
        pharmacy_name: s.pharmacy_name,
        pharmacy_city: s.pharmacy_city,
        status: s.status,
        subtotal: parseFloat(s.subtotal) || 0,
        delivery_fee: parseFloat(s.delivery_fee) || 0,
      })),
      items: items.map(i => ({
        medication_name: i.medication_name,
        quantity: i.quantity,
        price: parseFloat(i.price) || 0,
      })),
      summary: {
        subtotal,
        delivery_fee: deliveryFee,
        total,
        currency: 'SDG',
      },
    });
  } catch (err) {
    console.error('Get invoice error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:order_id/accept', async (req, res) => {
  try {
    const { order_id } = req.params;
    const { pharmacy_id } = req.body;

    if (!pharmacy_id) {
      return res.status(400).json({ error: 'pharmacy_id required' });
    }

    const result = await pool.query(
      `UPDATE order_segments 
       SET status = 'CONFIRMED', updated_at = NOW()
       WHERE order_id = $1 AND pharmacy_id = $2
       RETURNING *`,
      [order_id, pharmacy_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Segment not found' });
    }

    const allSegments = await pool.query(
      `SELECT status FROM order_segments WHERE order_id = $1`,
      [order_id]
    );

    const allConfirmed = allSegments.rows.every(s => s.status === 'CONFIRMED');
    if (allConfirmed) {
      await pool.query(
        `UPDATE orders SET status = 'CONFIRMED', updated_at = NOW() WHERE id = $1`,
        [order_id]
      );
    }

    res.json({ success: true, segment: result.rows[0] });
  } catch (err) {
    console.error('Accept segment error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:order_id/prepare', async (req, res) => {
  try {
    const { order_id } = req.params;
    const { pharmacy_id } = req.body;

    if (!pharmacy_id) {
      return res.status(400).json({ error: 'pharmacy_id required' });
    }

    const result = await pool.query(
      `UPDATE order_segments 
       SET status = 'READY', updated_at = NOW()
       WHERE order_id = $1 AND pharmacy_id = $2
       RETURNING *`,
      [order_id, pharmacy_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Segment not found' });
    }

    await pool.query(
      `UPDATE orders SET status = 'PREPARING', updated_at = NOW() WHERE id = $1`,
      [order_id]
    );

    res.json({ success: true, segment: result.rows[0] });
  } catch (err) {
    console.error('Prepare segment error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:order_id/verify-delivery', async (req, res) => {
  try {
    const { order_id } = req.params;
    const { driver_id, prescription_photo_url, signature_confirmed } = req.body;

    if (!driver_id) {
      return res.status(400).json({ error: 'driver_id required' });
    }

    const orderResult = await pool.query(
      'SELECT status FROM orders WHERE id = $1',
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const currentStatus = orderResult.rows[0].status;
    const allowedStatuses = ['READY_FOR_PICKUP', 'DISPATCHED'];

    if (!allowedStatuses.includes(currentStatus)) {
      return res.status(400).json({ 
        error: `Cannot verify delivery. Current status: ${currentStatus}` 
      });
    }

    if (prescription_photo_url) {
      await pool.query(
        `INSERT INTO order_delivery_proofs (order_id, driver_id, proof_type, proof_url, created_at)
         VALUES ($1, $2, 'PRESCRIPTION_PHOTO', $3, NOW())
         ON CONFLICT (order_id) DO UPDATE SET proof_url = $3, updated_at = NOW()`,
        [order_id, driver_id, prescription_photo_url]
      );
    }

    if (signature_confirmed) {
      await pool.query(
        `INSERT INTO order_delivery_proofs (order_id, driver_id, proof_type, created_at)
         VALUES ($1, $2, 'SIGNATURE', 'confirmed', NOW())
         ON CONFLICT (order_id) DO UPDATE SET proof_type = 'SIGNATURE', updated_at = NOW()`,
        [order_id, driver_id]
      );
    }

    res.json({
      success: true,
      message: 'Delivery verification recorded',
      requires_photo: !prescription_photo_url,
    });
  } catch (err) {
    console.error('Verify delivery error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:order_id/complete', async (req, res) => {
  try {
    const { order_id } = req.params;
    const { driver_id } = req.body;

    if (!driver_id) {
      return res.status(400).json({ error: 'driver_id required' });
    }

    const proofResult = await pool.query(
      'SELECT * FROM order_delivery_proofs WHERE order_id = $1',
      [order_id]
    );

    if (proofResult.rows.length === 0) {
      return res.status(400).json({ 
        error: 'Cannot complete order. No delivery proof recorded.' 
      });
    }

    const hasPhoto = proofResult.rows.some(p => p.proof_type === 'PRESCRIPTION_PHOTO');
    const hasSignature = proofResult.rows.some(p => p.proof_type === 'SIGNATURE');

    if (!hasPhoto) {
      return res.status(400).json({ 
        error: 'Cannot complete order. Prescription photo is required.' 
      });
    }

    await pool.query('BEGIN');

    await pool.query(
      `UPDATE orders SET status = 'COMPLETED', updated_at = NOW() WHERE id = $1`,
      [order_id]
    );

    await pool.query(
      `UPDATE order_segments SET status = 'DELIVERED', updated_at = NOW() WHERE order_id = $1`,
      [order_id]
    );

    await pool.query('COMMIT');

    res.json({
      success: true,
      message: 'Order completed successfully',
      status: 'COMPLETED',
    });
  } catch (err) {
    await pool.query('ROLLBACK');
    console.error('Complete order error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:order_id/trip-status', async (req, res) => {
  try {
    const { order_id } = req.params;

    const orderResult = await pool.query(
      `SELECT o.id, o.status, o.customer_id, u.phone as customer_phone
       FROM orders o
       JOIN users u ON o.customer_id = u.id
       WHERE o.id = $1`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const segmentsResult = await pool.query(
      `SELECT os.*, p.name as pharmacy_name, p.phone as pharmacy_phone
       FROM order_segments os
       JOIN pharmacies p ON os.pharmacy_id = p.id
       WHERE os.order_id = $1`,
      [order_id]
    );

    const proofResult = await pool.query(
      'SELECT * FROM order_delivery_proofs WHERE order_id = $1',
      [order_id]
    );

    const order = orderResult.rows[0];
    const segments = segmentsResult.rows;
    const proofs = proofResult.rows;

    res.json({
      order_id: order.id,
      status: order.status,
      customer_phone: order.customer_phone,
      segments: segments.map(s => ({
        pharmacy_name: s.pharmacy_name,
        pharmacy_phone: s.pharmacy_phone,
        status: s.status,
      })),
      delivery_proof: {
        prescription_photo: proofs.some(p => p.proof_type === 'PRESCRIPTION_PHOTO'),
        signature: proofs.some(p => p.proof_type === 'SIGNATURE'),
      },
      can_complete: order.status === 'READY_FOR_PICKUP' && proofs.some(p => p.proof_type === 'PRESCRIPTION_PHOTO'),
    });
  } catch (err) {
    console.error('Trip status error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:order_id/status', async (req, res) => {
  try {
    const { order_id } = req.params;
    const parsedId = parseInt(order_id);

    if (isNaN(parsedId) || parsedId <= 0) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    const orderResult = await pool.query(
      `SELECT o.*, u.phone as customer_phone
       FROM orders o
       JOIN users u ON o.customer_id = u.id
       WHERE o.id = $1`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    const segmentsResult = await pool.query(
      `SELECT os.*, p.name as pharmacy_name, p.lat as lat, p.lng as lng
       FROM order_segments os
       JOIN pharmacies p ON os.pharmacy_id = p.id
       WHERE os.order_id = $1`,
      [order_id]
    );

    const itemsResult = await pool.query(
      `SELECT oi.*, m.name as medication_name, m.is_flagged
       FROM order_items oi
       JOIN medications m ON oi.medication_id = m.id
       WHERE oi.order_id = $1`,
      [order_id]
    );

    const isHighRisk = itemsResult.rows.some(i => i.is_flagged);

    const activeStatuses = ['PENDING', 'PREPARING', 'READY_FOR_PICKUP', 'IN_TRANSIT', 'DISPATCHED'];
    const isActive = activeStatuses.includes(order.status);

    const waypoints = segmentsResult.rows.map((s, index) => ({
      type: s.status === 'PENDING' ? 'pharmacy' : 'pharmacy',
      name: s.pharmacy_name,
      lat: parseFloat(s.lat) || 0,
      lng: parseFloat(s.lng) || 0,
      order: index + 1,
      status: s.status,
    }));

    if (order.status === 'IN_TRANSIT' || order.status === 'DISPATCHED') {
      waypoints.push({
        type: 'customer',
        name: 'Delivery Location',
        order: waypoints.length + 1,
      });
    }

    const response = {
      order_id: order.id,
      status: order.status,
      current_waypoint: order.status === 'IN_TRANSIT' || order.status === 'DISPATCHED' 
        ? waypoints.length - 1 
        : 0,
      is_high_risk: isHighRisk,
    };

    if (isActive) {
      response.waypoints = waypoints;
    }

    if (order.status === 'IN_TRANSIT' || order.status === 'DISPATCHED') {
      const now = new Date();
      const estimatedMinutes = 30;
      const estimatedArrival = new Date(now.getTime() + estimatedMinutes * 60000);
      response.estimated_arrival = estimatedArrival.toISOString();
    }

    res.json(response);
  } catch (err) {
    console.error('Order status error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/:order_id/confirm-prescription', async (req, res) => {
  try {
    const { order_id } = req.params;
    const { driver_id } = req.body;
    const parsedId = parseInt(order_id);

    if (isNaN(parsedId) || parsedId <= 0) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    if (!driver_id) {
      return res.status(400).json({ error: 'driver_id required' });
    }

    const checkResult = await pool.query(
      'SELECT prescription_confirmed FROM orders WHERE id = $1',
      [order_id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (checkResult.rows[0].prescription_confirmed === true) {
      return res.json({
        success: true,
        already_confirmed: true,
        message: 'Prescription already confirmed',
      });
    }

    await pool.query(
      `UPDATE orders 
       SET prescription_confirmed = true, 
           prescription_confirmed_at = NOW(),
           updated_at = NOW()
       WHERE id = $1`,
      [order_id]
    );

    res.json({
      success: true,
      prescription_confirmed: true,
      message: 'Prescription handover confirmed',
    });
  } catch (err) {
    console.error('Confirm prescription error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:order_id/pharmacy-address', async (req, res) => {
  try {
    const { order_id } = req.params;
    const parsedId = parseInt(order_id);

    if (isNaN(parsedId) || parsedId <= 0) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    const orderResult = await pool.query(
      'SELECT prescription_confirmed, status FROM orders WHERE id = $1',
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const isConfirmed = orderResult.rows[0].prescription_confirmed === true;
    
    if (!isConfirmed) {
      return res.status(403).json({
        error: 'Prescription must be confirmed before viewing pharmacy address',
        requires_confirmation: true,
      });
    }

    const segmentResult = await pool.query(
      `SELECT os.*, p.name as pharmacy_name, p.address as pharmacy_address, 
              p.phone as pharmacy_phone, p.lat, p.lng
       FROM order_segments os
       JOIN pharmacies p ON os.pharmacy_id = p.id
       WHERE os.order_id = $1
       ORDER BY os.id ASC
       LIMIT 1`,
      [order_id]
    );

    if (segmentResult.rows.length === 0) {
      return res.status(404).json({ error: 'No pharmacy segments found' });
    }

    const segment = segmentResult.rows[0];

    res.json({
      pharmacy_name: segment.pharmacy_name,
      pharmacy_address: segment.pharmacy_address,
      pharmacy_phone: segment.pharmacy_phone,
      lat: parseFloat(segment.lat) || 0,
      lng: parseFloat(segment.lng) || 0,
    });
  } catch (err) {
    console.error('Pharmacy address error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;