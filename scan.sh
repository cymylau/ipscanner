#!/bin/sh

# Ensure the IP is provided
if [ -z "$TARGET_IP" ]; then
    echo "Error: TARGET_IP environment variable not set."
    exit 1
fi

echo "[+] Scanning $TARGET_IP for open ports..."
open_ports=$(nmap -p- --min-rate=1000 -T4 "$TARGET_IP" | grep "open" | awk '{print $1}' | tr -d '/tcp')

if [ -z "$open_ports" ]; then
    echo "No open ports found on $TARGET_IP."
    exit 0
fi

echo "[+] Found open ports: $open_ports"

# Evidence gathering for well-known services
for port in $open_ports; do
    case "$port" in
        22)
            echo "[+] SSH found on port $port"
            echo "Attempting to gather SSH banner..."
            nc -v -w 2 "$TARGET_IP" 22 | tee ssh_banner.txt
            ;;
        80|443)
            echo "[+] HTTP/HTTPS found on port $port"
            echo "Fetching webpage..."
            wget -qO- "http://$TARGET_IP" > "http_${port}.html"
            echo "Capturing screenshot (Eyewitness not available on Alpine)"
            ;;
        3389)
            echo "[+] RDP found on port $port"
            echo "Capturing RDP Screenshot..."
            xfreerdp /v:"$TARGET_IP" /u:guest /p:password /cert-ignore /bitmap-cache /app/evidence/rdp_screenshot.bmp
            ;;
        *)
            echo "[+] Port $port is open but not a well-known service."
            ;;
    esac
done

echo "[+] Evidence collection complete. Check the output files."
