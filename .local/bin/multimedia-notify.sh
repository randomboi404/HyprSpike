#!/usr/bin/env bash

# File to store the last notification ID
NID_FILE="/tmp/volume_notification_id"

# Default sink
SINK="@DEFAULT_AUDIO_SINK@"

# Read previous notification ID if it exists
if [[ -f "$NID_FILE" ]]; then
    NID=$(<"$NID_FILE")
else
    NID=0
fi

case "$1" in
    c)
        # Volume notification
        VOL_LINE=$(wpctl get-volume "$SINK")
        VOL=$(echo "$VOL_LINE" | awk '{ printf "%d", $2 * 100 }')
        TITLE="Volume"
        MSG="${VOL}%"
        ;;
    m)
        # Mute status notification
        VOL_LINE=$(wpctl get-volume "$SINK")
        if echo "$VOL_LINE" | grep -q "\[MUTED\]"; then
            MSG="on"
        else
            MSG="off"
        fi
        TITLE="Mute"
        ;;
    b)
        BRIGHTNESS=$(brightnessctl | awk -F '[()%]' '/Current brightness/ { print $2 }')
        MSG="${BRIGHTNESS}%"
        TITLE="Brightness"
        ;;
    *)
        echo "Usage: $0 [c|m]"
        echo "  c → show volume level"
        echo "  m → show mute status (on/off)"
        exit 1
        ;;
esac

# Send the notification, reusing the same ID so it replaces the old one
NID=$(notify-send -p -r "$NID" "$TITLE" "$MSG")

# Save the new ID
echo "$NID" > "$NID_FILE"
