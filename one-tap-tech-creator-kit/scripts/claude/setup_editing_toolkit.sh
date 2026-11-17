#!/usr/bin/env bash
# For Claude's OWN cloud workspace (Linux), not your computer: video-editing toolkit. Claude re-runs this at the start of an editing session.
# ffmpeg, dovi_tool (Dolby Vision metadata copy/inject), faster-whisper (speech timing / cut points), fonts Inter + Montserrat + Anton (OFL).
set -e
command -v ffmpeg >/dev/null || (apt-get update -qq && apt-get install -y -qq ffmpeg)
T="${TOOLKIT_DIR:-$HOME/.creator-kit-toolkit}"; mkdir -p "$T/fonts"; cd "$T"
[ -x "$T/dovi_tool" ] || { curl -sSfL -o dv.tgz https://github.com/quietvoid/dovi_tool/releases/download/2.3.1/dovi_tool-2.3.1-x86_64-unknown-linux-musl.tar.gz && tar xzf dv.tgz && rm dv.tgz; }
python3 -c "import faster_whisper" 2>/dev/null || pip install -q --break-system-packages faster-whisper 2>/dev/null || pip install -q faster-whisper
for f in "ofl/montserrat/Montserrat%5Bwght%5D.ttf" "ofl/anton/Anton-Regular.ttf" "ofl/inter/Inter%5Bopsz,wght%5D.ttf"; do
  n="$(basename "$f" | sed 's/%5B/[/; s/%5D/]/')"; [ -f "fonts/$n" ] || curl -sSfL -o "fonts/$n" "https://raw.githubusercontent.com/google/fonts/main/$f"; done
mkdir -p "$HOME/.fonts" && cp -f fonts/*.ttf "$HOME/.fonts/" && fc-cache -f >/dev/null 2>&1 || true
echo "== self-test"; ffmpeg -version | head -1; "$T/dovi_tool" --version
python3 - <<'PY'
from faster_whisper import WhisperModel; import numpy as np
m = WhisperModel("tiny", device="cpu", compute_type="int8"); s, i = m.transcribe(np.zeros(16000, np.float32)); list(s); print("faster-whisper OK")
PY
fc-list | grep -iE "Montserrat|Anton|Inter" | sed 's/:.*style=/ : /' | sort -u | head -4
echo "toolkit ready: $T  (dovi_tool: $T/dovi_tool)"
echo "Tip: transcribe from a numpy array (ffmpeg -> s16le 16 kHz mono), because faster_whisper's av.open can fail with some PyAV versions."
