@echo off
REM Coupe Ollama pour liberer la carte graphique et la RAM
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ollama-control.ps1" stop
timeout /t 4 >nul
