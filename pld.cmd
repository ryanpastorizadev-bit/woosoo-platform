@echo off
REM Palisade CLI shim (Windows) — delegates to pld.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pld.ps1" %*
exit /b %ERRORLEVEL%
