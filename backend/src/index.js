require('dotenv').config();
const express = require('express');
const cors = require('cors');
require('./services/storageService');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const relayRoutes = require('./routes/relay');
const authRoutes = require('./routes/auth');
const medsRoutes = require('./routes/meds');
const searchRoutes = require('./routes/search');
const quotesRoutes = require('./routes/quotes');

app.use('/api', relayRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/meds', medsRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/quotes', quotesRoutes);

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