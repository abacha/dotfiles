#!/bin/bash
# Helper script for EBO Air and ROLA Fountain integration
# Run this when you're at your PC with GUI access

echo "═══════════════════════════════════════════════════"
echo "EBO Air & ROLA Fountain - Home Assistant Setup"
echo "═══════════════════════════════════════════════════"
echo ""

# Check if HA is running
if ! curl -s http://localhost:8124/api/ > /dev/null 2>&1; then
    echo "❌ Home Assistant not responding on port 8124"
    echo "   Start it with: docker start homeassistant"
    exit 1
fi

echo "✅ Home Assistant is running"
echo ""

# Device info
echo "📱 Devices to integrate:"
echo "   - EBO Air (Y012YUMM) - Pet robot"
echo "   - ROLA Fountain-01 (100AAJD24CK0561) - Water fountain"
echo ""

echo "🔧 Integration methods to try:"
echo ""
echo "1️⃣  LocalTuya (already installed):"
echo "   → Open http://localhost:8124"
echo "   → Configuration → Devices & Services"
echo "   → Click '+ Add Integration' → Search 'LocalTuya'"
echo "   → Try 'Add a new device' or 'Discover devices'"
echo ""

echo "2️⃣  Find Local Keys (if LocalTuya needs them):"
echo "   Install tuya-cli: npm install -g @tuyapi/cli"
echo "   Run: tuya-cli wizard"
echo "   (Login with Tuya/Smart Life credentials)"
echo ""

echo "3️⃣  Check if apps support smart home platforms:"
echo "   → Open EBO app → Settings → Check for Alexa/Google Home"
echo "   → Open ROLA app → Settings → Check for Alexa/Google Home"
echo "   → If yes, integrate via HA's Alexa/Google Home integration"
echo ""

echo "4️⃣  Network scan (to find device IPs):"
echo "   Run: nmap -sn 192.168.1.0/24 (replace with your network)"
echo "   Or check your router's DHCP table"
echo ""

echo "5️⃣  Packet capture (advanced - find API endpoints):"
echo "   → Use mitmproxy or Wireshark"
echo "   → Capture traffic from EBO/ROLA apps"
echo "   → Look for REST API endpoints to reverse engineer"
echo ""

echo "═══════════════════════════════════════════════════"
echo "💡 TIP: Start with method #1 (LocalTuya discovery)"
echo "═══════════════════════════════════════════════════"
