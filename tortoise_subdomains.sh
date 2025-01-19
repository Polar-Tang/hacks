#!/bin/bash
green="\e[0;32m\033[1m"
end="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purple="\e[0;35m\033[1m"
gray="\e[0;37m\033[1m"

delay=1500ms
threads=10
output_dir="./gobuster_output"
mkdir -p "$output_dir"

usage() {
    echo -e "Usage: $0 -d <domain> -s <speed> -t <threads> -w <wordlist>"
    echo -e " ${purple} -d ${end}  Domain to start subdomain enumeration (required)."
    echo -e " ${purple} -s ${end}  Speed level (1: fast, 2: moderate, 3: slow)."
    echo -e " ${purple} -t ${end}  Threads (10, 100, or 200)."
    echo -e " ${purple} -w ${end}  Wordlist file for gobuster (required)."
    echo -e " ${purple} -r ${end}  Resume from a specific round."
    exit 1
}

# Parse options
while getopts ":d:s:t:w:r:" opt; do
  case $opt in
    d) domain="$OPTARG" ;;
    s) speed="$OPTARG" ;;
    t) threads="$OPTARG" ;;
    w) wordlist="$OPTARG" ;;
    r) retake_round="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$domain" || -z "$wordlist" ]]; then
    usage
fi

case $speed in
  1) delay=500ms ;;
  2) delay=1500ms ;;  
  3) delay=3000ms ;;
  "") ;;  
  *) echo -e "${red}Invalid speed level. Use 1 (fast), 2 (moderate), or 3 (slow). ${end}" >&2; exit 1 ;;
esac

threads=${threads:-10}

estimate_time() {
  local word_count
  word_count=$(wc -l < "$wordlist")

  local delay_ms="${delay//ms/}"
  local total_time_ms=$((word_count * delay_ms / threads))

  local hours=$((total_time_ms / 3600000))
  local minutes=$(( (total_time_ms % 3600000) / 60000 ))
  local seconds=$(( (total_time_ms % 60000) / 1000 ))

  echo -e "${yellow}Estimated time: ${hours}h ${minutes}m ${seconds}s${end}"
}

retake() {
  local last_word=$(tail -1 "${retake_round}" | awk '{print $4}' | cut -d= -f2 | tr -d '[]')
  local line_where_start=$(grep -nx "^${last_word}$" "${wordlist}" | cut -d: -f1)



  if [[ -z "$line_where_start" ]]; then
    echo "Error: The word '${last_word}' was not found in the provided wordlist."
    exit 1
   else
    echo -e "${green}Creating temporary files to start from line ${end}${line_where_start}${green}.${end}"
    tmp=$(mktemp)
    estimate_time
    tail -n +"${line_where_start}" "${wordlist}" > "${tmp}"
    echo -e "${green}Resuming from line $line_where_start, starting with word '${last_word}'.${end}"
    gobuster fuzz --url "https://FUZZ.${domain}" --delay ${delay} -w - --no-error -t ${threads} -w ${tmp} >> "$retake_round"
  fi

  }


recursive_gobuster() {
    local domain="$1"
    local round=1
    local input_file="$output_dir/${domain}_round_${round}.txt"

    echo -e "Starting recursive gobuster search on domain: ${purple}$domain${end} with delay: ${purple}$delay${end}, threads: ${purple}$threads${end}"
    estimate_time

    gobuster fuzz --url "https://FUZZ.$domain" --delay "$delay" -w "$wordlist" -t "$threads" --no-error > "$input_file"

    while :; do
        echo "Processing round $round for domain: $domain"

        new_subdomains=$(awk '{print $5}' "$input_file" | sed 's|https://||' | sort -u)

        if [[ -z "$new_subdomains" ]]; then
            echo -e "${red}No new subdomains found in round ${end}${purple}$round${end}${red}. Ending recursion.${end}"
            break
        fi

        round=$((round + 1))
        input_file="$output_dir/${domain}_round_${round}.txt"
        echo "$new_subdomains" | xargs -I {} bash -c \
            "gobuster fuzz --url 'https://FUZZ.{}' --delay '$delay' -w '$wordlist' -t '$threads' --no-error >> '$input_file'"

        if [[ ! -s "$input_file" ]]; then
          echo -e "${red}No new subdomains discovered in round ${end}${purple}$round${end}${red}. Stopping further processing.${end}"
          rm "$input_file"
          break
        fi

        sort -u -o "$input_file" "$input_file"
        estimate_time

    done

    echo -e "${green}Recursive gobuster search completed. Results saved in $output_dir${end}"
}

if [[ -n "$retake_round" ]]; then
    retake
else
    recursive_gobuster "$domain"
fi