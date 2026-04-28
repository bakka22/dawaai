const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.post('/profile', async (req, res) => {
  try {
    const { user_id, skin_type, concerns } = req.body;

    if (!user_id) {
      return res.status(400).json({ error: 'user_id required' });
    }

    await pool.query(
      `UPDATE users 
       SET skin_type = $1, concerns = $2, has_completed_quiz = true, updated_at = NOW()
       WHERE id = $3`,
      [skin_type || null, JSON.stringify(concerns || []), user_id]
    );

    res.json({ success: true, message: 'Profile updated' });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/profile/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      'SELECT id, phone, role, skin_type, concerns, has_completed_quiz FROM users WHERE id = $1',
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;