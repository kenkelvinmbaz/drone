# 🛡️ Comment Corriger les Failles

**Remédiation pour chacune des 8 failles. Code avant/après.**

---

## 1️⃣ FAILLE: No Input Validation

### ❌ AVANT (Vulnérable)
```javascript
app.post('/api/register', (req, res) => {
  const { username, email, password } = req.body;
  
  const newUser = { id: users.length + 1, username, email, password };
  users.push(newUser);
  res.json({ success: true });
});
```

### ✅ APRÈS (Sécurisé)
```javascript
const validator = require('email-validator');

app.post('/api/register', (req, res) => {
  const { username, email, password } = req.body;
  
  // Validation
  if (!username || username.trim().length < 3) {
    return res.json({ 
      success: false, 
      error: 'Username must be at least 3 characters' 
    });
  }
  
  if (!validator.validate(email)) {
    return res.json({ success: false, error: 'Invalid email' });
  }
  
  if (!password || password.length < 8) {
    return res.json({ 
      success: false, 
      error: 'Password must be at least 8 characters' 
    });
  }
  
  if (users.find(u => u.email === email)) {
    return res.json({ success: false, error: 'Email already registered' });
  }
  
  const newUser = { id: users.length + 1, username, email, password };
  users.push(newUser);
  res.json({ success: true, message: 'Registration successful' });
});
```

**Points clés:**
- Vérifier champ non-vide
- Valider format email
- Password mininum 8 chars
- Vérifier pas de duplication

---

## 2️⃣ FAILLE: Plain Text Passwords

### ❌ AVANT (Vulnérable)
```javascript
// Installation: npm install bcryptjs (MISSING!)
const newUser = { 
  username, 
  email, 
  password  // Plain text!
};
users.push(newUser);
```

### ✅ APRÈS (Sécurisé)
```javascript
const bcrypt = require('bcryptjs');

// Au register
app.post('/api/register', async (req, res) => {
  // ... validation ...
  
  // Hash le password
  const hashedPassword = await bcrypt.hash(password, 10);
  
  const newUser = { 
    id: users.length + 1, 
    username, 
    email, 
    password: hashedPassword  // Haché!
  };
  users.push(newUser);
  res.json({ success: true });
});

// Au login
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  const user = users.find(u => u.email === email);
  
  if (!user) {
    return res.json({ success: false, error: 'Invalid credentials' });
  }
  
  // Comparer avec le hash
  const isPasswordValid = await bcrypt.compare(password, user.password);
  
  if (!isPasswordValid) {
    return res.json({ success: false, error: 'Invalid credentials' });
  }
  
  req.session.userId = user.id;
  res.json({ success: true });
});
```

**Package.json:**
```json
{
  "dependencies": {
    "bcryptjs": "^2.4.3"
  }
}
```

---

## 3️⃣ FAILLE: No Rate Limiting

### ❌ AVANT (Vulnérable)
```javascript
app.post('/api/login', (req, res) => {
  // Pas de limite!
  const { email, password } = req.body;
  // ...
});
```

### ✅ APRÈS (Sécurisé)
```javascript
const rateLimit = require('express-rate-limit');

// Rate limiter: 5 tentatives par 15 minutes
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 5,                      // 5 requests max
  message: 'Too many login attempts, try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

app.post('/api/login', loginLimiter, (req, res) => {
  const { email, password } = req.body;
  
  // ... rest of login logic ...
});
```

**Package.json:**
```json
{
  "dependencies": {
    "express-rate-limit": "^6.7.0"
  }
}
```

---

## 4️⃣ FAILLE: Admin Bypass Token

### ❌ AVANT (Vulnérable)
```javascript
app.post('/api/login', (req, res) => {
  // FAILLE: Admin bypass!
  if (req.headers['x-admin-token'] === process.env.ADMIN_TOKEN) {
    req.session.userId = 1;
    return res.json({ success: true, message: 'Admin access' });
  }
  
  // Normal login...
});
```

### ✅ APRÈS (Sécurisé)
```javascript
// Option 1: Supprimer complètement
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;
  // Normal login only
  // ...
});

// Option 2: Si vous avez vraiment besoin d'un token admin (QA/testing)
// Créer une route séparée et protégée
const adminTokenSecret = require('crypto').randomBytes(32).toString('hex');

app.post('/api/admin-login', (req, res) => {
  const { token } = req.body;
  
  // Vérifier token dans une variable d'env (pas en header!)
  // Et SEULEMENT en dev
  if (process.env.NODE_ENV !== 'development') {
    return res.json({ success: false, error: 'Not available' });
  }
  
  if (token === adminTokenSecret) {
    req.session.userId = 1;
    req.session.isAdmin = true;
    return res.json({ success: true });
  }
  
  res.json({ success: false, error: 'Invalid token' });
});
```

**Message:** 
"Cette 'solution temporaire' a duré 6 mois. Ne faire JAMAIS ça."

---

## 5️⃣ FAILLE: Unsafe Session Cookies

### ❌ AVANT (Vulnérable)
```javascript
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: false,      // Marche même sans HTTPS
    httpOnly: false     // Accessible du JavaScript
  }
}));
```

### ✅ APRÈS (Sécurisé)
```javascript
const session = require('express-session');

app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: true,       // HTTPS only
    httpOnly: true,     // JavaScript ne peut pas y accéder
    sameSite: 'Strict', // Protection CSRF
    maxAge: 1000 * 60 * 60 * 24  // 24 hours
  }
}));
```

**Important (en production):**
```javascript
// En dev: accepter localhost sans HTTPS
if (process.env.NODE_ENV === 'production') {
  // app.set('trust proxy', 1); // Si derrière proxy
  app.use(session({
    cookie: {
      secure: true,
      httpOnly: true,
      sameSite: 'Strict'
    }
  }));
} else {
  app.use(session({
    cookie: {
      secure: false,  // Localhost peut fonctionner sans HTTPS
      httpOnly: true,
      sameSite: 'Lax'
    }
  }));
}
```

---

## 6️⃣ FAILLE: Information Disclosure

### ❌ AVANT (Vulnérable)
```javascript
app.post('/api/login', (req, res) => {
  const user = users.find(u => u.email === email && u.password === password);
  
  if (!user) {
    // FAILLE: Messages trop spécifiques!
    const userExists = users.find(u => u.email === email);
    return res.json({ 
      success: false, 
      error: userExists ? 'Wrong password' : 'User not found'
    });
  }
  
  req.session.userId = user.id;
  res.json({ success: true });
});
```

### ✅ APRÈS (Sécurisé)
```javascript
app.post('/api/login', (req, res) => {
  const user = users.find(u => u.email === email && u.password === password);
  
  if (!user) {
    // Message générique - pas de détails!
    return res.json({ 
      success: false, 
      error: 'Invalid email or password'
    });
  }
  
  req.session.userId = user.id;
  res.json({ success: true });
});
```

**Principe:**
- Jamais dire "user not found"
- Jamais dire "wrong password"
- Toujours: "Invalid credentials"
- Détails de l'erreur → logs only

---

## 7️⃣ FAILLE: BFLA (Broken Function Level Access)

### ❌ AVANT (Vulnérable)
```javascript
app.get('/api/user/:id', isLoggedIn, (req, res) => {
  const userId = parseInt(req.params.id);
  
  // FAILLE: Pas de vérification d'autorisation!
  const user = users.find(u => u.id === userId);
  
  res.json({ success: true, user: user });  // Expose TOUT
});
```

### ✅ APRÈS (Sécurisé)
```javascript
app.get('/api/user/:id', isLoggedIn, (req, res) => {
  const userId = parseInt(req.params.id);
  const requestingUserId = req.session.userId;
  
  // VÉRIFICATION: C'est mon propre profil?
  if (userId !== requestingUserId && !isAdmin(req.session)) {
    return res.json({ 
      success: false, 
      error: 'Unauthorized' 
    });
  }
  
  const user = users.find(u => u.id === userId);
  
  if (!user) {
    return res.json({ success: false, error: 'User not found' });
  }
  
  // Ne retourner que les infos publiques
  const publicUser = {
    id: user.id,
    username: user.username
    // NO password!
    // NO email!
  };
  
  res.json({ success: true, user: publicUser });
});

function isAdmin(session) {
  return session.userId === 1;  // Simpliste, faire mieux
}
```

---

## 8️⃣ FAILLE: Command Injection

### ❌ AVANT (Vulnérable)
```javascript
const { exec } = require('child_process');

app.get('/api/shoes/search', isLoggedIn, (req, res) => {
  const { q } = req.query;
  
  // FAILLE: shell=true + user input = RCE!
  const logCommand = `echo "Search: ${q}" >> /tmp/shoe_search.log`;
  
  exec(logCommand, { shell: true }, (err) => {
    if (err) console.error('Log error:', err.message);
  });
  
  // Return results...
});
```

### ✅ APRÈS (Sécurisé)
```javascript
const { execFile } = require('child_process');
const path = require('path');

app.get('/api/shoes/search', isLoggedIn, (req, res) => {
  const { q } = req.query;
  
  // Option 1: Utiliser execFile (pas de shell)
  const logFile = path.join('/tmp', 'shoe_search.log');
  
  execFile('tee', [logFile], (err) => {
    if (err) console.error('Log error:', err.message);
  }, { stdio: 'pipe' });
  
  // Ou Option 2: Utiliser fs pour écrire le log
  const fs = require('fs');
  
  // Sanitizer l'input
  const sanitizedQuery = q.replace(/[^a-zA-Z0-9 ]/g, '');
  
  fs.appendFile(
    '/tmp/shoe_search.log',
    `${new Date().toISOString()} - Search: ${sanitizedQuery}\n`,
    (err) => {
      if (err) console.error('Log error:', err);
    }
  );
  
  // Return results...
});
```

**Meilleures pratiques:**
```javascript
// Ne JAMAIS utiliser exec() avec user input
// Préférer execFile() ou spawn()
// Ou mieux: utiliser une librairie logging

// Avec Winston:
const winston = require('winston');

const logger = winston.createLogger({
  transports: [
    new winston.transports.File({ filename: '/tmp/shoe_search.log' })
  ]
});

app.get('/api/shoes/search', isLoggedIn, (req, res) => {
  const { q } = req.query;
  
  logger.info(`Search: ${q}`);  // Safe
  
  // Return results...
});
```

---

## 🛠️ Dépendances à Installer

```bash
npm install bcryptjs express-rate-limit email-validator winston
```

**package.json complet:**
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "express-rate-limit": "^6.7.0",
    "bcryptjs": "^2.4.3",
    "email-validator": "^2.1.0",
    "winston": "^3.8.2",
    "axios": "^1.4.0",
    "dotenv": "^16.0.3"
  }
}
```

---

## 🔒 Checklist de Sécurité

- [ ] Validation de tous les inputs
- [ ] Passwords hashés avec bcrypt
- [ ] Rate limiting sur endpoints sensibles
- [ ] Pas de backdoors/admin tokens
- [ ] Cookies httpOnly + secure + sameSite
- [ ] Messages d'erreur génériques
- [ ] Vérification d'autorisation (pas juste authen)
- [ ] Jamais exec() avec user input
- [ ] Logging centralisé
- [ ] HTTPS en production

---

## 📚 Références

- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [Node.js Security Best Practices](https://nodejs.org/en/knowledge/file-system/security/introduction/)
- [bcryptjs Documentation](https://github.com/dcodeIO/bcrypt.js)
- [express-rate-limit](https://github.com/nfriedly/express-rate-limit)

---

**Dernière pensée:** La sécurité n'est pas une feature qu'on ajoute à la fin. C'est une mentalité qu'on instille dès le début. 🛡️
