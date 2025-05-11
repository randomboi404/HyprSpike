#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path_to_img>"
  exit 1
fi

IMAGE="$1"

notify-send "Changing Theme" "Applying new theme..."

swww img "$IMAGE" --transition-type="fade" --transition-step=1 --transition-fps="60"

wal -i "$IMAGE" -n -s -t -e

matugen image "$IMAGE"
