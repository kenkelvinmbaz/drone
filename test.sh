#!/bin/bash

# Quick test to verify the app is working
BASE_URL="http://localhost:3000"

echo "🧪 Testing Sneaker Shop Application"
echo "===================================="
echo ""

# Check server
if ! curl -s "$BASE_URL/health" > /dev/null; then
  echo "❌ Server not running"
  echo "Start with: npm start"
  exit 1
fi

echo "✅ Server is running"
echo ""

# Test login
echo "Testing login..."
response=$(curl -s -X POST "$BASE_URL/api/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@sneakers.com","password":"user123"}')

if echo "$response" | grep -q '"success":true'; then
  echo "✅ Login works"
else
  echo "❌ Login failed"
fi

echo ""
echo "✅ Application is ready!"
echo ""
echo "Access at: http://localhost:3000"
