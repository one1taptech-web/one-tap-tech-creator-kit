# Shared settings for every Creator Kit script (sourced, not run). Works in macOS bash and Git Bash on Windows.
KIT_CONF="$HOME/.creator-kit"
KIT_ROOT_DEFAULT="$HOME/Documents/CreatorKit"
win_to_unix(){ if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi; }
unix_to_win(){ if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi; }
if [ -s "$KIT_CONF/root.txt" ]; then ROOT="$(win_to_unix "$(tr -d '\r' < "$KIT_CONF/root.txt" | head -1)")"; else ROOT="$KIT_ROOT_DEFAULT"; fi
export PATH="$HOME/.local/bin:$HOME/.deno/bin:$PATH"
if [ -n "${LOCALAPPDATA:-}" ]; then export PATH="$(win_to_unix "$LOCALAPPDATA")/CreatorKit/bin:$PATH"; fi
export PYTHONIOENCODING=utf-8
pause_exit(){ echo; read -r -p "Press Return to close." _; exit "${1:-0}"; }
