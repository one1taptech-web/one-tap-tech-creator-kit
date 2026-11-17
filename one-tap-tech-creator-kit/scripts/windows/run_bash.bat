@echo off
rem Runs a Creator Kit bash script with Git Bash (installed by setup). Usage: run_bash.bat <script name in ..\common>
setlocal
set "GB=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GB%" set "GB=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not exist "%GB%" set "GB=%LOCALAPPDATA%\CreatorKit\PortableGit\bin\bash.exe"
if not exist "%GB%" ( echo Git Bash not found - run 1_Setup_Windows first. & pause & exit /b 1 )
for %%I in ("%~dp0..\common\%~1") do set "S=%%~fI"
set "S=%S:\=/%"
"%GB%" "%S%"
endlocal
