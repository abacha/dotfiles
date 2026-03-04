#!/bin/bash
# Expose Home Assistant to local network (WSL2 port forwarding)

WSL_IP=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
PORT=8124

if [ -z "$WSL_IP" ]; then
    echo "❌ Could not detect WSL IP"
    exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "Expose Home Assistant to Local Network"
echo "═══════════════════════════════════════════════════"
echo ""
echo "WSL IP: $WSL_IP"
echo "Port: $PORT"
echo ""
echo "To make Home Assistant accessible from other devices:"
echo ""
echo "1️⃣  Open PowerShell as Administrator on Windows"
echo ""
echo "2️⃣  Run this command:"
echo ""
echo "   netsh interface portproxy add v4tov4 listenport=$PORT listenaddress=0.0.0.0 connectport=$PORT connectaddress=$WSL_IP"
echo ""
echo "3️⃣  Find your Windows PC IP:"
echo "   - Run: ipconfig"
echo "   - Look for 'Wireless LAN adapter' or 'Ethernet adapter'"
echo "   - Use the IPv4 Address (e.g., 192.168.1.XXX)"
echo ""
echo "4️⃣  Access Home Assistant from phone/other devices:"
echo "   http://YOUR_WINDOWS_IP:$PORT"
echo ""
echo "═══════════════════════════════════════════════════"
echo "To remove the port forwarding later:"
echo "   netsh interface portproxy delete v4tov4 listenport=$PORT listenaddress=0.0.0.0"
echo "═══════════════════════════════════════════════════"
echo ""
echo "💡 TIP: You may need to allow port $PORT in Windows Firewall"
echo ""
