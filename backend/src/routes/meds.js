const express = require('express');
const router = express.Router();
const pool = require('../db/config');

router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({ error: 'Search query required' });
    }

    const searchTerm = q.trim();

    const result = await pool.query(
      `SELECT id, name, active_ingredient, synonyms, is_flagged
       FROM medications
       WHERE similarity(name, $1) > 0.3
          OR similarity(active_ingredient, $1) > 0.3
          OR ($1 % name)
          OR name ILIKE '%' || $1 || '%'
          OR active_ingredient ILIKE '%' || $1 || '%'
       ORDER BY similarity(name, $1) DESC, similarity(active_ingredient, $1) DESC
       LIMIT 50`,
      [searchTerm]
    );

    res.json({
      query: searchTerm,
      count: result.rows.length,
      results: result.rows
    });
  } catch (err) {
    console.error('Medication search error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;