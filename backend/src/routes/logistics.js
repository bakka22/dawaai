const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.post('/plan-trip', async (req, res) => {
  try {
    const { order_id, customer_lat, customer_lng } = req.body;

    if (!order_id) {
      return res.status(400).json({ error: 'order_id required' });
    }

    const orderResult = await pool.query(
      `SELECT o.id, o.status, 
              array_agg(os.pharmacy_id) as pharmacy_ids,
              array_agg(p.lat) as pharmacy_lats,
              array_agg(p.lng) as pharmacy_lngs,
              array_agg(p.name) as pharmacy_names
       FROM orders o
       JOIN order_segments os ON o.id = os.order_id
       JOIN pharmacies p ON os.pharmacy_id = p.id
       WHERE o.id = $1
       GROUP BY o.id`,
      [order_id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    const flaggedMedsResult = await pool.query(
      `SELECT DISTINCT m.is_flagged, m.name
       FROM order_items oi
       JOIN medications m ON oi.medication_id = m.id
       WHERE oi.order_id = $1`,
      [order_id]
    );

    const hasFlaggedMeds = flaggedMedsResult.rows.some(m => m.is_flagged);

    const pharmacyStops = [];
    const orderPharmacies = order.pharmacy_ids || [];
    const orderLats = order.pharmacy_lats || [];
    const orderLngs = order.pharmacy_lngs || [];
    const orderNames = order.pharmacy_names || [];

    for (let i = 0; i < orderPharmacies.length; i++) {
      pharmacyStops.push({
        order: i + 1,
        pharmacy_id: orderPharmacies[i],
        pharmacy_name: orderNames[i],
        lat: parseFloat(orderLats[i]),
        lng: parseFloat(orderLngs[i]),
      });
    }

    const waypoints = [];
    const instructions = [];

    if (hasFlaggedMeds) {
      instructions.push({
        step: 1,
        type: 'START',
        message: 'بدء الرحلة - يتطلب توصيل أدوية خاضعة للتنظيم',
      });

      instructions.push({
        step: 2,
        type: 'CUSTOMER_COLLECT_PAPER',
        message: 'التوجه للعميل أولاً لجمع الوصفة الطبية الأصلية',
        location: customer_lat && customer_lng ? {
          lat: parseFloat(customer_lat),
          lng: parseFloat(customer_lng),
        } : null,
      });

      instructions.push({
        step: 3,
        type: 'PHARMACY_EXCHANGE',
        message: 'التوجه للصيدلية لاستبدال الوصفة بالأدوية',
        waypoints: pharmacyStops,
      });

      instructions.push({
        step: 4,
        type: 'CUSTOMER_DELIVER',
        message: 'التوجه للعميل لتسليم الأدوية',
        location: customer_lat && customer_lng ? {
          lat: parseFloat(customer_lat),
          lng: parseFloat(customer_lng),
        } : null,
      });

      instructions.push({
        step: 5,
        type: 'COMPLETE',
        message: 'اكتمال التوصيل - تذكير: يجب الاحتفاظ بنسخة من الوصفة',
      });
    } else {
      instructions.push({
        step: 1,
        type: 'START',
        message: 'بدء الرحلة',
      });

      instructions.push({
        step: 2,
        type: 'PHARMACY_PICKUP',
        message: 'التقاط الأدوية من الصيدلية',
        waypoints: pharmacyStops,
      });

      instructions.push({
        step: 3,
        type: 'CUSTOMER_DELIVER',
        message: 'توصيل الأدوية للعميل',
        location: customer_lat && customer_lng ? {
          lat: parseFloat(customer_lat),
          lng: parseFloat(customer_lng),
        } : null,
      });

      instructions.push({
        step: 4,
        type: 'COMPLETE',
        message: 'اكتمال التوصيل',
      });
    }

    const tripType = hasFlaggedMeds ? 'TRIPLE_LEG_REGULATED' : 'STANDARD';

    res.json({
      order_id: order.id,
      trip_type: tripType,
      has_regulated_medications: hasFlaggedMeds,
      regulated_medications: flaggedMedsResult.rows
        .filter(m => m.is_flagged)
        .map(m => m.name),
      waypoints: pharmacyStops,
      instructions,
      delivery_mode: hasFlaggedMeds 
        ? 'Regulated: Collect Paper → Pharmacy → Customer' 
        : 'Standard: Pharmacy → Customer',
    });
  } catch (err) {
    console.error('Plan trip error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;