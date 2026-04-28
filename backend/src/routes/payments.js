const express = require('express');
const router = express.Router();
const pool = require('../db/config');

async function addPaymentColumns() {
  try {
    await pool.query(`
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'UNPAID'
      CHECK (payment_status IN ('UNPAID', 'PAID', 'FAILED', 'REFUNDED'));
    `);
    await pool.query(`
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50);
    `);
    await pool.query(`
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(100);
    `);
    await pool.query(`
      ALTER TABLE orders ADD COLUMN IF NOT EXISTS paid_at TIMESTAMP;
    `);
    console.log('Payment columns added to orders table');
  } catch (err) {
    console.log('Payment columns might already exist:', err.message);
  }
}
addPaymentColumns();

router.post('/webhook', async (req, res) => {
  try {
    const { transaction_id, order_id, status, amount, payment_method, signature } = req.body;

    if (!transaction_id || !order_id || !status) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: transaction_id, order_id, status'
      });
    }

    const allowedStatuses = ['PAID', 'FAILED', 'REFUNDED'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status value'
      });
    }

    const orderResult = await pool.query(
      'SELECT id, total_price, payment_status FROM orders WHERE id = $1',
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    const order = orderResult.rows[0];

    if (order.payment_status === 'PAID') {
      return res.status(200).json({
        success: true,
        message: 'Order already paid',
        order_id: order.id
      });
    }

    if (status === 'PAID') {
      await pool.query(
        `UPDATE orders 
         SET payment_status = 'PAID', 
             transaction_id = $1, 
             payment_method = $2, 
             paid_at = NOW(),
             updated_at = NOW()
         WHERE id = $3`,
        [transaction_id, payment_method || 'gateway', order_id]
      );

      console.log(`Payment verified for order ${order_id}: ${transaction_id}`);

      return res.status(200).json({
        success: true,
        message: 'Payment verified successfully',
        order_id: order_id,
        payment_status: 'PAID'
      });
    } else if (status === 'FAILED') {
      await pool.query(
        `UPDATE orders 
         SET payment_status = 'FAILED', 
             transaction_id = $1, 
             updated_at = NOW()
         WHERE id = $2`,
        [transaction_id, order_id]
      );

      return res.status(200).json({
        success: true,
        message: 'Payment failed recorded',
        order_id: order_id,
        payment_status: 'FAILED'
      });
    } else if (status === 'REFUNDED') {
      await pool.query(
        `UPDATE orders 
         SET payment_status = 'REFUNDED', 
             transaction_id = $1, 
             updated_at = NOW()
         WHERE id = $2`,
        [transaction_id, order_id]
      );

      return res.status(200).json({
        success: true,
        message: 'Refund recorded',
        order_id: order_id,
        payment_status: 'REFUNDED'
      });
    }
  } catch (err) {
    console.error('Payment webhook error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

router.get('/verify/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;

    const result = await pool.query(
      `SELECT id, payment_status, transaction_id, payment_method, paid_at, total_price
       FROM orders WHERE id = $1`,
      [orderId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = result.rows[0];
    res.json({
      order_id: order.id,
      payment_status: order.payment_status,
      transaction_id: order.transaction_id,
      payment_method: order.payment_method,
      paid_at: order.paid_at,
      amount: order.total_price
    });
  } catch (err) {
    console.error('Verify payment error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/create-payment', async (req, res) => {
  try {
    const { order_id, payment_method } = req.body;

    if (!order_id) {
      return res.status(400).json({ error: 'order_id required' });
    }

    const orderResult = await pool.query(
      'SELECT id, total_price, payment_status FROM orders WHERE id = $1',
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    if (order.payment_status === 'PAID') {
      return res.status(400).json({ error: 'Order already paid' });
    }

    const mockTransactionId = `TXN_${Date.now()}_${order_id}`;

    res.json({
      success: true,
      transaction_id: mockTransactionId,
      order_id: order_id,
      amount: order.total_price,
      payment_method: payment_method || 'mobile_money',
      callback_url: '/api/payments/webhook'
    });
  } catch (err) {
    console.error('Create payment error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;