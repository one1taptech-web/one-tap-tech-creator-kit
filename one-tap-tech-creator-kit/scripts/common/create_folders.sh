#!/usr/bin/env bash
# Creates the Creator Kit folder layout. Safe to re-run: only creates missing folders, never moves or deletes anything.
# Usage: create_folders.sh <root_folder> [video_folder_name ...]   e.g. create_folders.sh ~/Documents/CreatorKit V01_My_First_Video
set -euo pipefail
ROOT="${1:?root folder required}"; shift || true
TOP=(00_Add_Raw_Videos 01_Videos 02_Brand_Assets 03_Music_SFX 04_Reference_Packs 05_Shortcut_Links 06_Posted_Archive scripts)
SUB=(01_Raw_Talking_Reel 02_Raw_Talking_YouTube 03_Screen_Recordings_Demo 04_Voice_Clips 05_Photos_Screenshots 06_Script 07_Thumbnails 08_Final_Reel 09_Final_Short 10_Final_YouTube 11_Publishing)
mkdir -p "$ROOT"
for d in "${TOP[@]}"; do mkdir -p "$ROOT/$d"; done
for v in "$@"; do
  case "$v" in */*|*\\*|.*|"") echo "Skipped invalid video folder name: '$v'"; continue;; esac
  for s in "${SUB[@]}"; do mkdir -p "$ROOT/01_Videos/$v/$s"; done
done
echo "OK: $ROOT"; (cd "$ROOT" && find . -mindepth 1 -maxdepth 3 -type d ! -path './scripts/*' | sed 's|^\./||' | sort)
