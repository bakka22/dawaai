const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('../db/config');
const { isTokenBlacklisted, addToBlacklist } = require('../services/tokenBlacklist');

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

function normalizePhoneNumber(phone) {
  const digits = phone.replace(/\D/g, '');
  
  if (digits.length === 10 && digits.startsWith('0')) {
    return '+249' + digits.substring(1);
  }
  
  if (phone.startsWith('+')) {
    return phone;
  }
  
  if (digits.length === 12 && digits.startsWith('249')) {
    return '+' + digits;
  }
  
  if (digits.length === 9 && /^[987]/.test(digits)) {
    return '+249' + digits;
  }
  
  return phone;
}


router.post('/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    const normalizedPhone = normalizePhoneNumber(phone);

    if (!normalizedPhone || !password) {
      return res.status(400).json({ error: 'Phone and password required' });
    }

    const result = await pool.query(
      'SELECT id, phone, role, password_hash, refresh_token_hash FROM users WHERE phone = $1',
      [normalizedPhone]
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
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }
    console.error('Refresh error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/register', async (req, res) => {
  try {
    const { phone, password, role = 'customer', name } = req.body;

    // Normalize phone number to ensure consistent format
    const normalizedPhone = normalizePhoneNumber(phone);

    if (!normalizedPhone || !password) {
      return res.status(400).json({ error: 'Phone and password required' });
    }

    const validRoles = ['customer', 'pharmacist', 'admin'];
    if (role && !validRoles.includes(role)) {
      return res.status(400).json({ error: 'Invalid role. Must be customer, pharmacist, or admin' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (phone, role, password_hash, refresh_token_hash) 
       VALUES ($1, $2, $3, $3) 
       RETURNING id, phone, role`,
      [normalizedPhone, role, hashedPassword]
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

router.post('/logout', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authorization token required' });
    }
    
    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'Token required' });
    }
    
    let userId = null;
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      userId = decoded.id;
    } catch (e) {
      // If token is invalid, we still want to blacklist it based on the token itself
      // In a real implementation, we might not be able to get userId from an invalid token
    }
    
    await addToBlacklist(token, userId);
    
    res.json({
      success: true,
      message: 'Logged out successfully. Token has been blacklisted.'
    });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authorization token required' });
    }

    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'Token required' });
    }

    const isBlacklisted = await isTokenBlacklisted(token);
    if (isBlacklisted) {
      return res.status(401).json({ error: 'Token has been revoked' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const result = await pool.query(
      'SELECT id, phone, role FROM users WHERE id = $1',
      [decoded.id]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    console.error('Get me error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;