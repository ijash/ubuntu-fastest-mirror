#!/bin/bash

# Set default value
COUNTRY_CODE_INCLUDED=()
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TOP_LIST_AMOUNT=5
reset_color='\033[0m'
cleanup_cache() {
    rm -rf "$SCRIPT_DIR/.cache"
}

validate_country_code() {
    local code="$1"
    if ! wget -q --spider "http://mirrors.ubuntu.com/$code.txt"; then
        echo "Error: Invalid country code '$code'" >&2
        return 1 # Return non-zero to indicate error
    fi
    return 0 # Return zero for valid code
}

format_color() {
    local speed_bps=$1

    # Convert bytes per second to kilobits per second
    speed_kbps=$(bc -l <<<"$speed_bps / 1000")

    local low_speed=100
    local medium_speed=275
    local high_speed=1000
    local very_high_speed=2000

    # if 0 speed
    if (($(bc <<<"$speed_kbps == 0"))); then
        echo "\e[38;5;9m" # red
    elif (($(bc <<<"$speed_kbps < $low_speed"))); then
        echo "\e[38;5;88m" # dark red    
    elif (($(bc <<<"$speed_kbps < $medium_speed"))); then
        echo "\e[38;5;58m" # brown
    elif (($(bc <<<"$speed_kbps < $high_speed"))); then
        echo "\e[38;5;178m" # yellow
    elif (($(bc <<<"$speed_kbps < $very_high_speed"))); then
        echo "\e[38;5;34m" #  green
    else
        echo "\e[38;5;46m" # bright green
    fi
}

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

show_help() {
    echo "Ubuntu Mirror Speed Checker"
    echo ""
    echo "Description:"
    echo "This script retrieves a list of Ubuntu mirrors based on specified country codes. If no country codes are provided, it defaults to using mirrors.txt, which contains geographic mirrors based on the client's source IP address. It then tests the speed of each mirror and displays the top fastest mirrors. You can check the current status of mirrors at https://launchpad.net/ubuntu/+archivemirrors and find available country codes at http://mirrors.ubuntu.com/."
    echo ""
    echo "Usage:"
    echo "$0 [-h|--help] [-c|--country <country-code> ...]"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message and exit."
    echo "  -c, --country    Specify one or more country codes to retrieve mirrors from. If not provided, the script will default to using mirrors from http://mirrors.ubuntu.com/mirrors.txt."
    echo ""
    echo "Example A:"
    echo "  $0 -c US JP ID"
    echo ""
    echo "Example B:"
    echo "  $0"
    echo ""
    echo "By: Jastria Rahmat | https://www.github.com/ijash"
}



trap cleanup_cache EXIT

# Check if -h is in the arguments
if [[ "$*" == *"-h"* || "$*" == *" --help"* ]]; then
    show_help
    exit 0
fi

# Parse command-line options
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
    *)
        echo "Usage: $0 [-c|--country <country-code> ...]" >&2
        exit 1
        ;;
    esac
    shift
done

# Set default value if no country code provided
if [ "${#COUNTRY_CODE_INCLUDED[@]}" -eq 0 ]; then
    COUNTRY_CODE_INCLUDED=("mirrors")
    echo "No country code provided using -c or --country options"
    echo "Retrieving list from http://mirrors.ubuntu.com/mirrors.txt"
else

    # Validate and fetch mirrors for each country code
    for country_code in "${COUNTRY_CODE_INCLUDED[@]}"; do
        if ! validate_country_code "$country_code"; then
            exit 1 # Exit script on any validation error
        fi
    done
    # Print the assigned country code
    echo "Using mirrors from:"
    for country_code in "${COUNTRY_CODE_INCLUDED[@]}"; do
        echo "http://mirrors.ubuntu.com/$country_code.txt"
    done
fi

# Fetch the HTML list of Ubuntu mirrors and extract URLs of up-to-date mirrors
mkdir -p "$SCRIPT_DIR/.cache"
for country_code in "${COUNTRY_CODE_INCLUDED[@]}"; do
    wget -q -O- "http://mirrors.ubuntu.com/$country_code.txt" >>"$SCRIPT_DIR/.cache/mirrors.txt"
done

# Read the list of mirrors
mapfile -t mirrors <"$SCRIPT_DIR/.cache/mirrors.txt"
total_mirrors=${#mirrors[@]}

# Array to hold speeds
declare -A speeds

# Check if the mirrors.txt file exists before reading it
if [ -f "$SCRIPT_DIR/.cache/mirrors.txt" ]; then
    # Read the list of mirrors
    mapfile -t mirrors <"$SCRIPT_DIR/.cache/mirrors.txt"
    total_mirrors=${#mirrors[@]}

    # Array to hold speeds
    declare -A speeds

    echo "Testing mirrors for speed..."

    # Test each mirror with a 2-second timeout
    seq_num=0
    for mirror_url in "${mirrors[@]}"; do
        # Increment the sequence number
        seq_num=$((seq_num + 1))

        # Get the speed in bytes per second and convert to kilobytes per second
        raw_speed_bps=$(curl --max-time 2 -r 0-102400 -s -w %{speed_download} -o /dev/null "$mirror_url/ls-lR.gz")

        # Convert bytes per second to kilobytes per second
        speed=$(convert_speed "$raw_speed_bps")

        # Save the speed with the mirror URL
        speeds["$mirror_url"]="$raw_speed_bps"

        # Print the mirror and speed
        echo -e "[$seq_num/$total_mirrors] $mirror_url --> $(format_color "$raw_speed_bps") $speed $speed_unit $reset_color"
    done

    # Sort the array based on speed using sort command and head
    sorted_mirrors=$(for mirror in "${!speeds[@]}"; do echo "$mirror ${speeds[$mirror]}"; done | sort -rn -k2 | head -n "$TOP_LIST_AMOUNT" | nl)

    # Print the top 5 fastest mirrors
    echo ""
    echo -e "\e[1mTop $TOP_LIST_AMOUNT fastest mirrors:\e[0m"
    # for loop to format the color
    while read -r line; do
        line_number=$(echo "$line" | awk '{print $1}')
        mirror=$(echo "$line" | awk '{print $2}')
        speed=$(echo "$line" | awk '{print $3}')
        echo -e "\e[2m$line_number\e[0m $mirror --> $(format_color "$speed") $(convert_speed "$speed") $reset_color"
    done <<<"$sorted_mirrors"

else
    echo "No mirrors found. Please provide at least one valid country code."
fi