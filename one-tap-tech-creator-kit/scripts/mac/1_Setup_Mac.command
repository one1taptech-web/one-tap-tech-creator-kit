#!/bin/bash
# Creator Kit setup for macOS (Intel or Apple Silicon). Double-click to run. Safe to re-run: skips what is already installed.
# Free tools from official sources -> ~/.local/bin : ffmpeg/ffprobe (evermeet.cx), yt-dlp, deno, uv, yutu (GitHub releases);
# optional: video-use (GitHub, PR #151 local Whisper). Folder: ~/Documents/CreatorKit unless ~/.creator-kit/root.txt says otherwise.
KIT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$HOME/.creator-kit"; chmod 700 "$HOME/.creator-kit"
[ -s "$HOME/.creator-kit/root.txt" ] || echo "${KIT_ROOT:-$HOME/Documents/CreatorKit}" > "$HOME/.creator-kit/root.txt"
. "$KIT/common/kit_env.sh"; mkdir -p "$ROOT/scripts"
LOG="$ROOT/scripts/setup_log.txt"; exec > >(tee "$LOG") 2>&1
BIN="$HOME/.local/bin"; mkdir -p "$BIN"; TMP="$(mktemp -d)"
ARCH="$(uname -m)"; case "$ARCH" in arm64) A=arm64; R=aarch64;; *) A=amd64; R=x86_64;; esac
step(){ echo; echo "==== $* ===="; }
fail(){ echo; echo "!!!! STOPPED: $*"; echo "Nothing was broken. Fix the problem (or ask Claude) and run this again."; pause_exit 1; }
get(){ curl -fL --retry 3 --connect-timeout 20 -o "$1" "$2"; }
unq(){ chmod +x "$1"; xattr -d com.apple.quarantine "$1" 2>/dev/null; hash -r; true; }
echo "Creator Kit setup (Mac) $(date) | macOS $(sw_vers -productVersion) | $ARCH | folder: $ROOT"

step "1/8 Folders + scripts"
bash "$KIT/common/create_folders.sh" "$ROOT" >/dev/null || fail "could not create folders in $ROOT"
if [ "$KIT" != "$ROOT/scripts" ]; then cp -R "$KIT/common" "$KIT/mac" "$KIT/windows" "$KIT/templates" "$ROOT/scripts/" 2>/dev/null; cp -R "$KIT/claude" "$ROOT/scripts/" 2>/dev/null; fi
for t in research_queries.txt youtube_job.json; do [ -f "$ROOT/scripts/$t" ] || cp "$KIT/templates/$t" "$ROOT/scripts/$t"; done
chmod +x "$ROOT"/scripts/mac/*.command 2>/dev/null; ls "$ROOT"

step "2/8 Apple command line tools (git)"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  read -r -p "Click Install in the pop-up, wait until it finishes, then press Return here." _
  xcode-select -p >/dev/null 2>&1 || fail "Command Line Tools are not installed yet."
fi
git --version || fail "git missing"

step "3/8 ffmpeg + ffprobe (evermeet.cx static build)"
if ! ffmpeg -version >/dev/null 2>&1; then
  if [ "$ARCH" = arm64 ] && ! /usr/bin/pgrep -q oahd; then softwareupdate --install-rosetta --agree-to-license || fail "Rosetta install failed"; fi
  for b in ffmpeg ffprobe; do
    u="$(curl -fsSL --retry 3 "https://evermeet.cx/ffmpeg/info/$b/release" | grep -o "https://evermeet.cx/ffmpeg/$b-[0-9.]*\.zip" | head -1)"
    { [ -n "$u" ] && get "$TMP/$b.zip" "$u"; } || get "$TMP/$b.zip" "https://evermeet.cx/ffmpeg/$b-9.0.2.zip" || fail "download $b failed"
    unzip -o -q "$TMP/$b.zip" -d "$TMP" && mv -f "$TMP/$b" "$BIN/$b" && unq "$BIN/$b" || fail "unpack $b failed"
  done
fi
ffmpeg -version | head -1; ffprobe -version >/dev/null 2>&1 || fail "ffprobe does not run"

step "4/8 yt-dlp"
yt-dlp --version >/dev/null 2>&1 || { get "$BIN/yt-dlp" https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos && unq "$BIN/yt-dlp"; }
yt-dlp --version || fail "yt-dlp does not run"

step "5/8 deno (yt-dlp needs it for YouTube)"
if ! deno --version >/dev/null 2>&1; then
  get "$TMP/deno.zip" "https://github.com/denoland/deno/releases/latest/download/deno-$R-apple-darwin.zip" && unzip -o -q "$TMP/deno.zip" -d "$BIN" && unq "$BIN/deno" || fail "deno install failed"
fi
deno --version | head -1 || fail "deno does not run"

step "6/8 uv (runs Python scripts, fetches Python itself)"
if ! uv --version >/dev/null 2>&1; then
  get "$TMP/uv.tgz" "https://github.com/astral-sh/uv/releases/latest/download/uv-$R-apple-darwin.tar.gz" && tar xzf "$TMP/uv.tgz" -C "$TMP" && mv -f "$TMP/uv-$R-apple-darwin/uv" "$TMP/uv-$R-apple-darwin/uvx" "$BIN/" && unq "$BIN/uv" && unq "$BIN/uvx" || fail "uv install failed"
fi
uv --version || fail "uv does not run"

step "7/8 yutu (YouTube sign-in)"
yutu version >/dev/null 2>&1 || { get "$BIN/yutu" "https://github.com/eat-pray-ai/yutu/releases/latest/download/yutu-darwin-$A" && unq "$BIN/yutu"; }
yutu version || fail "yutu does not run"

step "8/8 video-use (optional, for Claude Code video editing)"
VU="$HOME/Developer/video-use"; VUS="skipped"
if [ "${SKIP_VIDEO_USE:-0}" != 1 ]; then
  mkdir -p "$HOME/Developer"
  ( [ -d "$VU/.git" ] || git clone -q https://github.com/browser-use/video-use "$VU" ) && cd "$VU" && \
  ( git rev-parse --verify -q local-whisper >/dev/null || git fetch -q origin pull/151/head:local-whisper ) && git checkout -q local-whisper && \
  { [ "$ARCH" = arm64 ] && EXTRA=stt-mlx || EXTRA=stt-cpu; true; } && \
  { [ "$ARCH" = arm64 ] || grep -q '^\[tool.uv\]' pyproject.toml || printf '\n[tool.uv]\nconstraint-dependencies = ["onnxruntime<1.24", "numba<0.63", "llvmlite<0.46"]\n' >> pyproject.toml; } && \
  uv sync -q --extra "$EXTRA" && { touch .env; chmod 600 .env; grep -q '^VIDEO_USE_TRANSCRIBER=' .env || echo 'VIDEO_USE_TRANSCRIBER=local' >> .env; } && \
  uv run python helpers/timeline_view.py --help >/dev/null && mkdir -p "$HOME/.claude/skills" && ln -sfn "$VU" "$HOME/.claude/skills/video-use" && VUS="ok $(git -C "$VU" log -1 --format=%h)" \
  || { VUS="FAILED (optional - everything else still works)"; echo "video-use: $VUS"; }
  cd "$HOME"
fi

grep -q '.local/bin' "$HOME/.zprofile" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zprofile"
{ echo "date=$(date)"; echo "os=macOS $(sw_vers -productVersion) $ARCH"; echo "root=$ROOT"
  echo "ffmpeg=$(ffmpeg -version | head -1)"; echo "yt_dlp=$(yt-dlp --version)"; echo "deno=$(deno --version | head -1)"
  echo "uv=$(uv --version)"; echo "yutu=$(yutu version 2>&1 | head -1)"; echo "video_use=$VUS"; } > "$ROOT/scripts/setup_status.txt"
rm -rf "$TMP"; echo; cat "$ROOT/scripts/setup_status.txt"
echo; echo "ALL DONE. Next: put your client_secret.json in $ROOT/.secrets/ and run 2_Connect_YouTube."; pause_exit 0
