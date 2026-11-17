#!/usr/bin/env bash
# One-time YouTube sign-in. Needs your own client_secret.json (see README: "Get your free YouTube API key").
D="$(cd "$(dirname "$0")" && pwd)"; . "$D/kit_env.sh"
command -v yutu >/dev/null || { echo "yutu not found - run the Setup script first."; pause_exit 1; }
mkdir -p "$KIT_CONF"; chmod 700 "$KIT_CONF" 2>/dev/null
for f in "$ROOT/.secrets/client_secret.json" "$ROOT/client_secret.json"; do [ -f "$f" ] && mv -f "$f" "$KIT_CONF/client_secret.json"; done
rmdir "$ROOT/.secrets" 2>/dev/null
[ -f "$KIT_CONF/client_secret.json" ] || { echo "client_secret.json not found. Put it in: $ROOT/.secrets/  then run this again."; pause_exit 1; }
chmod 600 "$KIT_CONF/client_secret.json" 2>/dev/null; cd "$KIT_CONF" || pause_exit 1
echo "Your browser will open. Pick the Google account that owns your YouTube channel."
echo "If Google says the app isn't verified: click Continue (it's your own app), allow all YouTube permissions, then Continue."
yutu auth --credential client_secret.json --cacheToken youtube.token.json || { echo "Sign-in failed."; pause_exit 1; }
[ -f youtube.token.json ] || { echo "No token saved."; pause_exit 1; }
chmod 600 youtube.token.json 2>/dev/null
echo; echo "==== Test: your channel ===="
YUTU_CREDENTIAL=client_secret.json YUTU_CACHE_TOKEN=youtube.token.json yutu channel list --for mine --parts id,snippet 2>&1 | head -20
echo; echo "CONNECTED. If uploads later fail with an auth error, run this again."; pause_exit 0
