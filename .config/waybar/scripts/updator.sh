#!/usr/bin/env bash

AUR_HELPER="paru"
UPDATES_DIR="/tmp/updates"

# Create updates directory if it doesn't exist
mkdir -p "$UPDATES_DIR"

# Function to check for updates and always write to files
check_and_write_updates() {
  # Check for official updates
  ofc=$(CHECKUPDATES_DB=$(mktemp -u) checkupdates | wc -l)
  echo "$ofc" > "$UPDATES_DIR/official"

  # Check for AUR updates
  aur=$(${AUR_HELPER} -Qua | grep -v '\[ignored\]' | wc -l)
  echo "$aur" > "$UPDATES_DIR/aur"

  # Check for flatpak updates
  if command -v flatpak >/dev/null 2>&1; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n Flatpak $fpk"
  else
    fpk=0
    fpk_disp=""
  fi
  # Always write flatpak count even if flatpak is not installed
  echo "$fpk" > "$UPDATES_DIR/flatpak"

  total=$((ofc + aur + fpk))
}

# Function to read updates from files if they exist
read_updates_from_files() {
  if [ -f "$UPDATES_DIR/official" ] && [ -f "$UPDATES_DIR/aur" ] && [ -f "$UPDATES_DIR/flatpak" ]; then
    ofc=$(cat "$UPDATES_DIR/official")
    aur=$(cat "$UPDATES_DIR/aur")
    fpk=$(cat "$UPDATES_DIR/flatpak")
    
    if command -v flatpak >/dev/null 2>&1; then
      fpk_disp="\n Flatpak $fpk"
    else
      fpk_disp=""
    fi
    
    total=$((ofc + aur + fpk))
    return 0
  else
    # If any file is missing, do a full check
    check_and_write_updates
    return 1
  fi
}

# For up command, try to read from files first
if [[ "$1" == "up" ]]; then
  read_updates_from_files
else
  # For any other command, always check and write to files
  check_and_write_updates
fi

case "$1" in
  text)
    if [ $total -ne 0 ]; then
      echo "$total"
    fi
    exit
    ;;
  img)
    if [ $total -ne 0 ]; then
      echo "󰮯"
    fi
    exit
    ;;
esac

if [[ "$1" != "up" ]]; then
  exit
fi

if (( ofc + aur + fpk == 0 )); then
  exit
fi

trap 'pkill -SIGUSR2 waybar' EXIT

command=$(cat <<EOF
fastfetch

if (( $ofc > 0 )); then
  sudo pacman -Syu
fi

if (( $aur > 0 )); then
  $AUR_HELPER -Sua
fi

if (( $fpk > 0 )) && command -v flatpak >/dev/null 2>&1; then
  flatpak update --noninteractive
fi
read -n 1 -p 'Press any key to continue...'
EOF
)

kitty --title "System Update" -e bash -c "${command}"
