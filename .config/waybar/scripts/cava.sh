#!/usr/bin/env bash

# Configuration
CPU_LIMIT=50
SCRIPT_PID=$$
TMP_DIR=${HYDE_RUNTIME_DIR:-/tmp}

help_msg() {
  cat <<HELP
Usage: $(basename "$0") [stdout|waybar|hyprlock]
Prints a left–right mirrored, dark-to-light red visualizer,
immediately shows a symmetric idle bar whenever audio is silent,
and limits both cava and this script to the specified percent CPU.
HELP
  exit 1
}

stdout() {
  local name="${cava_cmd:-stdout}"
  local cfg="${TMP_DIR}/cava.${name}"
  
  # Kill any existing cava instances
  pkill -x cava >/dev/null 2>&1
  
  # Parse arguments
  local bar="${cava_bar:-▁▂▃▄▅▆▇█}"
  local bar_length=${#bar}
  local bar_width=${cava_width:-$bar_length}
  local bar_range=${cava_range:-$((bar_length-1))}
  
  # Generate cava config for 20 FPS
  cat >"$cfg" <<EOF
[general]
bars = ${bar_width}
sleep_timer = 0.05
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = ${bar_range}
EOF

  # Pre-generate color values for performance - compute once not every frame
  declare -a red_values
  local mid=$((bar_width/2))
  for ((j=0; j<bar_width; j++)); do
    local dist=$(( j<mid ? j : bar_width-j-1 ))
    local red=$(( 100 + dist*155/mid ))
    (( red>255 )) && red=255
    red_values[j]=$(printf "%02X" "$red")
  done
  
  # Pre-generate character indices for idle bar
  declare -a idle_indices
  for ((j=0; j<bar_width; j++)); do
    local dist=$(( j<mid ? j : bar_width-j-1 ))
    local idx=$(( bar_range - dist*bar_range/mid ))
    (( idx<0 )) && idx=0
    idle_indices[j]=$idx
  done
  
  # Build idle string - do this once, not every time
  build_idle() {
    local s=""
    for ((j=0; j<bar_width; j++)); do
      local ch="${bar:${idle_indices[j]}:1}"
      s+="<span color=\"#${red_values[j]}0000\">$ch</span>"
    done
    printf '%s' "$s"
  }
  
  # Generate idle visualization once
  local idle_str=$(build_idle)
  
  # Output idle immediately
  echo "$idle_str"
  
  # Start cava in a coprocess to capture its PID
  coproc CAVAPROC { stdbuf -oL cava -p "$cfg"; }
  local cava_pid=$CAVAPROC_PID
  
  # Limit CPU usage
  limitcpu -p "$cava_pid" -l $CPU_LIMIT &
  limitcpu -p "$SCRIPT_PID" -l $CPU_LIMIT &
  
  # Process cava output
  local IFS=';'
  local -a levels
  while IFS= read -r line <&"${CAVAPROC[0]}"; do
    read -ra levels <<< "$line"
    
    # Fast silence check
    local all_zero=1
    for l in "${levels[@]}"; do
      [[ "$l" -ne 0 ]] && { all_zero=0; break; }
    done
    
    if (( all_zero )); then
      echo "$idle_str"
      continue
    fi
    
    # Build mirrored, gradient-colored output efficiently
    local out=""
    for ((j=0; j<bar_width; j++)); do
      # Use mirrored value for right half
      if (( j <= mid )); then
        lvl="${levels[j]:-0}"
      else
        lvl="${levels[bar_width-1-j]:-0}"
      fi
      
      # Clamp level values
      (( lvl<0 )) && lvl=0
      (( lvl>bar_range )) && lvl=bar_range
      
      # Use pre-computed color values
      out+="<span color=\"#${red_values[j]}0000\">${bar:lvl:1}</span>"
    done
    
    echo "$out"
  done
}

case "$1" in
  stdout)
    shift; stdout "$@" ;;
  waybar)
    cava_cmd=waybar
    cava_bar="$CAVA_WAYBAR_BAR" \
    cava_width="$CAVA_WAYBAR_WIDTH" \
    cava_range="$CAVA_WAYBAR_RANGE"
    stdout ;;
  hyprlock)
    cava_cmd=hyprlock
    cava_bar="$CAVA_HYPRLOCK_BAR" \
    cava_width="$CAVA_HYPRLOCK_WIDTH" \
    cava_range="$CAVA_HYPRLOCK_RANGE"
    stdout ;;
  *) help_msg ;;
esac
