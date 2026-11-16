@echo off
REM Relance Ollama
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ollama-control.ps1" start
timeout /t 4 >nul
