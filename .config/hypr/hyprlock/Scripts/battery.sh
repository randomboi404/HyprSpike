#!/usr/bin/env bash

ICON_BAT_00=""
ICON_BAT_10=""
ICON_BAT_20=""
ICON_BAT_30=""
ICON_BAT_40=""
ICON_BAT_50=""
ICON_BAT_60=""
ICON_BAT_70=""
ICON_BAT_80=""
ICON_BAT_90=""
ICON_BAT_100=""
ICON_CHARGING=""
ICON_PLUGGED="󰚥"

BAT=/sys/class/power_supply/BAT0
AC=/sys/class/power_supply/AC0
CACHE_FILE="/tmp/battery.txt"

# Read core values
if [[ ! -r "$BAT/energy_now" ]]; then
  echo "No battery found"
  exit 1
fi
energy_now=$(< "$BAT/energy_now")
energy_full=$(< "$BAT/energy_full")
power_now=$(< "$BAT/power_now")

percent=$(< "$BAT/capacity")
status=$(< "$BAT/status")
ac_online=0
if [[ -r "$AC/online" ]]; then
  ac_online=$(< "$AC/online")
fi

# Pick icon
if [[ "$status" == "Charging" ]]; then
  icon=$ICON_CHARGING
elif [[ $ac_online -eq 1 && $percent -ge 100 ]]; then
  icon=$ICON_PLUGGED
elif [[ $ac_online -eq 1 ]]; then
  icon=$ICON_CHARGING
else
  lvl=$(( percent / 10 * 10 ))
  (( lvl < 0 ))   && lvl=0
  (( lvl > 100 )) && lvl=100
  var="ICON_BAT_${lvl}"
  icon=${!var}
fi

# Read previous state from cache
prev_percent=""
prev_status=""
prev_time_display=""
if [[ -f "$CACHE_FILE" ]]; then
  IFS='|' read -r prev_percent prev_status prev_time_display < "$CACHE_FILE"
fi

# Compute time estimate if state changed
time_display=""
state_changed=0
if [[ "$percent" != "$prev_percent" || "$status" != "$prev_status" ]]; then
  state_changed=1
  if (( power_now > 0 )); then
    if [[ "$status" == "Charging" ]] && (( percent < 100 )); then
      secs=$(( (energy_full - energy_now) * 3600 / power_now ))
    elif [[ "$status" == "Discharging" ]]; then
      secs=$(( energy_now * 3600 / power_now ))
    fi

    if [[ -n "$secs" ]]; then
      h=$(( secs / 3600 ))
      m=$(( (secs % 3600) / 60 ))
      if [[ "$status" == "Charging" ]]; then
        time_display="\nTime to Full: $(printf " %d:%02d" "$h" "$m") hrs"
      else
        time_display="\nTime Remaining: $(printf " %d:%02d" "$h" "$m") hrs"
      fi
    fi
  fi

  if [[ $ac_online -eq 1 && $percent -ge 100 ]]; then
    time_display=" - Plugged"
  fi

  # Write new state to cache
  echo "${percent}|${status}|${time_display}" > "$CACHE_FILE"
else
  # Use cached time_display if available
  time_display="$prev_time_display"
fi

echo -n "${icon} ${percent}%${time_display}"
