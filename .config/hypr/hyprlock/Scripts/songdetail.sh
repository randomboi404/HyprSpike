#!/bin/bash

# Get metadata (may be empty if no media is playing)
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

# Exit silently if nothing is playing
if [ -z "$title" ] && [ -z "$artist" ]; then
    exit 0
fi

emoji="  "
max_length=50

# Compose full song info
full_info="${title}${emoji}${artist}"

if [ ${#full_info} -gt $max_length ]; then
    artist_reserved=15
    emoji_and_artist="${emoji}${artist}"
    emoji_and_artist_trunc=$(echo "$emoji_and_artist" | cut -c1-$artist_reserved)

    remaining=$((max_length - ${#emoji_and_artist_trunc} - 3))  # reserve for "..."
    title_trunc=$(echo "$title" | cut -c1-$remaining)

    full_info="${title_trunc}...${emoji_and_artist_trunc}"
fi

echo "$full_info"
