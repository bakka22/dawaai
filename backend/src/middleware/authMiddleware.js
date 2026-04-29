const jwt = require('jsonwebtoken');
const { isTokenBlacklisted } = require('../services/tokenBlacklist');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization token required' });
  }

  const token = authHeader.slice(7);
  
  if (!token || token.trim() === '') {
    return res.status(401).json({ error: 'Token required' });
  }

  if (token === 'null' || token === 'undefined') {
    return res.status(401).json({ error: 'Invalid token' });
  }

  isTokenBlacklisted(token)
    .then(isBlacklisted => {
      if (isBlacklisted) {
        return res.status(401).json({ error: 'Token has been revoked' });
      }

      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
      } catch (err) {
        if (err.name === 'TokenExpiredError') {
          return res.status(401).json({ error: 'Token expired' });
        }
        if (err.name === 'JsonWebTokenError') {
          return res.status(401).json({ error: 'Invalid token' });
        }
        return res.status(401).json({ error: 'Token verification failed' });
      }
    })
    .catch(err => {
      console.error('Auth middleware error:', err);
      return res.status(500).json({ error: 'Internal server error' });
    });
}

module.exports = authMiddleware;