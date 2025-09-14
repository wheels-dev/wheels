#!/bin/bash

# Test script for Wheels AI Documentation Endpoints
# Requires Wheels dev server to be running on port 60000

echo "Testing Wheels AI Documentation Endpoints"
echo "========================================="
echo ""

BASE_URL="http://localhost:60006"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local description=$2

    echo -n "Testing $description... "

    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")

    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ OK${NC}"

        # Get sample of response
        echo "  Sample response:"
        curl -s "$BASE_URL$endpoint" | head -c 200
        echo ""
        echo ""
    else
        echo -e "${RED}✗ Failed (HTTP $response)${NC}"
        echo ""
    fi
}

# Check if server is running
echo "Checking if Wheels dev server is running..."
if ! curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" > /dev/null 2>&1; then
    echo -e "${RED}Error: Wheels dev server is not running on port 60000${NC}"
    echo "Please start it with: wheels server start"
    exit 1
fi
echo -e "${GREEN}Server is running${NC}"
echo ""

# Test main AI endpoint
test_endpoint "/wheels/ai" "Main AI Documentation Endpoint"

# Test manifest endpoint
test_endpoint "/wheels/ai?mode=manifest" "Documentation Manifest"

# Test project context endpoint
test_endpoint "/wheels/ai?mode=project" "Project Context"

# Test documentation chunks
test_endpoint "/wheels/ai?mode=chunk&id=models" "Models Documentation Chunk"
test_endpoint "/wheels/ai?mode=chunk&id=controllers" "Controllers Documentation Chunk"
test_endpoint "/wheels/ai?mode=chunk&id=views" "Views Documentation Chunk"
test_endpoint "/wheels/ai?mode=chunk&id=migrations" "Migrations Documentation Chunk"
test_endpoint "/wheels/ai?mode=chunk&id=patterns" "Patterns Documentation Chunk"

# Test context filtering
test_endpoint "/wheels/ai?context=model" "Model Context Filter"
test_endpoint "/wheels/ai?context=controller" "Controller Context Filter"
test_endpoint "/wheels/ai?context=view" "View Context Filter"

# Test legacy endpoints
echo "Testing Legacy Endpoints"
echo "------------------------"
test_endpoint "/wheels/api?format=json" "Legacy API Documentation"
test_endpoint "/wheels/guides?format=json" "Legacy Guides Documentation"

echo ""
echo "========================================="
echo "Testing Complete!"
echo ""

# Summary
echo "For full integration testing:"
echo "1. Configure MCP server: npm install @modelcontextprotocol/sdk"
echo "2. Start MCP server: node mcp-server.js"
echo "3. Test with your AI coding assistant"
echo ""
echo "Documentation available at:"
echo "- Integration Guide: /docs/AI_INTEGRATION_GUIDE.md"
echo "- CLAUDE.md: Project-specific AI instructions"