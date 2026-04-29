const bcrypt = require('bcryptjs');
const pool = require('../db/config');

async function ensureBlacklistTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS token_blacklist (
        id SERIAL PRIMARY KEY,
        token_hash TEXT NOT NULL,
        user_id INTEGER,
        created_at TIMESTAMP DEFAULT NOW(),
        expires_at TIMESTAMP
      )
    `);
    
    // Create indexes for better performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_token_blacklist_token_hash ON token_blacklist(token_hash)
    `);
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_token_blacklist_expires ON token_blacklist(expires_at)
    `);
  } catch (err) {
    console.error('Error creating token blacklist table:', err);
    // Don't fail the app if table creation fails, but log it
  }
}

// Call the ensure function and handle its promise
ensureBlacklistTable().catch(err => {
  console.error('Failed to initialize token blacklist table:', err);
});

async function isTokenBlacklisted(token) {
  try {
    const tokenHash = await bcrypt.hash(token, 10);
    const result = await pool.query(
      'SELECT 1 FROM token_blacklist WHERE token_hash = $1',
      [tokenHash]
    );
    return result.rows.length > 0;
  } catch (err) {
    return false;
  }
}

async function addToBlacklist(token, userId) {
  const tokenHash = await bcrypt.hash(token, 10);
  const jwt = require('jsonwebtoken');
  
  let expiresAt = new Date(Date.now() + 3600000);
  try {
    const decoded = jwt.decode(token);
    if (decoded && decoded.exp) {
      expiresAt = new Date(decoded.exp * 1000);
    }
  } catch (e) {}
  
  try {
    await pool.query(
      'INSERT INTO token_blacklist (token_hash, user_id, expires_at) VALUES ($1, $2, $3)',
      [tokenHash, userId, expiresAt]
    );
  } catch (err) {
    console.error('Blacklist add error:', err.message);
  }
}

module.exports = {
  isTokenBlacklisted,
  addToBlacklist
};