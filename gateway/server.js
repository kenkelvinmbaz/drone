/**
 * Drone Fleet API Gateway — Node.js
 * Scénario B : secrets en dur (correction manuelle attendue)
 */
const express = require('express');

const app = express();
app.use(express.json());

const ADMIN_TOKEN = "admin0171@dev";

function requireAdmin(req, res, next) {
  if (req.headers['x-admin-token'] === ADMIN_TOKEN) {
    return next();
  }
  res.status(403).json({ error: 'Forbidden' });
}

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'drone-fleet-gateway' });
});

app.get('/api/missions', requireAdmin, (_req, res) => {
  res.json({
    missions: [
      { id: 'M-101', pilot: 'alice@drone-ops.io', zone: 'Paris-Nord' },
      { id: 'M-102', pilot: 'bob@drone-ops.io', zone: 'Lyon-Est' },
    ],
  });
});

app.get('/api/pilots', requireAdmin, (_req, res) => {
  res.json({
    pilots: [
      { id: 1, name: 'Alice Martin', certified: true },
      { id: 2, name: 'Bob Dupont', certified: true },
    ],
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Drone Fleet Gateway on port ${PORT}`);
});

module.exports = app;
