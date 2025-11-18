#!/bin/bash

# BetaCaller Backend Setup Script

set -e

echo "🚀 BetaCaller Backend Setup"
echo "============================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Node.js
echo "📦 Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed!${NC}"
    echo "Please install Node.js 18+ from: https://nodejs.org"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js version 18 or higher is required${NC}"
    echo "Current version: $(node -v)"
    exit 1
fi

echo -e "${GREEN}✅ Node.js $(node -v) installed${NC}"
echo ""

# Check npm
echo "📦 Checking npm..."
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ npm $(npm -v) installed${NC}"
echo ""

# Check PostgreSQL
echo "🐘 Checking PostgreSQL..."
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL installed${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL not found. You can use Docker instead.${NC}"
fi
echo ""

# Environment file
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
    echo -e "${YELLOW}⚠️  Please update .env with your credentials!${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Build TypeScript
echo "🔨 Building TypeScript..."
npm run build
echo -e "${GREEN}✅ TypeScript compiled${NC}"
echo ""

# Create logs directory
if [ ! -d "logs" ]; then
    mkdir -p logs
    echo -e "${GREEN}✅ Logs directory created${NC}"
fi
echo ""

# Success message
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Update .env with your credentials:"
echo "   - Clerk keys (from https://clerk.com)"
echo "   - Twilio credentials (from https://twilio.com)"
echo "   - PostgreSQL database settings"
echo ""
echo "2. Create PostgreSQL database:"
echo "   createdb betacaller"
echo ""
echo "3. Start development server:"
echo "   npm run dev"
echo ""
echo "OR use Docker:"
echo "   docker-compose up -d"
echo ""
echo "🎉 Happy coding!"
