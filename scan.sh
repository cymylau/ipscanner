#!/bin/sh

# Ensure the IP is provided
if [ -z "$TARGET_IP" ]; then
    echo "Error: TARGET_IP environment variable not set." | tee /app/reports/error.log
    exit 1
fi

# Ensure the report directory exists
mkdir -p "$REPORT_DIR"

# Format filename-friendly IP (replace dots with underscores)
SAFE_IP=$(echo "$TARGET_IP" | tr '.' '_')

# Get current date and time
SCAN_DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Define file paths
OPEN_PORTS_FILE="$REPORT_DIR/${SAFE_IP}_open_ports.txt"
NMAP_XML_FILE="$REPORT_DIR/${SAFE_IP}_scan.xml"
NMAP_JSON_FILE="$REPORT_DIR/${SAFE_IP}_scan.json"
SSH_BANNER_FILE="$REPORT_DIR/${SAFE_IP}_ssh_banner.txt"
HTTP_FILE="$REPORT_DIR/${SAFE_IP}_http"
RDP_SCREENSHOT="$REPORT_DIR/${SAFE_IP}_rdp_screenshot.bmp"
DNS_SCAN_FILE="$REPORT_DIR/${SAFE_IP}_dns_scan.txt"
HTTP_SCAN_FILE="$REPORT_DIR/${SAFE_IP}_http_scan.txt"

echo "[+] Scanning $TARGET_IP for open ports..."
echo "Scan Date: $SCAN_DATE" > "$OPEN_PORTS_FILE"

# Step 1: Check if ICMP is blocked
echo "[+] Checking if ICMP (ping) is allowed..."
ping -c 1 -W 1 "$TARGET_IP" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[!] ICMP is blocked, switching to No Ping mode (-Pn)"
    NMAP_FLAGS="-Pn"
else
    echo "[+] ICMP is allowed, using standard scanning."
    NMAP_FLAGS=""
fi

# Step 2: Run Nmap scan (both TCP and UDP)
nmap $NMAP_FLAGS -p- -sV -A --min-rate=1000 -T4 -oN "$OPEN_PORTS_FILE" -oX "$NMAP_XML_FILE" "$TARGET_IP"
nmap -sU --top-ports 100 -oN "$REPORT_DIR/${SAFE_IP}_udp_scan.txt" "$TARGET_IP"

echo "[+] Nmap scan complete. Results saved in $OPEN_PORTS_FILE and $NMAP_XML_FILE"

# Step 3: Convert XML to JSON (optional, requires `xsltproc`)
if command -v xsltproc >/dev/null 2>&1; then
    xsltproc /usr/share/nmap/nmap.xsl "$NMAP_XML_FILE" > "$NMAP_JSON_FILE"
    echo "[+] Converted scan results to JSON: $NMAP_JSON_FILE"
fi

# Step 4: Collect evidence for known services
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

            # Run HTTP-focused Nmap scans
            echo "[+] Running HTTP-focused Nmap scans..." | tee -a "$HTTP_SCAN_FILE"
            nmap -p "$port" --script=http-title,http-headers,http-server-header,http-methods,http-robots.txt,http-enum,http-vuln-cve2021-41773,http-wordpress-enum,http-dirscan -oN "$HTTP_SCAN_FILE" "$TARGET_IP"
            echo "[+] HTTP scan completed. Results saved in $HTTP_SCAN_FILE."
            ;;
        3389)
            echo "[+] RDP found on port $port"
            echo "Scan Date: $SCAN_DATE" > "$RDP_SCREENSHOT.log"
            xfreerdp /v:"$TARGET_IP" /u:guest /p:password /cert-ignore /bitmap-cache "$RDP_SCREENSHOT"
            ;;
        53)
            echo "[+] DNS found on port 53 (UDP)"
            echo "Scan Date: $SCAN_DATE" > "$DNS_SCAN_FILE"
            echo "[+] Performing DNS enumeration..." | tee -a "$DNS_SCAN_FILE"

            # Test basic DNS resolution
            dig @$TARGET_IP google.com | tee -a "$DNS_SCAN_FILE"

            # Attempt a zone transfer (AXFR)
            echo "[+] Attempting Zone Transfer..."
            dig @$TARGET_IP google.com AXFR | tee -a "$DNS_SCAN_FILE"

            # Reverse DNS lookup
            echo "[+] Performing reverse DNS lookup..."
            host "$TARGET_IP" | tee -a "$DNS_SCAN_FILE"
            ;;
        *)
            echo "[+] Port $port is open but not a well-known service."
            ;;
    esac
done

echo "[+] Evidence collection complete. Check output files in $REPORT_DIR."
