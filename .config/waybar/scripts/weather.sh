#!/bin/bash

API_KEY="API_KEY HERE"
LOCATION="City name"
UNITS="C"
API_URL="https://api.weatherapi.com/v1/current.json?key=${API_KEY}&q=${LOCATION}&aqi=no"
CACHE_FILE="/tmp/weather.jsonc"

get_weather_icon() {
    case $1 in
        Sunny) echo "" ;;
        Clear) echo "" ;;
        Partly\ Cloudy) echo "" ;;
        Cloudy) echo "" ;;
        Overcast) echo "" ;;
        Mist|Fog) echo "" ;;
        Patchy\ rain\ possible|Patchy\ light\ drizzle|Light\ drizzle|Light\ rain|Patchy\ rain\ nearby) echo "" ;;
        Moderate\ rain|Heavy\ rain|Torrential\ rain) echo "" ;;
        Thunderstorm|Patchy\ thunderstorm) echo "" ;;
        Snow|Patchy\ snow|Light\ snow|Moderate\ snow|Heavy\ snow) echo "" ;;
        *) echo "" ;;
    esac
}

# Try to fetch from API
response=$(curl -s --max-time 5 "${API_URL}")
if [[ $? -eq 0 && -n "$response" && $(echo "$response" | jq -e .current > /dev/null 2>&1; echo $?) -eq 0 ]]; then
    echo "$response" > "$CACHE_FILE"
else
    # If API fails, try to read from cache
    if [[ -f "$CACHE_FILE" ]]; then
        response=$(cat "$CACHE_FILE")
    else
        exit 0
    fi
fi

condition=$(echo "$response" | jq -r '.current.condition.text')
temperature=$(echo "$response" | jq -r ".current.temp_${UNITS,,}")
icon=$(get_weather_icon "$condition")

if [[ $1 == "icon" ]]; then
    echo "$icon"
elif [[ $1 == "text" ]]; then
    echo "{\"text\": \"${temperature}°${UNITS}\", \"tooltip\": \"$condition\"}"
elif [[ $1 == "lock" ]]; then
    echo "${temperature}°${UNITS}\n${condition}"
else
    echo "Usage: $0 [icon|text]"
    exit 1
fi
