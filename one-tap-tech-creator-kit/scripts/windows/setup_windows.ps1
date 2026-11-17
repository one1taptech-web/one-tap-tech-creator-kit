# Creator Kit setup for Windows 10/11 (x64 or ARM64). Run via 1_Setup_Windows.bat. Safe to re-run: skips what is already installed.
# Free tools from official sources -> %LOCALAPPDATA%\CreatorKit\bin : ffmpeg/ffprobe (BtbN builds), yt-dlp, deno, uv, yutu (GitHub releases);
# Git for Windows (winget, or PortableGit from GitHub); optional: video-use (GitHub, PR #151 local Whisper).
$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Kit  = Split-Path -Parent $PSScriptRoot
$Conf = Join-Path $env:USERPROFILE '.creator-kit'
$Bin  = Join-Path $env:LOCALAPPDATA 'CreatorKit\bin'
$Tmp  = Join-Path $env:TEMP ('creatorkit_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $Conf, $Bin, $Tmp | Out-Null
$RootFile = Join-Path $Conf 'root.txt'
if (-not (Test-Path $RootFile) -or -not (Get-Content $RootFile -ErrorAction SilentlyContinue)) {
  $def = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CreatorKit'
  if ($env:KIT_ROOT) { $def = $env:KIT_ROOT }
  Set-Content -Path $RootFile -Value $def -Encoding ASCII
}
$Root = (Get-Content $RootFile | Select-Object -First 1).Trim()
New-Item -ItemType Directory -Force -Path (Join-Path $Root 'scripts') | Out-Null
Start-Transcript -Path (Join-Path $Root 'scripts\setup_log.txt') -Force | Out-Null
$Arm = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
function Step($t) { Write-Host ''; Write-Host "==== $t ====" -ForegroundColor Cyan }
function Fail($t) { Write-Host ''; Write-Host "!!!! STOPPED: $t" -ForegroundColor Red; Write-Host 'Nothing was broken. Fix the problem (or ask Claude) and run this again.'; Stop-Transcript | Out-Null; exit 1 }
function Get-File($url, $out) { for ($i = 1; $i -le 3; $i++) { try { Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $out; Unblock-File $out; return } catch { if ($i -eq 3) { throw } Start-Sleep 3 } } }
function Has($exe) { return [bool](Get-Command $exe -ErrorAction SilentlyContinue) }
# make our bin folder usable now and in future windows
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); if (-not $userPath) { $userPath = '' }
if (($userPath -split ';') -notcontains $Bin) { [Environment]::SetEnvironmentVariable('Path', ($Bin + ';' + $userPath).TrimEnd(';'), 'User') }
$env:Path = $Bin + ';' + $env:Path
Write-Host "Creator Kit setup (Windows) $(Get-Date) | $([Environment]::OSVersion.VersionString) | $env:PROCESSOR_ARCHITECTURE | folder: $Root"

Step '1/8 Git (provides Git Bash for the kit scripts)'
$GitBash = @("$env:ProgramFiles\Git\bin\bash.exe", "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe", "$env:LOCALAPPDATA\CreatorKit\PortableGit\bin\bash.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $GitBash -and (Has 'winget')) {
  winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements | Out-Host
  $GitBash = @("$env:ProgramFiles\Git\bin\bash.exe", "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $GitBash) {
  try {
    $rel = Invoke-RestMethod -UseBasicParsing 'https://api.github.com/repos/git-for-windows/git/releases/latest'
    $pat = if ($Arm) { '^PortableGit-.*-arm64\.7z\.exe$' } else { '^PortableGit-.*-64-bit\.7z\.exe$' }
    $asset = $rel.assets | Where-Object { $_.name -match $pat } | Select-Object -First 1
    $pg = Join-Path $Tmp $asset.name; Get-File $asset.browser_download_url $pg
    $dest = "$env:LOCALAPPDATA\CreatorKit\PortableGit"
    Start-Process -FilePath $pg -ArgumentList @("-o`"$dest`"", '-y') -Wait -WindowStyle Hidden
    $GitBash = "$dest\bin\bash.exe"
  } catch { Fail "Git install failed: $($_.Exception.Message)" }
}
if (-not (Test-Path $GitBash)) { Fail 'Git Bash not found after install' }
$GitExe = Join-Path (Split-Path (Split-Path $GitBash)) 'cmd\git.exe'; if (Test-Path $GitExe) { $env:Path = (Split-Path $GitExe) + ';' + $env:Path }
Write-Host "Git Bash: $GitBash"

Step '2/8 Folders + scripts'
$RootFwd = $Root -replace '\\', '/'
& $GitBash ((Join-Path $Kit 'common\create_folders.sh') -replace '\\', '/') $RootFwd | Out-Null; if ($LASTEXITCODE -ne 0) { Fail "could not create folders in $Root" }
$Dst = Join-Path $Root 'scripts'
if ((Resolve-Path $Kit).Path.TrimEnd('\') -ne (Resolve-Path $Dst).Path.TrimEnd('\')) {
  foreach ($d in 'common', 'mac', 'windows', 'templates', 'claude') { if (Test-Path (Join-Path $Kit $d)) { Copy-Item -Recurse -Force (Join-Path $Kit $d) $Dst } }
}
foreach ($t in 'research_queries.txt', 'youtube_job.json') { if (-not (Test-Path (Join-Path $Dst $t))) { Copy-Item (Join-Path $Kit "templates\$t") (Join-Path $Dst $t) } }
Get-ChildItem $Root | Select-Object -ExpandProperty Name

Step '3/8 ffmpeg + ffprobe'
if (-not (Has 'ffmpeg') -or -not (Has 'ffprobe')) {
  $n = if ($Arm) { 'ffmpeg-master-latest-winarm64-gpl' } else { 'ffmpeg-master-latest-win64-gpl' }
  try { Get-File "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/$n.zip" "$Tmp\ff.zip"; Expand-Archive -Force "$Tmp\ff.zip" "$Tmp\ff"
        Copy-Item -Force "$Tmp\ff\$n\bin\ffmpeg.exe", "$Tmp\ff\$n\bin\ffprobe.exe" $Bin } catch { Fail "ffmpeg install failed: $($_.Exception.Message)" }
}
& ffmpeg -hide_banner -version | Select-Object -First 1

Step '4/8 yt-dlp'
if (-not (Has 'yt-dlp')) { $n = if ($Arm) { 'yt-dlp_arm64.exe' } else { 'yt-dlp.exe' }
  try { Get-File "https://github.com/yt-dlp/yt-dlp/releases/latest/download/$n" "$Bin\yt-dlp.exe" } catch { Fail "yt-dlp download failed: $($_.Exception.Message)" } }
& yt-dlp --version; if ($LASTEXITCODE -ne 0) { Fail 'yt-dlp does not run' }

Step '5/8 deno (yt-dlp needs it for YouTube)'
if (-not (Has 'deno')) { $n = if ($Arm) { 'deno-aarch64-pc-windows-msvc.zip' } else { 'deno-x86_64-pc-windows-msvc.zip' }
  try { Get-File "https://github.com/denoland/deno/releases/latest/download/$n" "$Tmp\deno.zip"; Expand-Archive -Force "$Tmp\deno.zip" $Bin; Unblock-File "$Bin\deno.exe" } catch { Fail "deno install failed: $($_.Exception.Message)" } }
& deno --version | Select-Object -First 1

Step '6/8 uv (runs Python scripts, fetches Python itself)'
if (-not (Has 'uv')) { $n = if ($Arm) { 'uv-aarch64-pc-windows-msvc.zip' } else { 'uv-x86_64-pc-windows-msvc.zip' }
  try { Get-File "https://github.com/astral-sh/uv/releases/latest/download/$n" "$Tmp\uv.zip"; Expand-Archive -Force "$Tmp\uv.zip" "$Tmp\uv"
        Get-ChildItem "$Tmp\uv" -Recurse -Filter 'uv*.exe' | ForEach-Object { Copy-Item -Force $_.FullName $Bin; Unblock-File (Join-Path $Bin $_.Name) } } catch { Fail "uv install failed: $($_.Exception.Message)" } }
& uv --version; if ($LASTEXITCODE -ne 0) { Fail 'uv does not run' }

Step '7/8 yutu (YouTube sign-in)'
if (-not (Has 'yutu')) { $n = if ($Arm) { 'yutu-windows-arm64.exe' } else { 'yutu-windows-amd64.exe' }
  try { Get-File "https://github.com/eat-pray-ai/yutu/releases/latest/download/$n" "$Bin\yutu.exe" } catch { Fail "yutu download failed: $($_.Exception.Message)" } }
& yutu version; if ($LASTEXITCODE -ne 0) { Fail 'yutu does not run' }

Step '8/8 video-use (optional, for Claude Code video editing)'
$VU = Join-Path $env:USERPROFILE 'Developer\video-use'; $VUS = 'skipped'
if ($env:SKIP_VIDEO_USE -ne '1') {
  try {
    $ErrorActionPreference = 'Continue'
    New-Item -ItemType Directory -Force -Path (Split-Path $VU) | Out-Null
    if (-not (Test-Path "$VU\.git")) { & git clone -q https://github.com/browser-use/video-use $VU; if ($LASTEXITCODE) { throw 'clone failed' } }
    Push-Location $VU
    & git rev-parse --verify -q local-whisper | Out-Null; if ($LASTEXITCODE) { & git fetch -q origin pull/151/head:local-whisper; if ($LASTEXITCODE) { throw 'fetch failed' } }
    & git checkout -q local-whisper; if ($LASTEXITCODE) { throw 'checkout failed' }
    & uv sync -q --extra stt-cpu; if ($LASTEXITCODE) { throw 'uv sync failed' }
    if (-not (Select-String -Path .env -Pattern '^VIDEO_USE_TRANSCRIBER=' -Quiet -ErrorAction SilentlyContinue)) { Add-Content .env 'VIDEO_USE_TRANSCRIBER=local' }
    & uv run python helpers/timeline_view.py --help | Out-Null; if ($LASTEXITCODE) { throw 'helpers check failed' }
    $sk = Join-Path $env:USERPROFILE '.claude\skills'; New-Item -ItemType Directory -Force -Path $sk | Out-Null
    if (-not (Test-Path "$sk\video-use")) { cmd /c mklink /J "$sk\video-use" "$VU" | Out-Null }
    $VUS = 'ok ' + (& git log -1 --format=%h)
  } catch { $VUS = "FAILED ($_) - optional, everything else still works"; Write-Host "video-use: $VUS" -ForegroundColor Yellow }
  finally { Pop-Location -ErrorAction SilentlyContinue; $ErrorActionPreference = 'Stop' }
}

$status = @("date=$(Get-Date)", "os=$([Environment]::OSVersion.VersionString) $env:PROCESSOR_ARCHITECTURE", "root=$Root", "git_bash=$GitBash",
  "ffmpeg=$((& ffmpeg -hide_banner -version | Select-Object -First 1))", "yt_dlp=$(& yt-dlp --version)", "deno=$((& deno --version | Select-Object -First 1))",
  "uv=$(& uv --version)", "yutu=$((& yutu version | Select-Object -First 1))", "video_use=$VUS")
Set-Content -Path (Join-Path $Root 'scripts\setup_status.txt') -Value $status -Encoding UTF8
Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
Write-Host ''; $status | ForEach-Object { Write-Host $_ }
Write-Host ''; Write-Host "ALL DONE. Next: put your client_secret.json in $Root\.secrets\ and run 2_Connect_YouTube." -ForegroundColor Green
Stop-Transcript | Out-Null
