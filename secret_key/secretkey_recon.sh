#!/bin/bash

usage() {
    echo "Usage: $0 <domain>"
    exit 1
}

if [[ -z "$1" ]]; then
    usage
fi

domain="$1"

output_dir="$pwd"/"$domain"

mkdir -p "$output_dir"

echo "[*] Running subfinder for domain: $domain"
subfinder -d "$domain" -all -recursive -o "$output_dir/subs.txt"

echo "[*] Running waybackurls"
cat "$output_dir/subs.txt" | /root/go/bin/waybackurls -no-subs | /root/go/bin/anew "$output_dir/wayback.txt"

echo "[*] Running gau"
cat "$output_dir/subs.txt" | /root/go/bin/gau --threads 5 --o "$output_dir/gau.txt"

echo "[*] Combining wayback and gau results"
cat "$output_dir/gau.txt" "$output_dir/wayback.txt" >> "$output_dir/final_subs.txt"

echo "[*] Running httpx-toolkit to find live hosts"
cat "$output_dir/final_subs.txt" | httpx-toolkit >> "$output_dir/alive-doit.txt"

echo "[*] Running katana"
cat "$output_dir/alive-doit.txt" | /root/go/bin/katana -d 5 -c 50 -jc -s breadth-first -o "$output_dir/katana.txt"

echo "[*] Running hakrawler"
cat "$output_dir/alive-doit.txt" | /root/go/bin/hakrawler -d 5 -t 20 -subs | tee "$output_dir/hakrawler.txt"

echo "[*] Extracting JavaScript files"
cat "$output_dir"/*.txt | grep ".js" | sort -u | tee "$output_dir/alljs.txt"


cat "$output_dir/alljs.txt" | httpx-toolkit >> "$output_dir/alive-js.txt"

echo "[*] Running mantra on JavaScript files"
cat "$output_dir/alive-js.txt" | /root/go/bin/mantra

echo "[*] Running cariddi"
cat "$output_dir/alljs.txt" | /root/go/bin/cariddi -e -err -info -debug

echo "[*] Running nuclei with exposure templates"
cat "$output_dir/alljs.txt" | /root/go/bin/nuclei -t /root/nuclei-templates/exposures

echo "[*] Process completed. Results are saved in $output_dir"
