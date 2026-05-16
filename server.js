const express = require('express');
const session = require('express-session');
const axios = require('axios');
const { exec } = require('child_process');
const sqlite3 = require('sqlite3').verbose();
require('dotenv').config();

const app = express();

// ============================================
// MIDDLEWARE
// ============================================
app.use(express.static('public'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// FAILLE 7: Session secret en .env (et hardcodé!)
app.use(session({
  secret: process.env.SESSION_SECRET,  // 'my_super_secret_key_shared_on_slack_2024'
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: false,  // FAILLE 5: secure=false même sans HTTPS
    httpOnly: false // FAILLE: httpOnly=false, accessible from JavaScript!
  }
}));

// ============================================
// DATA - Base de données "en mémoire"
// ============================================
let users = [
  { id: 1, username: 'user', email: 'user@sneakers.com', password: process.env.password},
  { id: 2, username: 'admin', email: 'admin@sneakers.com', password: process.env.ADMIN_TOKEN}
];

let loginAttempts = {}; 

const shoes = [
  { id: 1, model: 'Air Max 90', brand: 'Nike', price: 129.99, image: 'https://via.placeholder.com/200?text=Air+Max+90' },
  { id: 2, model: 'Jordan 1 Retro', brand: 'Jordan', price: 170, image: 'https://via.placeholder.com/200?text=Jordan+1' },
  { id: 3, model: 'Yeezy Boost 350', brand: 'Adidas', price: 220, image: 'https://via.placeholder.com/200?text=Yeezy' },
  { id: 4, model: 'Ultraboost 22', brand: 'Adidas', price: 180, image: 'https://via.placeholder.com/200?text=Ultraboost' },
  { id: 5, model: 'Chuck 70', brand: 'Converse', price: 75, image: 'https://via.placeholder.com/200?text=Chuck+70' },
  { id: 6, model: 'New Balance 990v6', brand: 'New Balance', price: 185, image: 'https://via.placeholder.com/200?text=NB+990v6' }
];

// ============================================
// AUTH MIDDLEWARE
// ============================================
function isLoggedIn(req, res, next) {
  if (req.session && req.session.userId) {
    next();
  } else {
    res.redirect('/login.html');
  }
}

// ============================================
// PAGES
// ============================================

// Landing page
app.get('/', (req, res) => {
  if (req.session && req.session.userId) {
    res.redirect('/dashboard.html');
  } else {
    res.redirect('/login.html');
  }
});

// ============================================
// AUTHENTICATION ENDPOINTS
// ============================================


const bcrypt = require('bcrypt');
const { z } = require('zod');

const registerSchema = z.object({
  username: z.string().min(3).max(30),
  email: z.string().email(),
  password: z.string().min(8).max(128)
});

app.post('/api/register', async (req, res) => {
  // Validate request body
  const validation = registerSchema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({
      success: false,
      error: 'Invalid request body'
    });
  }

  const { username, email, password } = validation.data;

  const normalizedEmail = email.trim().toLowerCase();

  // Check if user already exists
  if (users.find(u => u.email === normalizedEmail)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid registration request'
    });
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 12);

  const newUser = {
    id: users.length + 1,
    username,
    email: normalizedEmail,
    password: hashedPassword
  };

  users.push(newUser);

  // Prevent session fixation
  req.session.regenerate(err => {
    if (err) {
      return res.status(500).json({
        success: false,
        error: 'Session error'
      });
    }

    req.session.userId = newUser.id;
    req.session.username = newUser.username;

    // Safe logging
    if (process.env.DEBUG) {
      console.log('User registered:', {
        id: newUser.id,
        username: newUser.username
      });
    }

    res.json({
      success: true,
      message: 'Account created!'
    });
  });
});


app.post('/api/login', (req, res) => {
  const { email, password } = req.body;
  const clientIp = req.ip;


  // Quelqu'un peut bruteforce les passwords
  if (!email || !password) {
    return res.json({ success: false, error: 'Missing credentials' });
  }

  
  // Vérifier si admin token
  if (req.headers['x-admin-token'] === process.env.ADMIN_TOKEN) {
    // FAILLE 4: Backdoor admin!
    req.session.userId = 1;
    req.session.username = 'admin_bypass';
    return res.json({ success: true, message: 'Admin access granted' });
  }

  const user = users.find(u => u.email === email && u.password === password);

  if (!user) {
   
    const userExists = users.find(u => u.email === email);
    return res.json({ 
      success: false, 
      error: userExists ? 'Wrong password' : 'User not found'  // FAILLE 6!
    });
  }

  // Login successful
  req.session.userId = user.id;
  req.session.username = user.username;

  if (process.env.DEBUG) {
    console.log(`Login successful for ${email}`);
  }

  res.json({ success: true, message: 'Logged in!', user: { username: user.username } });
});

// Logout
app.post('/api/logout', (req, res) => {
  req.session.destroy();
  res.json({ success: true, message: 'Logged out' });
});

// ============================================
// DASHBOARD ENDPOINTS
// ============================================

// Get shoes list
app.get('/api/shoes', isLoggedIn, (req, res) => {
  // N'importe quel user connecté peut voir
  
  res.json({ success: true, shoes });
});

// Get current user info (FAILLE 3: BFLA variant)
app.get('/api/user/profile', isLoggedIn, (req, res) => {
  const user = users.find(u => u.id === req.session.userId);
  
  if (!user) {
    return res.json({ success: false, error: 'User not found' });
  }


  res.json({ 
    success: true, 
    user: user  // Password inclus!
  });
});


app.get('/api/user/:id', isLoggedIn, (req, res) => {
  const userId = parseInt(req.params.id);

  
  const user = users.find(u => u.id === userId);
  
  if (!user) {
    return res.json({ success: false, error: 'User not found' });
  }

  res.json({ 
    success: true, 
    user: user 
  });
});

// ============================================
// SQL INJECTION ENDPOINT (FAILLE 9: Vraie SQL Injection avec SQLite)
// ============================================

// Base de données SQLite en mémoire — vraies requêtes SQL exécutées
const db = new sqlite3.Database(':memory:');

// Créer la table et insérer des données de commandes
db.serialize(() => {
  db.run(
    'CREATE TABLE orders (' +
    '  id INTEGER PRIMARY KEY,' +
    '  userId INTEGER,' +
    '  product TEXT,' +
    '  amount REAL,' +
    '  status TEXT' +
    ')'
  );
  db.run("INSERT INTO orders (userId, product, amount, status) VALUES (1, 'Air Max 90', 129.99, 'shipped')");
  db.run("INSERT INTO orders (userId, product, amount, status) VALUES (2, 'Jordan 1 Retro', 170.00, 'pending')");
  db.run("INSERT INTO orders (userId, product, amount, status) VALUES (1, 'Yeezy Boost 350', 220.00, 'delivered')");
  db.run("INSERT INTO orders (userId, product, amount, status) VALUES (2, 'Ultraboost 22', 180.00, 'shipped')");
  db.run("INSERT INTO orders (userId, product, amount, status) VALUES (3, 'Chuck 70', 75.00, 'pending')");
});

// FAILLE 9: SQL Injection — req.query injecté directement dans db.all()
app.get('/api/orders/search', isLoggedIn, (req, res) => {
  if (!req.query.userId) {
    return res.json({ success: false, error: 'Missing userId parameter' });
  }

  // ❌ FAILLE SQL INJECTION: concaténation directe de req.query dans db.all()
  // Correction: db.all('SELECT * FROM orders WHERE userId = ?', [req.query.userId], cb)
  db.all(
    'SELECT * FROM orders WHERE userId = ' + req.query.userId,
    (err, rows) => {
      if (err) {
        return res.json({
          success: false,
          error: 'SQL Error: ' + err.message,
          query: 'SELECT * FROM orders WHERE userId = ' + req.query.userId
        });
      }
      // ❌ La requête SQL construite est exposée dans la réponse
      res.json({
        success: true,
        query: 'SELECT * FROM orders WHERE userId = ' + req.query.userId,
        results: rows,
        count: rows.length
      });
    }
  );
});

// ============================================
// SEARCH ENDPOINT (FAILLE 1: SQL Injection simulation)
// ============================================
app.get('/api/shoes/search', isLoggedIn, (req, res) => {
  const { q } = req.query;

  if (!q) {
    return res.json({ success: false, error: 'Missing search query' });
  }

  const searchTerm = q.toLowerCase();
  const results = shoes.filter(shoe => 
    shoe.model.toLowerCase().includes(searchTerm) ||
    shoe.brand.toLowerCase().includes(searchTerm)
  );


  const logCommand = `echo "Search: ${q}" >> /tmp/shoe_search.log`;
  

  exec(logCommand, { shell: true }, (err) => {
    if (err) console.error('Log error:', err.message);
  });

  if (process.env.DEBUG) {
    console.log('Search:', { q, results: results.length });
  }

  res.json({ success: true, results });
});

// ============================================
// CONFIG ENDPOINT (FAILLE: Debug info exposed)
// ============================================
app.get('/api/config', (req, res) => {
  // FAILLE: Pas d'authentification
  // Quelqu'un a créé ça pour tester
  
  if (process.env.DEBUG) {
    res.json({
      debug: true,
      environment: process.env.NODE_ENV,
      sessionSecret: process.env.SESSION_SECRET,  // FAILLE: Exposed!
      adminToken: process.env.ADMIN_TOKEN,        // FAILLE: Exposed!
      apiKey: process.env.API_KEY,                // FAILLE: Exposed!
      users_count: users.length,
      version: '1.0.0'
    });
  } else {
    res.status(404).json({ error: 'Not found' });
  }
});

// ============================================
// HEALTH CHECK
// ============================================
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    debug: process.env.DEBUG === 'true'
  });
});

// ============================================
// FAILLE 5: HTTPS verification disabled (simulation)
// ============================================
app.get('/api/external-data', isLoggedIn, async (req, res) => {
  try {
    // Simulation - en prod ce serait une vraie requête HTTPS
    const response = await axios.get('https://api.example.com/data', {
      httpsAgent: {
        rejectUnauthorized: false  // FAILLE 5: MITM vulnerable!
      },
      timeout: 3000
    });
    res.json({ success: true, data: response.data });
  } catch (error) {
    // FAILLE: Erreur détaillée
    res.json({ 
      success: false, 
      error: error.message,
      ...(process.env.DEBUG && { stack: error.stack })
    });
  }
});

// ============================================
// 404
// ============================================
app.use((req, res) => {
  res.status(404).send('Page not found');
});

// ============================================
// ERROR HANDLER
// ============================================
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    ...(process.env.DEBUG && { details: err.message })
  });
});

// ============================================
// START SERVER
// ============================================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`[Sneaker Shop] Running on http://localhost:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
  if (process.env.DEBUG) {
    console.log('⚠️  DEBUG MODE ENABLED');
    console.log('Config exposed at /api/config');
  }
});
