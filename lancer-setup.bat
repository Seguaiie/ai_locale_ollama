@echo off
REM Double-clique ce fichier pour lancer le setup (contourne la politique d'execution PowerShell)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-ollama.ps1" %*
pause
