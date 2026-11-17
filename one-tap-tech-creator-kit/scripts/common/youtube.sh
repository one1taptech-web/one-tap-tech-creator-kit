#!/usr/bin/env bash
# Runs yt_tool.py with the job file <root>/scripts/youtube_job.json (Python is fetched automatically by uv).
D="$(cd "$(dirname "$0")" && pwd)"; . "$D/kit_env.sh"
command -v uv >/dev/null || { echo "uv not found - run the Setup script first."; pause_exit 1; }
JOB="${1:-$ROOT/scripts/youtube_job.json}"; [ -f "$JOB" ] || { echo "Missing $JOB (copy templates/youtube_job.json there and edit it)."; pause_exit 1; }
LOG="$ROOT/scripts/youtube_$(date +%m%d_%H%M).log"
uv run --no-project --python 3.12 "$(unix_to_win "$D/yt_tool.py")" "$(unix_to_win "$JOB")" "$(unix_to_win "$ROOT")" "$(unix_to_win "$KIT_CONF")" 2>&1 | tee "$LOG"
echo; echo "Log saved: $LOG"; pause_exit 0
