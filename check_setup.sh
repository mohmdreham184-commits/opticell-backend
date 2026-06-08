#!/bin/bash
# Quick diagnostic script for Opticell data loading

echo "🔍 Opticell Data Loading Diagnostic Tool"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Run from project root."
    exit 1
fi

echo "✅ Found pubspec.yaml"
echo ""

# Check Flutter
echo "📱 Flutter version:"
flutter --version
echo ""

# Check if backend exists
if [ -d "opticell-backend" ]; then
    echo "✅ Found backend directory"
    
    if [ -f "opticell-backend/package.json" ]; then
        echo "✅ Found package.json"
        echo ""
        echo "📦 Backend dependencies:"
        cat opticell-backend/package.json | grep -A 5 '"dependencies"'
    fi
fi

echo ""
echo "🔧 Configuration Check:"
echo "========================"

# Check Android Network Security Config
if [ -f "android/app/src/main/res/xml/network_security_config.xml" ]; then
    echo "✅ Network Security Config exists"
else
    echo "❌ Missing network_security_config.xml"
fi

# Check API endpoint
echo ""
echo "🌐 API Configuration:"
if grep -q "opticell-backend-production" lib/app_state.dart; then
    echo "✅ API endpoint is configured"
    grep "opticell-backend-production" lib/app_state.dart
fi

echo ""
echo "📋 Next Steps:"
echo "1. cd opticell-backend && npm install && node seed.js"
echo "2. npm start (to test backend locally)"
echo "3. flutter clean && flutter pub get"
echo "4. flutter build apk --release"
echo "5. adb logcat | grep -E '📡|✅|❌|⚠️'"
echo ""
