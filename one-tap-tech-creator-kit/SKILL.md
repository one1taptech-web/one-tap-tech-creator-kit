---
name: one-tap-tech-creator-kit
description: Set up a YouTube/Reels creator workspace on Mac or Windows - folder layout, free tools (ffmpeg, yt-dlp, deno, uv, yutu, video-use), hook research, YouTube metadata/upload - plus Claude's own editing toolkit. Use for "set up my creator kit", "create my video folders", "add a new video folder", "research hooks", "fill my YouTube details".
---

# One Tap Tech Creator Kit

Free, local tools for a solo creator who films a talking part + screen demos and posts Reels/Shorts/YouTube videos. Works on macOS (Intel/Apple Silicon) and Windows 10/11 (x64/ARM64). Everything is free; nothing needs a paid plan.

All scripts are in this skill's `scripts/` folder:
- `common/` bash + Python used on both systems (`create_folders.sh`, `research.sh`, `connect_youtube.sh`, `youtube.sh`, `yt_tool.py`, `kit_env.sh`)
- `mac/` double-click `.command` launchers · `windows/` double-click `.bat` launchers (they run the common scripts through Git Bash)
- `templates/` `research_queries.txt`, `youtube_job.json` · `claude/setup_editing_toolkit.sh` (Claude's workspace only)

## Rules
- Do the work yourself through the Claude desktop app's folder access and computer use; ask for access with the access prompt instead of handing the user steps. If the chat isn't linked to their computer, tell them to open this chat in the Claude desktop app, or give them the README's manual steps.
- Never move, rename or delete the user's existing files. Every script only creates what is missing and is safe to re-run.
- Never put the user's `client_secret.json`, tokens or passwords in chat, memory, skills or public places. They stay in `~/.creator-kit/` (Windows: `%USERPROFILE%\.creator-kit\`).
- Install nothing beyond what's listed here. Each tool comes from its official release.
- Before you report anything as done, QA it (see the last section).

## 1. Start
Ask once, together: (a) where the kit folder should go (default `Documents/CreatorKit`; an existing work folder is fine), (b) a name for their first video folder (optional, e.g. `V01_My_Video`). Find their OS with `get_device_info` (or by asking).

## 2. Folders (approved layout)
```
00_Add_Raw_Videos/   <- drop new raw recordings here
01_Videos/<video>/   01_Raw_Talking_Reel 02_Raw_Talking_YouTube 03_Screen_Recordings_Demo 04_Voice_Clips 05_Photos_Screenshots
                     06_Script (research/ inside) 07_Thumbnails 08_Final_Reel 09_Final_Short 10_Final_YouTube 11_Publishing
02_Brand_Assets/  03_Music_SFX/  04_Reference_Packs/  05_Shortcut_Links/  06_Posted_Archive/  scripts/
```
Request access to the folder's parent → write `~/.creator-kit/root.txt` with the full kit path (create `~/.creator-kit` if needed; on Windows use the Windows path, e.g. `C:\Users\<name>\Documents\CreatorKit`). Copy this skill's `scripts/` contents into `<root>/scripts/` (device_commit_files / device_bash), then `chmod +x` the `.command` files (an edit drops the exec bit). Run `bash <root>/scripts/common/create_folders.sh <root> [video names...]` in device_bash (it works for Windows folders too, because the folder is mounted there) and check the printed tree.
**New video later:** run the same script with just the new folder name.

## 3. Free tools on their computer
The device_bash shell is a Linux VM and can't install Mac/Windows programs, so run the setup on the computer itself with computer use: open the kit's `scripts` folder in Finder / File Explorer and double-click
- Mac: `mac/1_Setup_Mac.command` (Terminal only accepts clicks: just watch it). It installs ffmpeg/ffprobe, yt-dlp, deno, uv and yutu into `~/.local/bin`, plus video-use (optional) into `~/Developer/video-use`. On Apple Silicon it adds Rosetta for ffmpeg.
- Windows: `windows/1_Setup_Windows.bat`. It installs Git for Windows (winget, else PortableGit), then ffmpeg/ffprobe, yt-dlp, deno, uv and yutu into `%LOCALAPPDATA%\CreatorKit\bin` (added to the user PATH; no admin needed), plus video-use (optional) into `%USERPROFILE%\Developer\video-use`. If SmartScreen asks, choose "More info → Run anyway" only for these kit files.
QA: read `<root>/scripts/setup_status.txt` (every tool must show a version) and `setup_log.txt`. If it stopped, read the log, fix the cause, and run it again. video-use is optional and comes from an unmerged pull request (#151, free local Whisper). If it fails, the rest still works. Skip it with `SKIP_VIDEO_USE=1`.

## 4. YouTube connection (one time per computer)
1. The user needs their own free Google key. Guide them (or do it in their browser with their OK) using the README section "Get your free YouTube API key". It ends with a downloaded `client_secret.json`.
2. They put it in `<root>/.secrets/` (or `<root>/`). Then run `2_Connect_YouTube` (mac `.command` / windows `.bat`). The browser opens. They pick the channel's Google account, accept the "unverified app" screen (it's their own app) and allow the YouTube permissions.
3. While the Google app is in "Testing", the sign-in expires after 7 days. When a run says the sign-in expired, run `2_Connect_YouTube` again.

## 5. Hook research
Write `<root>/scripts/research_queries.txt` with the video folder on line 1, then one search phrase per line (the phrases people actually search). Run `3_Research`. Results land in `01_Videos/<video>/06_Script/research/run_<date>/`: `top.tsv` (top Shorts by views ≤75 s; change the limit with `MAX_SECONDS`), plus `sheet_0.3.jpg` and `sheet_1.5.jpg` (first-frame contact sheets). Searches take a few minutes. YouTube is only reachable from their computer, not from Claude's workspace.

## 6. YouTube details / upload
Edit `<root>/scripts/youtube_job.json` (template fields: mode, video_id, file, title, description_file, tags, category_id, language, audio_language, privacy, publish_at (UTC ISO, e.g. 2026-12-01T13:30:00Z), thumbnail, made_for_kids, contains_synthetic_media). Paths are relative to the kit folder. Run `4_YouTube_Update_or_Upload` and check the `CHECK` line in the log.
- **mode "update" (recommended):** the user uploads the video as Private from the YouTube app/Studio and gives you the video ID. The tool then sets the title, description, tags, thumbnail and schedule.
- **mode "upload":** uploads the file through the API. Google locks API uploads from unaudited projects created after 28 Jul 2020 to **Private**, so they can't be made public. Say this before using it.
- A custom thumbnail needs a phone-verified YouTube channel. Uploads have a daily limit, so don't bulk upload.

## 7. Claude's editing toolkit (Claude's cloud workspace, never their computer)
At the start of an editing session, run `scripts/claude/setup_editing_toolkit.sh` with Bash in your own workspace. It installs ffmpeg, dovi_tool 2.3.1 (copies Dolby Vision RPU metadata so iPhone HDR footage keeps looking right), faster-whisper (speech timing and silence cut points) and the fonts Inter, Montserrat and Anton (OFL), then self-tests. Move footage in with device_stage_files and finished files out with device_commit_files into the video's `08_/09_/10_Final_*` folders.

## QA before replying
The folder tree is printed. `setup_status.txt` lists a version for every tool. The toolkit self-test passed. For YouTube, the log's `CHECK` line shows the right title, privacy and schedule. Then tell the user briefly what was done and the only steps that need them: creating the Google key and signing in.
