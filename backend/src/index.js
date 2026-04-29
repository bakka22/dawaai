require('dotenv').config();
const express = require('express');
const cors = require('cors');
require('./services/storageService');
const logger = require('./middleware/logger');
const authMiddleware = require('./middleware/authMiddleware');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(logger);

const relayRoutes = require('./routes/relay');
const authRoutes = require('./routes/auth');
const medsRoutes = require('./routes/meds');
const searchRoutes = require('./routes/search');
const quotesRoutes = require('./routes/quotes');
const ordersRoutes = require('./routes/orders');
const logisticsRoutes = require('./routes/logistics');
const userRoutes = require('./routes/user');
const cosmeticsRoutes = require('./routes/cosmetics');
const pharmacistRoutes = require('./routes/pharmacist');
const paymentsRoutes = require('./routes/payments');
const adminRoutes = require('./routes/admin');

// Public routes (no authentication required)
app.use('/api', relayRoutes);
app.use('/api/auth', authRoutes);

// Protected routes (require authentication)
app.use('/api/meds', authMiddleware, medsRoutes);
app.use('/api/search', authMiddleware, searchRoutes);
app.use('/api/quotes', authMiddleware, quotesRoutes);
app.use('/api/orders', authMiddleware, ordersRoutes);
app.use('/api/logistics', authMiddleware, logisticsRoutes);
app.use('/api/user', authMiddleware, userRoutes);
app.use('/api/cosmetics', authMiddleware, cosmeticsRoutes);
app.use('/api/pharmacist', authMiddleware, pharmacistRoutes);
app.use('/api/payments', authMiddleware, paymentsRoutes);
app.use('/api/admin', authMiddleware, adminRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/', (req, res) => {
  res.json({ message: 'Dawaai API running' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;