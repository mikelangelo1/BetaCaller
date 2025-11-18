#!/bin/bash

# BetaCaller Setup Script
# This script helps you set up the BetaCaller project

set -e

echo "🚀 BetaCaller Setup Script"
echo "=========================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Flutter is installed
echo "📱 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed!${NC}"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter is installed${NC}"
flutter --version
echo ""

# Run flutter doctor
echo "🔍 Running Flutter Doctor..."
flutter doctor
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Create asset directories if they don't exist
echo "📁 Creating asset directories..."
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts
echo -e "${GREEN}✅ Asset directories created${NC}"
echo ""

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices
echo ""

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze
echo ""

# Success message
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Review README.md for full documentation"
echo "2. Run 'flutter run' to start the app in demo mode"
echo "3. See BACKEND_SETUP.md to set up your backend"
echo "4. See TWILIO_INTEGRATION.md for Twilio setup"
echo ""
echo "🎉 Happy coding!"
