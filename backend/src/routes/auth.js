const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('../db/config');

const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '30d';

function generateAccessToken(user) {
  return jwt.sign(
    { id: user.id, phone: user.phone, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );
}

function generateRefreshToken(user) {
  return jwt.sign(
    { id: user.id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );
}

router.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ error: 'Phone and password required' });
    }

    const result = await pool.query(
      'SELECT id, phone, role, password_hash, refresh_token_hash FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    const hashedRefresh = await bcrypt.hash(refreshToken, 10);
    await pool.query(
      'UPDATE users SET refresh_token_hash = $1, updated_at = NOW() WHERE id = $2',
      [hashedRefresh, user.id]
    );

    res.json({
      accessToken,
      refreshToken,
      user: { id: user.id, phone: user.phone, role: user.role }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    const result = await pool.query(
      'SELECT id, phone, role, refresh_token_hash FROM users WHERE id = $1',
      [decoded.id]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }

    const user = result.rows[0];
    const validToken = await bcrypt.compare(refreshToken, user.refresh_token_hash);

    if (!validToken) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    const accessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);

    const hashedRefresh = await bcrypt.hash(newRefreshToken, 10);
    await pool.query(
      'UPDATE users SET refresh_token_hash = $1, updated_at = NOW() WHERE id = $2',
      [hashedRefresh, user.id]
    );

    res.json({ accessToken, refreshToken: newRefreshToken });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Refresh token expired' });
    }
    console.error('Refresh error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/register', async (req, res) => {
  try {
    const { phone, password, role = 'customer', name } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ error: 'Phone and password required' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (phone, role, password_hash, refresh_token_hash) 
       VALUES ($1, $2, $3, $3) 
       RETURNING id, phone, role`,
      [phone, role, hashedPassword]
    );

    const user = result.rows[0];
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    const hashedRefresh = await bcrypt.hash(refreshToken, 10);
    await pool.query(
      'UPDATE users SET refresh_token_hash = $1, updated_at = NOW() WHERE id = $2',
      [hashedRefresh, user.id]
    );

    res.status(201).json({
      accessToken,
      refreshToken,
      user: { id: user.id, phone: user.phone, role: user.role }
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Phone already registered' });
    }
    console.error('Register error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;