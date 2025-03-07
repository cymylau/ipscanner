#!/bin/sh

# Ensure the IP is provided
if [ -z "$TARGET_IP" ]; then
    echo "Error: TARGET_IP environment variable not set." | tee /app/error.log
    exit 1
fi

# Format filename-friendly IP (replace dots with underscores)
SAFE_IP=$(echo "$TARGET_IP" | tr '.' '_')

# Get current date and time
SCAN_DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Define file paths
OPEN_PORTS_FILE="/app/${SAFE_IP}_open_ports.txt"
SSH_BANNER_FILE="/app/${SAFE_IP}_ssh_banner.txt"
HTTP_FILE="/app/${SAFE_IP}_http"
RDP_SCREENSHOT="/app/${SAFE_IP}_rdp_screenshot.bmp"

echo "[+] Scanning $TARGET_IP for open ports..."
echo "Scan Date: $SCAN_DATE" > "$OPEN_PORTS_FILE"
nmap -p- --min-rate=1000 -T4 "$TARGET_IP" | tee -a "$OPEN_PORTS_FILE"

# Collect evidence
for port in $(grep "open" "$OPEN_PORTS_FILE" | awk '{print $1}' | tr -d '/tcp'); do
    case "$port" in
        22)
            echo "[+] SSH found on port $port"
            echo "Scan Date: $SCAN_DATE" > "$SSH_BANNER_FILE"
            nc -v -w 2 "$TARGET_IP" 22 | tee -a "$SSH_BANNER_FILE"
            ;;
        80|443)
            echo "[+] HTTP/HTTPS found on port $port"
            HTTP_OUTPUT="${HTTP_FILE}_${port}.html"
            echo "Scan Date: $SCAN_DATE" > "$HTTP_OUTPUT"
            wget -qO- "http://$TARGET_IP" >> "$HTTP_OUTPUT"
            ;;
        3389)
            echo "[+] RDP found on port $port"
            echo "Scan Date: $SCAN_DATE" > "$RDP_SCREENSHOT.log"
            xfreerdp /v:"$TARGET_IP" /u:guest /p:password /cert-ignore /bitmap-cache "$RDP_SCREENSHOT"
            ;;
        *)
            echo "[+] Port $port is open but not a well-known service."
            ;;
    esac
done

echo "[+] Evidence collection complete. Check the output files in /app."
