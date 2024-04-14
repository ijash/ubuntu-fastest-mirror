#!/bin/bash

#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#%    ./run [-h|--help] [-c|--country <country-code> ...]
#%
#% DESCRIPTION
#%   This script retrieves a list of Ubuntu mirrors based on specified country codes.
#%   If no country codes are provided, it defaults to using mirrors.txt, which contains
#%   geographic mirrors based on the client's source IP address. It then tests the speed
#%   of each mirror and displays the top fastest mirrors. It can replace the default mirrors
#%   with the fastest ones and includes backup capabilities. It will create a 'sources.list.backup'
#%   folder in /etc/apt/ with a backup of the sources.list file before replacing it with the fastest mirrors.
#%   (if backup is enabled). You can check the current status of mirrors at
#%   https://launchpad.net/ubuntu/+archivemirrors and find available country codes at
#%   http://mirrors.ubuntu.com/.
#%
#% OPTIONS
#%    -h, --help       Show this help message and exit.
#%    -c, --country    Specify one or more country codes to retrieve mirrors from. If not
#%                     provided, the script will default to using mirrors from
#%                     http://mirrors.ubuntu.com/mirrors.txt.
#%    -a, --auto       Select fastest mirror automatically without user
#%                     prompt. and automatically backup sources.list
#%    -b, --backup     Backup sources.list to sources.list.backup folder
#%
#% EXAMPLES
#%    ./run -c US JP ID
#%    ./run -b -c ID
#%    ./run -a
#%    ./run
#%
#% AUTHOR
#%    Jastria Rahmat
#%    https://github.com/ijash
#%
#% LICENSE
#%    Distributed under the MIT License.
#%
#================================================================
# END_OF_HEADER
#================================================================

# Constants
COUNTRY_CODE_INCLUDED=()
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TOP_LIST_AMOUNT=5
reset_color='\033[0m'
auto_select=false
top_mirrors=()
backup=false

# Function to clean up cache on exit
cleanup_cache() {
    rm -rf "$SCRIPT_DIR/.cache"
}

# Function to validate country code
validate_country_code() {
    local code="$1"
    if ! wget -q --spider "http://mirrors.ubuntu.com/$code.txt"; then
        echo "Error: Invalid country code '$code'" >&2
        return 1
    fi
    return 0
}

# Function to format color based on speed
format_color() {
    local speed_bps=$1
    speed_kbps=$(bc -l <<<"$speed_bps / 1000")

    if (($(bc <<<"$speed_kbps == 0"))); then
        echo "\e[38;5;9m"
    elif (($(bc <<<"$speed_kbps < 100"))); then
        echo "\e[38;5;88m"
    elif (($(bc <<<"$speed_kbps < 275"))); then
        echo "\e[38;5;58m"
    elif (($(bc <<<"$speed_kbps < 1000"))); then
        echo "\e[38;5;178m"
    elif (($(bc <<<"$speed_kbps < 2000"))); then
        echo "\e[38;5;34m"
    else
        echo "\e[38;5;46m"
    fi
}

# Function to convert speed to human-readable format
convert_speed() {
    local speed=$1
    if ((speed >= 1000000000)); then
        echo "$(bc -l <<<"scale=1; $speed / 1000000000") Gbps"
    elif ((speed >= 1000000)); then
        echo "$(bc -l <<<"scale=1; $speed / 1000000") Mbps"
    elif ((speed >= 1000)); then
        echo "$(bc -l <<<"scale=1; $speed / 1000") Kbps"
    else
        echo "${speed} Bps"
    fi
}

# Function to show help message
show_help() {
    awk '/^#%/{gsub(/^#% ?/,""); print}' "$0"
}

# Function to process command line arguments
process_arguments() {
    if [[ "$*" == *"-h"* || "$*" == *" --help"* ]]; then
        show_help
        exit 0
    fi

    while [[ "$1" != "" ]]; do
        case "$1" in
        -c | --country)
            shift
            while [[ "$1" != "" && "$1" != "-"* ]]; do
                country_code=$(echo "$1" | tr '[:lower:]' '[:upper:]')
                COUNTRY_CODE_INCLUDED+=("$country_code")
                shift
            done
            ;;
        -a | --auto-select)
            check_root
            auto_select=true
            backup=true
            ;;
        -b | --backup)
            check_root
            backup=true
            ;;
        *)
            show_help
            exit 1
            ;;
        esac
        shift
    done
}

# Function to fetch mirrors
fetch_mirrors() {
    mkdir -p "$SCRIPT_DIR/.cache"
    for country_code in "${COUNTRY_CODE_INCLUDED[@]}"; do
        wget -q -O- "http://mirrors.ubuntu.com/$country_code.txt" >>"$SCRIPT_DIR/.cache/mirrors.txt"
    done
}

# Function to test mirror speed
test_mirror_speed() {
    local mirrors=("$@")
    declare -A speeds

    if [ -f "$SCRIPT_DIR/.cache/mirrors.txt" ]; then
        mapfile -t mirrors <"$SCRIPT_DIR/.cache/mirrors.txt"
        total_mirrors=${#mirrors[@]}

        echo -e "\nTesting mirrors for speed..."

        seq_num=0
        for mirror_url in "${mirrors[@]}"; do
            seq_num=$((seq_num + 1))
            raw_speed_bps=$(curl --max-time 2 -r 0-102400 -s -w %{speed_download} -o /dev/null "$mirror_url/ls-lR.gz")
            speed=$(convert_speed "$raw_speed_bps")
            speeds["$mirror_url"]="$raw_speed_bps"
            echo -e "[$seq_num/$total_mirrors] $mirror_url --> $(format_color "$raw_speed_bps") $speed $speed_unit $reset_color"
        done

        sorted_mirrors=$(for mirror in "${!speeds[@]}"; do echo "$mirror ${speeds[$mirror]}"; done | sort -rn -k2 | head -n "$TOP_LIST_AMOUNT" | nl)

        echo -e "\n\e[1mTop $TOP_LIST_AMOUNT fastest mirrors:\e[0m"
        while read -r line; do
            line_number=$(echo "$line" | awk '{print $1}')
            mirror=$(echo "$line" | awk '{print $2}')
            speed=$(echo "$line" | awk '{print $3}')
            echo -e "\e[2m$line_number\e[0m $mirror --> $(format_color "$speed") $(convert_speed "$speed") $reset_color"
            top_mirrors+=("$mirror")
        done <<<"$sorted_mirrors"

    else
        echo "No mirrors found. Please provide at least one valid country code."
    fi
}

# Function to check country code and retrieve mirrors
check_country_code() {
    if [ "${#COUNTRY_CODE_INCLUDED[@]}" -eq 0 ]; then
        COUNTRY_CODE_INCLUDED=("mirrors")
        echo "No country code provided using -c or --country options"
        echo "Retrieving list from http://mirrors.ubuntu.com/mirrors.txt"
    else
        for country_code in "${COUNTRY_CODE_INCLUDED[@]}"; do
            if ! validate_country_code "$country_code"; then
                exit 1
            fi
        done
        echo "Using mirrors from:"
        for country_code in "${COUNTRY_CODE_INCLUDED[@]}"; do
            echo "http://mirrors.ubuntu.com/$country_code.txt"
        done
    fi
}

# Function to check if script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script requires root privileges. Please run it with sudo."
        exit 1
    fi
}

# Function to select mirror
select_mirror() {
    real_top_mirrors_count=${#top_mirrors[@]}

    if [ "$real_top_mirrors_count" -eq 0 ]; then
        echo "Error. No mirrors found."
        exit 1
    fi

    if [ "$auto_select" = true ]; then
        newMirror=${top_mirrors[0]}

    else
        echo -e "\nSelect one of the top $real_top_mirrors_count fastest mirrors. This will apply the selected mirror to your apt sources.list"
        read -rp "Select from 1 to $real_top_mirrors_count , or enter 0 to cancel: " newMirror
        if [ "$newMirror" -eq 0 ]; then
            echo -e "Cancelled. No changes made.\nExiting..."
            exit 0
        fi

        if ! [[ "$newMirror" =~ ^[0-9]+$ ]] || [ "$newMirror" -gt "$real_top_mirrors_count" ] || [ "$newMirror" -lt 1 ]; then
            echo "Error. Invalid selection."
            exit 1
        fi
        newMirror=${top_mirrors[$((newMirror - 1))]}
    fi
    if [ "$backup" = true ]; then
        time_postfix=$(date -u +"UTC%Y-%m-%dT%H_%M_%S")
        mkdir -p /etc/apt/sources.list.backup && cp -rp /etc/apt/sources.list /etc/apt/sources.list.backup/sources.list."$time_postfix".bak
        if [-f /etc/apt/sources.list.backup/sources.list."$time_postfix".bak]; then
            echo -e "Backup created in /etc/apt/sources.list.backup/sources.list."$time_postfix".bak\n"
        else
            echo "Backup failed."
            exit 1
        fi
    fi
    
    echo "Selected mirror: $newMirror"
    echo "Updating sources.list..."
    sudo sed -i "s|deb [a-z]*://[^ ]* |deb ${newMirror} |g" /etc/apt/sources.list
    sleep 2
    echo "testing new mirror speed with apt update..."
    sudo rm -rf /var/lib/apt/lists/* && sudo apt update
}

# Trap to cleanup cache on exit
trap cleanup_cache EXIT

# Main execution
process_arguments "$@"
check_country_code
fetch_mirrors
test_mirror_speed "${COUNTRY_CODE_INCLUDED[@]}"
select_mirror
