#!/bin/bash



usage() {
    echo "Usage: $0 -d <domain>"
    exit 1
}

while getopts "d:" opt; do
    case $opt in
        d) domain="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -z "$domain" ]]; then
    usage
fi

subfinder_output="${domain}"
assetfinder_output="${domain}_2"
sorted_output="${domain}_sorted"
merged_output="${domain}_final"
alive_output="${domain}_alive"
pics_dir="${domain}_pics"
out_dir="${domain}_output"

mkdir -p "$out_dir"

echo "[*] Running subfinder for domain: $domain"
subfinder -d "$domain" -o "$out_dir"/"$subfinder_output"

echo "[*] Running assetfinder for domain: $domain"
assetfinder "$domain" | sort -u > "$out_dir"/"$assetfinder_output"

echo "[*] Sorting subfinder results"
cat "$out_dir"/"$subfinder_output" | sort -u > "$out_dir"/"$sorted_output"

echo "[*] Merging sorted results with assetfinder results"
cat ""$out_dir"/$sorted_output" >> "$out_dir"/"$assetfinder_output"
cat "$out_dir"/"$assetfinder_output" | sort -u > "$out_dir"/"$merged_output"

echo "[*] Probing for live domains with httprobe"
cat "$out_dir"/"$merged_output" | sort -u | httprobe -prefer-https -c 50 | grep https > "$out_dir"/"$alive_output"

echo "[*] Creating directory for screenshots: $pics_dir"
mkdir -p "$out_dir"/"$pics_dir"

echo "[*] Running gowitness for live domains"
gowitval=$(awk '{gsub(/https:\/\//, "", $1); if($1 != "") print $1}' "$out_dir"/"$alive_output" 2>/dev/null)

if [[ -n "$gowitval" ]]; then
    gowitness file -f <(echo "$gowitval") -P "$out_dir"/"$pics_dir" --no-http
else
    echo "[!] No live domains found to process with gowitness."
fi

echo "[*] Script completed. Results:"
echo " - Subfinder results: $out_dir/$subfinder_output"
echo " - Assetfinder results: $out_dir/$assetfinder_output"
echo " - Final merged results: $out_dir/$merged_output"
echo " - Live domains: $out_dir/$alive_output"
echo " - Screenshots stored in: $out_dir/$pics_dir"