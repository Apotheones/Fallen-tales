@echo off
rem Shim p/ cmd.exe: o runner real e o script bash ao lado.
bash "%~dp0run_headless" %*
exit /b %errorlevel%
