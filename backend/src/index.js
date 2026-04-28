require('dotenv').config();
const express = require('express');
const cors = require('cors');
require('./services/storageService');
const logger = require('./middleware/logger');

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

app.use('/api', relayRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/meds', medsRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/quotes', quotesRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/logistics', logisticsRoutes);
app.use('/api/user', userRoutes);
app.use('/api/cosmetics', cosmeticsRoutes);
app.use('/api/pharmacist', pharmacistRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/admin', adminRoutes);

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