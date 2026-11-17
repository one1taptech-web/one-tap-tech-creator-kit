#!/usr/bin/env bash
# Hook research: finds the most-viewed Shorts for your search phrases and saves first-frame contact sheets.
# Reads <root>/scripts/research_queries.txt : line 1 = video folder name (e.g. V01_My_Video), then one search phrase per line.
D="$(cd "$(dirname "$0")" && pwd)"; . "$D/kit_env.sh"
Q="$ROOT/scripts/research_queries.txt"
[ -f "$Q" ] || { echo "Missing $Q (copy templates/research_queries.txt there and edit it)."; pause_exit 1; }
for t in yt-dlp ffmpeg; do command -v $t >/dev/null || { echo "$t not found - run the Setup script first."; pause_exit 1; }; done
V="$(tr -d '\r' < "$Q" | head -1)"; MAXS="${MAX_SECONDS:-75}"
W="$ROOT/01_Videos/$V/06_Script/research/run_$(date +%m%d_%H%M)"; mkdir -p "$W/clips" "$W/frames" "$W/sheet_in"; cd "$W" || pause_exit 1
T=$'\t'; F="%(id)s${T}%(view_count)s${T}%(duration)s${T}%(channel)s${T}%(title)s"; : > search.tsv
tr -d '\r' < "$Q" | tail -n +2 | while IFS= read -r q; do
  [ -n "$q" ] || continue; echo "Searching: $q"
  yt-dlp --encoding utf-8 --flat-playlist --print "$q${T}$F" "ytsearch30:$q" </dev/null >> search.tsv 2>>log.txt
done
awk -F'\t' -v m="$MAXS" '$3!="NA" && $4!="NA" && $4<=m && !s[$2]++' search.tsv | sort -t"$T" -k3,3nr | head -10 > top.tsv
echo "Top results:"; cut -f3,5,6 top.tsv
n=0; cut -f2 top.tsv | while read -r id; do
  n=$((n+1)); yt-dlp --encoding utf-8 -q --remote-components ejs:github -f "bv*[height<=720]/b" --download-sections "*0-4" -o "clips/$id.%(ext)s" "https://www.youtube.com/shorts/$id" </dev/null 2>>log.txt
  c=$(ls clips/"$id".* 2>/dev/null | head -1); [ -n "$c" ] || continue
  for s in 0.3 1.5; do ffmpeg -nostdin -loglevel error -y -ss $s -i "$c" -frames:v 1 -vf "scale=270:480" "frames/${id}_$s.jpg"; done
done
for s in 0.3 1.5; do  # numbered copies, because Windows ffmpeg has no glob input
  i=0; rm -f sheet_in/*; for f in frames/*_"$s".jpg; do [ -f "$f" ] || continue; i=$((i+1)); cp "$f" "sheet_in/$(printf '%02d' $i).jpg"; done
  [ "$i" -gt 0 ] && ffmpeg -nostdin -loglevel error -y -i sheet_in/%02d.jpg -vf "tile=5x2" -frames:v 1 "sheet_$s.jpg"
done
rm -rf sheet_in; echo DONE > done.txt; echo; echo "Research saved in: $W"; pause_exit 0
