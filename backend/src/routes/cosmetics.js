const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.get('/recommendations', async (req, res) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({ error: 'user_id required' });
    }

    const userResult = await pool.query(
      'SELECT skin_type, concerns FROM users WHERE id = $1',
      [user_id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const { skin_type, concerns } = userResult.rows[0];
    const concernsArray = concerns || [];

    let query = `
      SELECT id, name, brand, target_skin_type, concerns, price, description, image_url
      FROM cosmetic_products
      WHERE is_active = true
    `;
    const params = [];

    if (skin_type) {
      params.push(skin_type);
      query += ` AND (target_skin_type = $${params.length} OR target_skin_type IS NULL OR target_skin_type = 'all')`;
    }

    if (concernsArray.length > 0) {
      for (const concern of concernsArray) {
        params.push(`%${concern}%`);
        query += ` AND concerns::text LIKE $${params.length}`;
      }
    }

    query += ' ORDER BY price ASC LIMIT 20';

    const result = await pool.query(query, params);

    const products = result.rows.map(product => {
      const productConcerns = product.concerns || [];
      const matchedConcerns = concernsArray.filter(c =>
        productConcerns.some(pc => pc.toLowerCase().includes(c.toLowerCase()))
      );

      let whyThis = [];
      if (product.target_skin_type === skin_type) {
        if (skin_type === 'sensitive') {
          whyThis.push('آمن للبشرة الحساسة');
        } else if (skin_type === 'dry') {
          whyThis.push('مرطب intensivo');
        } else if (skin_type === 'oily') {
          whyThis.push('مضحب للزيت');
        } else if (skin_type === 'combination') {
          whyThis.push('مناسب للبشرة المختلطة');
        }
      }
      if (matchedConcerns.length > 0) {
        whyThis.push(`يعالج: ${matchedConcerns.join(', ')}`);
      }
      if (!product.target_skin_type || product.target_skin_type === 'all') {
        whyThis.push('مناسب لجميع أنواع البشرة');
      }

      return {
        ...product,
        why_this: whyThis,
      };
    });

    res.json({ products });
  } catch (err) {
    console.error('Get recommendations error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, brand, target_skin_type, concerns, price, description, image_url
       FROM cosmetic_products
       WHERE is_active = true
       ORDER BY created_at DESC LIMIT 50`
    );
    res.json({ products: result.rows });
  } catch (err) {
    console.error('Get cosmetics error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM cosmetic_products WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product: result.rows[0] });
  } catch (err) {
    console.error('Get cosmetic error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;