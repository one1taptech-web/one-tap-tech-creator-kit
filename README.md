# One Tap Tech Creator Kit

Free creator workspace for **Mac and Windows**, made for the One Tap Tech video. One double-click sets up:

- **Folders:** a drop folder for raw videos, one folder per video (raw talking parts, screen recordings, voice clips, script, thumbnails, final Reel/Short/YouTube, publishing), brand assets, music, archive
- **Free tools:** ffmpeg, yt-dlp, deno, uv, yutu, and (optional) video-use. All are official releases. No admin rights or paid plans.
- **Hook research:** finds the most-viewed Shorts for your search phrases and makes first-frame contact sheets
- **YouTube details:** fills the title, description, tags, thumbnail and schedule from one file
- **A Claude skill**, so Claude can do all of this for you, plus set up its own video-editing toolkit

## Use it with Claude (easiest)
1. Download **one-tap-tech-creator-kit.zip** from this repo (click the file → Download raw file).
2. In Claude, make sure **Settings → Capabilities → Code execution and file creation** ("Create and edit files") is on. Then go to **Customize → Skills → + → Create skill → Upload a skill** and choose `one-tap-tech-creator-kit.zip`.
3. Open the **Claude desktop app** and say: *"Set up my creator kit."* Allow folder access and computer use when Claude asks.

## Use it without Claude
1. Download and unzip this repo.
2. Open `one-tap-tech-creator-kit/scripts/`:
   - **Mac:** double-click `mac/1_Setup_Mac.command`. If macOS says it can't be opened: **System Settings → Privacy & Security → Open Anyway** (on macOS 14 and older, right-click the file → Open).
   - **Windows:** double-click `windows/1_Setup_Windows.bat`. If SmartScreen appears: More info → Run anyway.
3. Your kit folder is created at `Documents/CreatorKit`, with a copy of all the scripts inside `scripts/`. From now on, use the launchers in that copy:
   `2_Connect_YouTube` → `3_Research` → `4_YouTube_Update_or_Upload`

Optional: to use another folder, set `KIT_ROOT` before the first setup, or put the full path in `~/.creator-kit/root.txt`.

## Get your free YouTube API key (one time, about 10 minutes)
1. Go to **console.cloud.google.com** → sign in with the Google account that owns your channel → **Select a project → New project** (any name) → Create.
2. **APIs & Services → Library** → search **YouTube Data API v3** → **Enable**.
3. **APIs & Services → OAuth consent screen** (Google Auth Platform): User type **External**, app name, your email → save. Under **Audience / Test users**, **add your own Gmail**.
4. **APIs & Services → Credentials → Create credentials → OAuth client ID** → Application type **Desktop app** → Create → **Download JSON**.
5. Rename the file to **client_secret.json** and put it in `CreatorKit/.secrets/`. Then run **2_Connect_YouTube**, pick your channel's account, and click Continue on "Google hasn't verified this app" (it's your own app).

Keep `client_secret.json` private. Never share it or upload it anywhere.

## Good to know
- **YouTube uploads:** Google locks videos uploaded through the API to **Private** when the Google project hasn't been audited, and they can't be made public. So the recommended way is: upload your video yourself (YouTube app or Studio) as Private, then use **mode "update"** in `youtube_job.json` with the video ID to fill everything else, including the schedule.
- **Sign-in expiry:** while your Google app is in *Testing*, the sign-in lasts 7 days. Just run 2_Connect_YouTube again.
- **Custom thumbnails** need a phone-verified YouTube channel.
- **video-use** is optional. It comes from an unmerged pull request (#151) of browser-use/video-use for free local Whisper. If it fails, everything else still works. To skip it, run setup with `SKIP_VIDEO_USE=1`.
- **What setup changes:** Mac: `~/.local/bin`, `~/.zprofile` (PATH), `~/Developer/video-use`, `~/.creator-kit`. Windows: `%LOCALAPPDATA%\CreatorKit`, user PATH, Git for Windows, `%USERPROFILE%\Developer\video-use`, `%USERPROFILE%\.creator-kit`.
- **Uninstall:** delete the folders above. Your kit folder and videos are never touched by uninstalling.

## Tool sources
ffmpeg: evermeet.cx (Mac), BtbN/FFmpeg-Builds (Windows) · yt-dlp: yt-dlp/yt-dlp · deno: denoland/deno · uv: astral-sh/uv · yutu: eat-pray-ai/yutu · Git: git-for-windows · video-use: browser-use/video-use · dovi_tool: quietvoid/dovi_tool · fonts: Google Fonts (OFL)

Each tool keeps its own license. The kit scripts are MIT licensed.
