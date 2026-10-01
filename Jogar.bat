@echo off
cd /d "%~dp0"
if exist "C:\Program Files\LOVE\love.exe" (
    start "" "C:\Program Files\LOVE\love.exe" "%~dp0"
) else (
    love "%~dp0"
)
