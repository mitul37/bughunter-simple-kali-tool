#!/bin/bash

# Bug Hunter - Automated Recon Tool for Bug Bounty
# Usage: ./bug_hunter.sh <target_url> [--keep-old]

detect_protocol() {
    if [[ $1 == https* ]]; then
        echo "[+] HTTPS detected"
        protocol="https"
    else
        echo "[+] HTTP detected"
        protocol="http"
    fi
}

check_target() {
    echo "[+] Checking target availability: $1"
    curl -Is "$1" | head -n 1
}

nmap_scan() {
    echo "[+] Running Nmap scan on $1"
    domain=$(echo $1 | sed -E 's~https?://~~;s~/.*~~')
    nmap -p- -T4 "$domain" -oN "$folder/$protocol/nmap_scan.txt"
}

dirb_scan() {
    echo "[+] Running Dirb scan on $1"
    dirb "$1" /usr/share/seclists/Discovery/Web-Content/common.txt -o "$folder/$protocol/dirb_scan.txt"
}

gobuster_scan() {
    echo "[+] Running Gobuster scan on $1"
    gobuster dir -u "$1" -w /usr/share/seclists/Discovery/Web-Content/common.txt -t 50 -b 403 -o "$folder/$protocol/gobuster_scan.txt"
}

run_payload_test() {
    local name=$1
    local file=$2
    echo "[+] Running $name tests"
    if [[ ! -f $file ]]; then
        echo "[-] $name payload file not found: $file"
        return
    fi

    outfile="$folder/$protocol/${name,,}_test.txt"
    > "$outfile"

    while IFS= read -r payload || [[ -n "$payload" ]]; do
        [[ -z "$payload" ]] && continue
        url="${TARGET_URL}?test=$payload"
        response=$(curl -skL "$url" --max-time 10)
        if echo "$response" | grep -q "$payload"; then
            echo "[!] Possible $name with payload: $payload" | tee -a "$outfile"
        fi
    done < "$file"
}

# Main Execution
if [ $# -lt 1 ]; then
    echo "Usage: $0 <target_url> [--keep-old]"
    exit 1
fi

TARGET_URL=$1
KEEP_OLD=false
[[ $2 == "--keep-old" ]] && KEEP_OLD=true

detect_protocol "$TARGET_URL"
folder="bug_hunt_results"
result_dir="$folder/$protocol"

if [ "$KEEP_OLD" = false ] && [ -d "$result_dir" ]; then
    echo "[+] Previous results found, deleting..."
    rm -rf "$result_dir"
fi

mkdir -p "$result_dir"

check_target "$TARGET_URL"
nmap_scan "$TARGET_URL"
dirb_scan "$TARGET_URL"
gobuster_scan "$TARGET_URL"

# Real payload files that exist on Kali:
run_payload_test "SQL Injection" "/usr/share/seclists/Fuzzing/SQLi/Generic-SQLi.txt"
run_payload_test "XSS" "/usr/share/seclists/Fuzzing/XSS/robot-friendly/XSS-payloadbox.txt"
run_payload_test "LFI" "/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt"
run_payload_test "RFI" "/usr/share/seclists/Fuzzing/LFI_RFI/RFI-LFI-payloads.txt"

echo "[+] Bug bounty scan completed for $TARGET_URL"
echo "[+] Results saved in: $result_dir"
